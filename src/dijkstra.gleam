////
//// The key to this library is the user specified [`SuccessorsFunc`](#SuccessorsFunc) function,
//// passed as the `edges_from` parameter, with type `fn(node_id) -> Dict(node_id, Int)`.
//// 
//// To define a suitable function, first define a type for the `node_id` type variable. For many
//// graphs a simple `Int` or `String` will suffice to identify each node. But you are free to
//// include context in the type, such as direction or a counter, by specifying a tuple or record.
//// You can then use this context to determine the successor nodes.
//// 
//// `SuccessorsFunc` takes a `node_id` of the type you define, and returns a `Dict` of successor
//// nodes and their distances. In traditional graph theory, these are called *edges*. For
//// example, a simple undirected graph could be represented with a `node_id` of `Int` and a
//// return value consisting of all the adjacent nodes and their distances. But you could just
//// as well represent a game of tic-tac-toe, where each `node_id` is the current game state and
//// each successor is a possible next move.
//// 
//// If you already have a graph type, it's likely you need only map `SuccessorsFunc` to that
//// graph type's function for listing outgoing nodes. For example, if you're using the
//// [`graph`](https://hex.pm/packages/graph) package, then your `SuccessorsFunc` might look
//// like this:
//// 
//// ```gleam
//// type NodeId = Int
//// let f: SuccessorsFunc(NodeId) = fn(node: NodeId) {
////   let my_graph =
////     graph.new()
////     |> graph.insert_node(1, "one node")
////     |> graph.insert_node(2, "other node")
////     |> graph.insert_directed_edge("edge label", from: 1, to: 2)
////     |> ...
////   
////   let assert Ok(context) = graph.get_context(my_graph, node)
////   context.outgoing
////   |> dict.keys
////   |> list.map(fn(id) { #(id, 1) })
////   |> dict.from_list
//// }
//// 
//// For graphs without edge weights, it is perfectly valid to use the same distance value for
//// every successor.

//// Typically however, you don't want to create the graph inside your `SuccessorsFunc` function.
//// So note that the function can capture immutable data and just use it to determine the
//// successors. For example you could have a function that accepts a custom data store, that
//// creates your `SuccessorsFunc` function by capturing that store and querying it based on the
//// node provided. Suppose you were trying to make a certain paragraph from a list of sentence
//// fragments. You could define the node as the paragraph left to construct, capture the list
//// of sentence fragments in your `SuccessorsFunc`, and check if any of them can help complete
//// your paragraph. It might look something like this:
//// 
//// ```gleam
//// type NodeId = String
//// fn make_successor_fn(snippets: List(String)) -> SuccessorsFunc(NodeId)
//// {
////   fn(remaining_text: NodeId) -> Dict(NodeId, Int) {
////     list.filter_map(remaining_text, fn (snippet) {
////       case string.starts_with(remaining_text, snippet) {
////         False -> Error(Nil)
////         True  -> Ok(#(string.drop_start(remaining_text, string.length(snippet)), 1))
////       }
////     })
////     |> dict.from_list
////   }
//// }
//// 
//// Then you simply pass your data store to the generator to get your function:
//// 
//// ```gleam
//// let can_be_done = make_graph_fn(my_snippets)
//// |> dijkstra.dijkstra(my_paragrah)
//// |> dijkstra.has_path_to("")
//// ```
//// 
//// You can even treat your `node_id` as a position with some state. So for example if you had
//// a maze represented as a matrix of integer coordinates, but you want the ability to walk
//// through walls once on your way to the exit, you could define your `node_id` as
//// `#(#(Int, Int), Int)`. The inner pair is the current coordinates, and the last `Int`
//// is `1` if you have a wall-walk left or `0` if you've used it up. Your `SuccessorsFunc`
//// generator might then look something like this:
//// 
//// ```gleam
//// type Coord = #(Int, Int)
//// type NodeId = #(Coord, Int)
//// fn make_successor_fn(m: Matrix) -> SuccessorsFunc(NodeId)
//// {
////   fn(n: NodeId) -> Dict(NodeId, Int) {
////     let #(coord, cheats_left) = n
////     list.filter_map(get_neighbours(m, coord), fn(neighbour) {
////       case is_wall(m, neighbour), cheats_left > 0 {
////         True,  False -> Error(Nil)                         //Wall and no cheats left
////         True,  True  -> Ok(#(neighbour, cheats_left - 1))  //Wall and can use a cheat
////         False, _     -> Ok(#(neighbour, cheats_left))      //No wall, free to proceed
////           }
////       }
////     })
////     |> list.map(fn(coord_cheats_left) {
////       #(coord_cheats_left, 1) //all moves cost the same
////     })
////     |> dict.from_list
////   }
//// }
////
//// Finally, instead of deciding next moves based on the current state, your `SuccessorsFunc`
//// could determine a distance based on the current state. Say for example you're modelling
//// a powerboat that is fastest in a straight line. Your `node_id` could include the direction
//// from which the current node was reached. Then your `SuccessorsFunc` could use that to
//// prevent turning around on the spot, and to set the edge distance based on whether the
//// direction is changing or not. Something like this:
//// 
//// type NodeId = #(Coord, Direction)
//// fn make_successor_fn(m: Matrix) -> SuccessorsFunc(NodeId)
//// {
////   fn(n: NodeId) -> Dict(NodeId, Int) {
////     let #(coord, old_dir) = n
////     [N, E, S, W]
////     |> list.filter(fn(new_dir) { new_dir != opposite(old_dir) }) //can't go backwards
////     |> list.map(fn(new_dir) { #(get_neighbours(m, coord), new_dir) })
////     |> list.map(fn(coord_dir) {
////       #(coord_dir, case coord_dir.1 == old_dir { True -> 1  False -> 10 })
////     })
////     |> dict.from_list
////   }
//// }
//// 
//// So you can see that decoupling this library from a particular graph implementation makes
//// it applicable to a wide variety of problems. By designing a suitable `SuccessorsFunc`
//// function, and taking advantage of function captures and the variable `node_id` type, you
//// can apply Dijkstra's algorithm to scenarios that would otherwise be difficult to model as
//// a graph. In my experience, the most difficult part of applying Dijkstra from a library is
//// often working out how to transform your problem domain to the graph representation expected
//// of the library. Eliminating that dependency might mean more time exploring the problem
//// domain and less time learning a new graph abstraction.

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
