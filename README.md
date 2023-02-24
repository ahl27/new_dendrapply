# new_dendrapply

New dendrapply implementation.

See https://www.ahl27.com/posts/2023/02/dendrapply/ for a quick writeup, I'll improve the formatting later.

Highlights:
- Unrolled recursion, no stack issues
- 2-3x runtime speedup
- Significant memory improvement (observed up to 10x reduction in `profvis`, still working on concrete benchmarks aside from that)
- Support for ~~inorder~~ preorder and postorder traversal for applying functions to dendrogram
  - I just realized I got this wrong, documentation and files will be changed to correct for this
- default settings are a drop-in replacement for `stats::dendrapply`, passes all unit tests in `dendextend`
- postorder traversal ensures children of node are evaluated before node itself, allowing more possibilities

Tentative Future Features:
- inorder traversal
- something like a `flatten` argument that can report the result as a flat list/vector.
  - traversal method would be very useful here, would function like `rapply` but on internal nodes.
