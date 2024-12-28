# dijkstra

[![Package Version](https://img.shields.io/hexpm/v/dijkstra)](https://hex.pm/packages/dijkstra)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/dijkstra/)

A versatile implementation of Dijkstra's shortest path algorithm.

Key features:

- No reliance on any particular graph representation.
- Requires only a function that returns a node's successors.
- Supports lazy graph descriptions, since nodes are only explored as required.
- Only a single dependency: `gleamy_structures` for its fine priority queue implementation.


## Installation

```sh
gleam add dijkstra
```


## Short Example

```gleam
import dijkstra

pub fn main() {
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
  io.print("Shortest path to node 3 has length: ")
  io.debug(shortest_path_to_3.1)
  io.println(".")
  io.print("That path is: ")
  io.debug(shortest_path_to_3.0)
  io.println(".")
}
```


## Development

```sh
gleam test  # Run the tests
```

## Usage

The key to this library is the user specified [`SuccessorsFunc`](#SuccessorsFunc) function
with type `fn(node_id) -> Dict(node_id, Int)`, passed as the `edges_from` parameter to the
`dijkstra` function. Instead of relying on a graph data structure, this function provides
node neighbours on demand.

To define a suitable function, first define a type for the `node_id` type variable. For many
graphs a simple `Int` or `String` will suffice to identify each node. But you are free to
include context in the type, such as direction or a counter, by specifying a tuple or record.
You can then use this context to determine the successor nodes.

`SuccessorsFunc` takes a `node_id` of the type you define, and returns a `Dict` of successor
nodes and their distances. In traditional graph theory, these are called *edges*. For
example, a simple undirected graph could be represented with a `node_id` of `Int` and a
return value consisting of all the adjacent nodes and their distances. But you could just
as well represent a game of tic-tac-toe, where each `node_id` is the current game state and
each successor is a possible next move.

If you already have a graph type, it's likely you need only map `SuccessorsFunc` to that
graph type's function for listing outgoing nodes. For example, if you're using the
[`graph`](https://hex.pm/packages/graph) package, then your `SuccessorsFunc` might look
like this:

```gleam
type NodeId = Int
let f: SuccessorsFunc(NodeId) = fn(node: NodeId) {
  let my_graph =
    graph.new()
    |> graph.insert_node(1, "one node")
    |> graph.insert_node(2, "other node")
    |> graph.insert_directed_edge("edge label", from: 1, to: 2)
    |> ...
  
  let assert Ok(context) = graph.get_context(my_graph, node)
  context.outgoing
  |> dict.keys
  |> list.map(fn(id) { #(id, 1) }) //give all edges a distance of 1
  |> dict.from_list
}
```

For graphs without edge weights, it is perfectly valid to use the same distance value for
every successor.

Typically however, you don't want to create the graph inside your `SuccessorsFunc` function.
So note that the function can capture immutable data and just use it to determine the
successors. For example you could have another function that accepts a custom data store,
that creates your `SuccessorsFunc` function by capturing that store and querying it based on
the node provided. Suppose you were trying to make a certain paragraph from a list of sentence
fragments. You could define the node as the paragraph left to construct, capture the list
of sentence fragments in your `SuccessorsFunc`, and check if any of them can help complete
your paragraph. It might look something like this:

```gleam
type NodeId = String
fn make_successor_fn(snippets: List(String)) -> SuccessorsFunc(NodeId)
{
  fn(remaining_text: NodeId) -> Dict(NodeId, Int) {
    list.filter_map(remaining_text, fn (snippet) {
      case string.starts_with(remaining_text, snippet) {
        False -> Error(Nil)
        True  -> Ok(#(string.drop_start(remaining_text, string.length(snippet)), 1))
      }
    })
    |> dict.from_list
  }
}
```

Then you simply pass your data store to the generator to get your function:

```gleam
let can_be_done = make_graph_fn(my_snippets)
|> dijkstra.dijkstra(my_paragrah)
|> dijkstra.has_path_to("")
```

You can even treat your `node_id` as a position with some state. So for example if you had
a maze represented as a matrix of integer coordinates, but you want the ability to walk
through walls once on your way to the exit, you could define your `node_id` as
`#(#(Int, Int), Int)`. The inner pair is the current coordinates, and the last `Int`
is `1` if you have a wall-walk left or `0` if you've used it up. Your `SuccessorsFunc`
generator might then look something like this:

```gleam
type Coord = #(Int, Int)
type NodeId = #(Coord, Int)
fn make_successor_fn(m: Matrix) -> SuccessorsFunc(NodeId)
{
  fn(n: NodeId) -> Dict(NodeId, Int) {
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
```

Finally, instead of deciding next moves based on the current state, your `SuccessorsFunc`
could determine a distance based on the current state. Say for example you're modelling
a powerboat that is fastest in a straight line. Your `node_id` could include the direction
from which the current node was reached. Then your `SuccessorsFunc` could use that to
prevent turning around on the spot, and to set the edge distance based on whether the
direction is changing or not. Something like this:

```gleam
type NodeId = #(Coord, Direction)
fn make_successor_fn(m: Matrix) -> SuccessorsFunc(NodeId)
{
  fn(n: NodeId) -> Dict(NodeId, Int) {
    let #(coord, old_dir) = n
    [N, E, S, W]
    |> list.filter(fn(new_dir) { new_dir != opposite(old_dir) }) //can't go backwards
    |> list.map(fn(new_dir) { #(get_neighbours(m, coord), new_dir) })
    |> list.map(fn(coord_dir) {
      #(coord_dir, case coord_dir.1 == old_dir { True -> 1  False -> 10 })
    })
    |> dict.from_list
  }
}
```

So you can see that decoupling this library from a particular graph implementation makes
it applicable to a wide variety of problems. By designing a suitable `SuccessorsFunc`
function, and taking advantage of function captures and the variable `node_id` type, you
can apply Dijkstra's algorithm to scenarios that would otherwise be difficult to model as
a graph. In my experience, the most difficult part of applying Dijkstra from a library is
often working out how to transform your problem domain to the graph representation expected
of the library. Eliminating that dependency might mean more time exploring the problem
domain and less time learning a new graph abstraction.


## Acknowledgements

This implementation was inspired by [https://ummels.de/2014/06/08/dijkstra-in-clojure/](https://ummels.de/2014/06/08/dijkstra-in-clojure/)
