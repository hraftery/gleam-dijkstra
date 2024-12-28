import gleeunit
import gleeunit/should

import gleam/list
import gleam/dict.{type Dict}

import dijkstra.{type SuccessorsFunc}


pub fn main() {
  gleeunit.main()
}

type NodeId = Int
pub fn dijkstra_test()
{
  //use example from https://www.geeksforgeeks.org/dijkstras-shortest-path-algorithm-greedy-algo-7/
  let f = fn(node_id: NodeId) -> Dict(NodeId, Int) {
    case node_id {
      0 -> dict.from_list([#(1,4),#(7,8)])
      1 -> dict.from_list([#(0,4),#(7,11),#(2,8)])
      7 -> dict.from_list([#(0,8),#(1,11),#(8,8),#(6,1)])
      2 -> dict.from_list([#(1,8),#(8,2),#(3,7),#(5,4)])
      8 -> dict.from_list([#(7,7),#(2,2),#(6,6)])
      6 -> dict.from_list([#(7,1),#(8,6),#(5,2)])
      3 -> dict.from_list([#(2,7),#(5,14),#(4,9)])
      5 -> dict.from_list([#(6,2),#(2,4),#(3,14),#(4,10)])
      4 -> dict.from_list([#(3,9),#(5,10)])
      _ -> panic as "bug"
    }
  }

  let paths = dijkstra.dijkstra(f, 0)
  paths.distances
  |> should.equal(dict.from_list([
    #(0, 0),
    #(1, 4),
    #(2, 12),
    #(3, 19),
    #(4, 21),
    #(5, 11),
    #(6, 9),
    #(7, 8),
    #(8, 14)]))
}

pub fn dijkstra_all_test()
{
  let f = fn(node_id: NodeId) -> Dict(NodeId, Int) {
    case node_id {
      0 -> dict.from_list([#(1,4),#(7,8)])
      1 -> dict.from_list([#(0,4),#(7,11),#(2,8)])
      //7 -> dict.from_list([#(0,8),#(1,11),#(#(8,8),#(#(6,1)])
      2 -> dict.from_list([#(1,8),#(8,2),#(3,7),#(5,4)])
      8 -> dict.from_list([#(7,7),#(2,2),#(6,6)])
      6 -> dict.from_list([#(7,1),#(8,6),#(5,2)])
      3 -> dict.from_list([#(2,7),#(5,14),#(4,9)])
      //5 -> dict.from_list([#(6,2),#(2,4),#(#(3,14),#(#(4,10)])
      4 -> dict.from_list([#(3,9),#(5,10)])

      //Add alternate route 7-9-5, with same distance as 7-6-5
      7 -> dict.from_list([#(0,8),#(1,11),#(8,8),#(6,1),#(9,2)])
      9 -> dict.from_list([#(7,2),#(5,1)])
      5 -> dict.from_list([#(6,2),#(2,4),#(3,14),#(4,10),#(9,1)])

      _ -> panic as "bug"
    }
  }

  let paths = dijkstra.dijkstra(f, 0)
  let sp = dijkstra.shortest_path(paths, 4)
  let all_paths = dijkstra.dijkstra_all(f, 0)
  let sps = dijkstra.shortest_paths(all_paths, 4)

  should.equal(sp.1, sp.1)                    //Shortest path length is the same.
  should.be_true(list.contains(sps.0, sp.0))  //One of shortest_paths is shortest_path.
  should.equal(list.length(sps.0), 2)         //There are two shortest_paths.
}


pub fn dijkstra_simple_test()
{
  let f = fn(node_id: NodeId) -> Dict(NodeId, Int) {
    case node_id {
      0 -> dict.from_list([#(1,4), #(2,3)])
      1 -> dict.from_list([#(3,5)])
      2 -> dict.from_list([#(3,5)])
      3 -> dict.from_list([])
      _ -> panic as "bug"
    }
  }

  should.equal(dijkstra.dijkstra(f, 0),
    dijkstra.ShortestPaths(
      distances: dict.from_list([
        #(0, 0),
        #(1, 4),
        #(2, 3),
        #(3, 8)]),
      predecessors: dict.from_list([
        #(1, 0),
        #(2, 0),
        #(3, 2)])))
}


pub fn doc1_test()
{
  let successor_func = fn(node_id: NodeId) -> Dict(NodeId, Int) {
    case node_id {
      0 -> dict.from_list([#(1,4), #(2,3)])
      1 -> dict.from_list([#(3,5)])
      2 -> dict.from_list([#(3,5)])
      3 -> dict.from_list([])
      _ -> panic as "unreachable"
    }
  }
  
  let shortest_paths = dijkstra.dijkstra(successor_func, 0)
  let shortest_path_to_3 = dijkstra.shortest_path(shortest_paths, 3)
  should.equal(shortest_path_to_3.1, 8)
  should.equal(shortest_path_to_3.0, [0, 2, 3])
}

import graph.{Node}

pub fn doc2_test()
{
  let f: SuccessorsFunc(NodeId) = fn(node: NodeId) {
    let my_graph =
      graph.new()
      |> graph.insert_node(Node(1, "one node"))
      |> graph.insert_node(Node(2, "other node"))
      |> graph.insert_directed_edge("edge label", from: 1, to: 2)
  
    let assert Ok(context) = graph.get_context(my_graph, node)
    context.outgoing
    |> dict.keys
    |> list.map(fn(id) { #(id, 1) }) //give all edges a distance of 1
    |> dict.from_list
  }

  let shortest_paths = dijkstra.dijkstra(f, 1)
  let shortest_path_to_2 = dijkstra.shortest_path(shortest_paths, 2)
  should.equal(shortest_path_to_2.1, 1)
  should.equal(shortest_path_to_2.0, [1, 2])
}


import gleam/string
type NodeId3 = String
fn doc3_make_successor_fn(snippets: List(String)) -> SuccessorsFunc(NodeId3)
{
  fn(remaining_text: NodeId3) -> Dict(NodeId3, Int) {
    list.filter_map(snippets, fn (snippet) {
      case string.starts_with(remaining_text, snippet) {
        False -> Error(Nil)
        True  -> Ok(#(string.drop_start(remaining_text, string.length(snippet)), 1))
      }
    })
    |> dict.from_list
  }
}

pub fn doc3_test()
{
  let my_snippets = ["abc de", "abc", "def ", "f ghi", "ghi"]
  let can_be_done1 = doc3_make_successor_fn(my_snippets)
  |> dijkstra.dijkstra("abc def ghi")
  |> dijkstra.has_path_to("")

  should.be_true(can_be_done1)

  let can_be_done2 = doc3_make_successor_fn(my_snippets)
  |> dijkstra.dijkstra("abc def ghi j")
  |> dijkstra.has_path_to("")

  should.be_false(can_be_done2)
}

type Matrix = Dict(Coord, String)
fn get_neighbours(_m: Matrix, coord: Coord)
{
  case coord {
    c if c == #(0,0) -> [#(1,0), #(1,1)]
    c if c == #(1,1) -> [#(2,0)]
    c if c == #(1,0) -> [#(2,0)]
    _ -> []
  }
}
fn is_wall(_m: Matrix, coord: Coord)
{
  coord == #(1,1)
}
type Coord = #(Int, Int)
type NodeId4 = #(Coord, Int)
fn doc4_make_successor_fn(m: Matrix) -> SuccessorsFunc(NodeId4)
{
  fn(n: NodeId4) -> Dict(NodeId4, Int) {
    let #(coord, cheats_left) = n
    list.filter_map(get_neighbours(m, coord), fn(neighbour) {
      case is_wall(m, neighbour), cheats_left > 0 {
        True,  False -> Error(Nil)                         //Wall and no cheats left
        True,  True  -> Ok(#(neighbour, cheats_left - 1))  //Wall and can use a cheat
        False, _     -> Ok(#(neighbour, cheats_left))      //No wall, free to proceed
      }
    })
    |> list.map(fn(coord_cheats_left) {
      #(coord_cheats_left, 1) //all moves cost the same
    })
    |> dict.from_list
  }
}

pub fn doc4_test()
{
  let can_be_done1 = doc4_make_successor_fn(dict.new())
  |> dijkstra.dijkstra(#(#(0,0), 1))
  |> dijkstra.has_path_to(#(#(2,0), 0))

  should.be_true(can_be_done1)

  let can_be_done2 = doc4_make_successor_fn(dict.new())
  |> dijkstra.dijkstra(#(#(0,0), 1))
  |> dijkstra.has_path_to(#(#(2,0), 1))

  should.be_true(can_be_done2)
}

fn opposite(d) { d }
fn get_neighbour(_m, _c, _d) { #(0,0) }
type Direction { N E S W }
type NodeId5 = #(Coord, Direction)
fn doc5_make_successor_fn(m: Matrix) -> SuccessorsFunc(NodeId5)
{
  fn(n: NodeId5) -> Dict(NodeId5, Int) {
    let #(coord, old_dir) = n
    [N, E, S, W]
    |> list.filter(fn(new_dir) { new_dir != opposite(old_dir) }) //can't go backwards
    |> list.map(fn(new_dir) { #(get_neighbour(m, coord, new_dir), new_dir) })
    |> list.map(fn(coord_dir) {
      #(coord_dir, case coord_dir.1 == old_dir { True -> 1  False -> 10 })
    })
    |> dict.from_list
  }
}

pub fn doc5_test()
{
  let can_be_done1 = doc5_make_successor_fn(dict.new())
  |> dijkstra.dijkstra(#(#(0,0), N))
  |> dijkstra.has_path_to(#(#(1,0), E))

  should.be_false(can_be_done1)
}
