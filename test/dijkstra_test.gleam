import gleeunit
import gleeunit/should

import gleam/list
import gleam/dict.{type Dict}

import dijkstra


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
