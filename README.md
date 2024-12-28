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
  let f = fn(node_id: Int) -> Dict(Int, Int) {
    case node_id {
      0 -> dict.from_list([#(1,4), #(7,8)])
      1 -> dict.from_list([#(0,4), #(7,11), #(2,8)])
      7 -> dict.from_list([#(0,8), #(1,11), #(8,8),  #(6,1)])
      2 -> dict.from_list([#(1,8), #(8,2),  #(3,7),  #(5,4)])
      8 -> dict.from_list([#(7,7), #(2,2),  #(6,6)])
      6 -> dict.from_list([#(7,1), #(8,6),  #(5,2)])
      3 -> dict.from_list([#(2,7), #(5,14), #(4,9)])
      5 -> dict.from_list([#(6,2), #(2,4),  #(3,14), #(4,10)])
      4 -> dict.from_list([#(3,9), #(5,10)])
      _ -> panic as "bug"
    }
  }
  
  let shortest_paths = dijkstra.dijkstra(f, 0)
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
