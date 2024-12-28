import gleam/int
import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{Some}
import gleamy/priority_queue.{type Queue} as pq


/// A function that given a node, returns successor nodes and their distances.
///
pub type SuccessorsFunc(node_id) = fn(node_id) -> Dict(node_id, Int)

/// The return type of [`dijkstra`](#dijkstra). Consists of two dictionaries that contain,
/// for every visited node, the shortest distance to that node and the node's immediate
/// predecssor on that shortest path.
///
pub type ShortestPaths(node_id) {
  ShortestPaths(distances: Dict(node_id, Int),
                predecessors: Dict(node_id, node_id))
}

/// Same as [`ShortestPaths`](#ShortestPaths), except for [`dijkstra_all`](#dijkstra_all).
/// The `distances` field is the same as `ShortestPaths` since there is only one shortest
/// distance. But the `predecessors` field has a list of predecessors for each node instead
/// of a single predecessor, to represent the possibility of there being multiple paths
/// that result in the same shortest distance.
///
pub type AllShortestPaths(node_id) {
  AllShortestPaths(distances: Dict(node_id, Int),
                   predecessors: Dict(node_id, List(node_id)))
}

//Descriptive shorthand for the fields of `ShortestPaths` and `AllShortestPaths`, but which
//needn't complicate the public interface.
type Distances(node_id) = Dict(node_id, Int)
type Predecessors(node_id) = Dict(node_id, node_id)
type AllPredecessors(node_id) = Dict(node_id, List(node_id))


/// Run Dijkstra's algorithm to determine the shortest path to every node reachable from
/// `start`, according to `edges_from`.
///
/// ## Examples
///
/// ```gleam
/// let f = fn(node_id: NodeId) -> Dict(NodeId, Int) {
///   case node_id {
///     0 -> dict.from_list([#(1,4), #(2,3)])
///     1 -> dict.from_list([#(3,5)])
///     2 -> dict.from_list([#(3,5)])
///     3 -> dict.from_list([])
///     _ -> panic as "unreachable"
///   }
/// }
///
/// dijkstra.dijkstra(f, 0)
/// // -> ShortestPaths(dict.from_list([#(0, 0), #(1, 4), #(2, 3), #(3, 8)]), dict.from_list([#(1, 0), #(2, 0), #(3, 2)]))
/// ```
///
pub fn dijkstra(edges_from: SuccessorsFunc(node_id),
                start: node_id) -> ShortestPaths(node_id)
{
  let dist = dict.from_list([#(start, 0)])
  let q = pq.from_list([#(start, 0)], fn(a, b) { int.compare(a.1, b.1) })

  do_dijkstra(edges_from, dist, dict.new(), q)
}

fn do_dijkstra(edges_from: SuccessorsFunc(node_id),
               dist: Distances(node_id), pred: Predecessors(node_id),
               q: Queue(#(node_id, Int))) -> ShortestPaths(node_id)
{
  case pq.is_empty(q) {
    True  -> ShortestPaths(dist, pred)
    False -> {
      let assert Ok(#(#(u, _), q)) = pq.pop(q)
      let #(dist, pred, q) = dict.fold(edges_from(u), #(dist, pred, q), fn(acc, v, uv_dist) {
        let #(dist, pred, q) = acc
        let assert Ok(u_dist) = dict.get(dist, u)
        let alt = u_dist + uv_dist
        case dict.get(dist, v) {
          Ok(v_dist) if alt >= v_dist -> acc //If already have a shorter route, then no changes.
          _ -> #(dict.insert(dist, v, alt),  //Otherwise update dist,
                 dict.insert(pred, v, u),    //pred,
                 pq.push(q, #(v, alt)))      //and q.
        }
      })
      do_dijkstra(edges_from, dist, pred, q)
    }
  }
}

/// Return true if Dijkstra's algorithm found a path to the `dest` node.
/// 
/// Recall that in order to determine the shortest path, Dijkstra's algorithm visits all
/// nodes reachable from the given start node. Thus we can exploit that to determine whether
/// any particular node is reachable, without looking at the graph again.
///
pub fn has_path_to(paths: ShortestPaths(node_id), dest: node_id)
{
  dict.has_key(paths.distances, dest)
}

/// When applied to the result of [`dijkstra`](#dijkstra), returns the shortest path to the
/// `dest` node as a list of successive nodes, and the total length of that path.
///
pub fn shortest_path(paths: ShortestPaths(node_id), dest: node_id) -> #(List(node_id), Int)
{
  let path = do_shortest_path(paths.predecessors, dest)
  let assert Ok(dist) = dict.get(paths.distances, dest)
  #(list.reverse(path), dist)
}

fn do_shortest_path(predecessors, curr) -> List(node_id)
{
  case dict.get(predecessors, curr) {
    Error(_) -> [curr]
    Ok(pred) -> [curr, ..do_shortest_path(predecessors, pred)]
  }
}


/// Same as [`dijkstra`](#dijkstra), except each node predecessor is a `list` instead of a
/// single node. If there are multiple shortest paths, junction nodes will have more than one
/// predecessor.
/// 
pub fn dijkstra_all(edges_from: SuccessorsFunc(node_id),
                    start: node_id) -> AllShortestPaths(node_id)
{
  let dist = dict.from_list([#(start, 0)])
  let q = pq.from_list([#(start, 0)], fn(a, b) { int.compare(a.1, b.1) })

  do_dijkstra_all(edges_from, dist, dict.new(), q)
}

fn do_dijkstra_all(edges_from: SuccessorsFunc(node_id),
                   dist: Distances(node_id), pred: AllPredecessors(node_id),
                   q: Queue(#(node_id, Int))) -> AllShortestPaths(node_id)
{
  case pq.is_empty(q) {
    True  -> AllShortestPaths(dist, pred)
    False -> {
      let assert Ok(#(#(u, _), q)) = pq.pop(q)
      let #(dist, pred, q) = dict.fold(edges_from(u), #(dist, pred, q), fn(acc, v, uv_dist) {
        let #(dist, pred, q) = acc
        let assert Ok(u_dist) = dict.get(dist, u)
        let alt = u_dist + uv_dist
        case dict.get(dist, v) {
          Ok(v_dist) if alt >  v_dist -> acc  //If already have a shorter route, then no changes.
          Ok(v_dist) if alt == v_dist -> {    //If already have a same dist route, then
            #(dist,                           //  leave dist alone,
              dict.upsert(pred, v, fn(x) {    
                case x { Some(i) -> [u, ..i]  //  prepend to pred,
                         _ -> panic as "BUG" }}),
              q)}                             //  and leave q alone.
          _ -> #(dict.insert(dist, v, alt),   //Otherwise this is the shortest route, so update dist,
                 dict.insert(pred, v, [u]),   //  pred,
                 pq.push(q, #(v, alt)))       //  and q.
        }
      })
      do_dijkstra_all(edges_from, dist, pred, q)
    }
  }
}

/// Same as [`shortest_path`](#shortest_path), except for [`dijkstra_all`](#dijkstra_all).
/// 
pub fn shortest_paths(all_paths: AllShortestPaths(node_id), dest: node_id) -> #(List(List(node_id)), Int)
{
  let paths = do_shortest_paths(all_paths.predecessors, [], dest)
  let assert Ok(dist) = dict.get(all_paths.distances, dest)
  #(paths, dist)
}

fn do_shortest_paths(predecessors: AllPredecessors(node_id), path: List(node_id),
                     curr: node_id) -> List(List(node_id))
{
  let new_path = [curr, ..path]
  case dict.get(predecessors, curr) {
    Error(_)  -> [new_path]
    Ok(preds) -> list.flat_map(preds, do_shortest_paths(predecessors, new_path, _))
  }
}
