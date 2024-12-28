# dijkstra

[![Package Version](https://img.shields.io/hexpm/v/dijkstra)](https://hex.pm/packages/dijkstra)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/dijkstra/)

A versatile implementation of Dijkstra's shortest path algorithm.

Key features:

- No reliance on any particular graph representation.
- Requires only a function that returns a node's successors.
- Supports lazy graph descriptions, since nodes are only explored as required.
- Only a single dependency: `gleamy_structures` for its fine priority queue implementation.


Further documentation can be found at <https://hexdocs.pm/dijkstra>.


## Installation

```sh
gleam add dijkstra
```


## Example Usage

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


## Implementation Notes

Inspired by https://ummels.de/2014/06/08/dijkstra-in-clojure/

Instead of relying on a graph data structure, node neighbours are provided by a function. Not only does this provide easy integration with any graph representation, it also works without a graph. Nodes can be generated on demand.

This is similar in concept to laziness, where elements are only generated as they're required. Not only does this open the door to use with huge graphs without having to pre-calculate unreachable regions, it also permits dynamically generated graphs.
