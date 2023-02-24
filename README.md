# new_dendrapply

New dendrapply implementation.

See https://www.ahl27.com/posts/2023/02/dendrapply/ for a quick writeup, I'll improve the formatting later.

Highlights:
- Unrolled recursion, no stack issues
- 2-3x runtime speedup
- Significant memory improvement (observed up to 10x reduction in `profvis`, still working on concrete benchmarks aside from that)
- Support for preorder and postorder traversal for applying functions to dendrogram
- default settings are a drop-in replacement for `stats::dendrapply`, passes all unit tests in `dendextend`
- postorder traversal ensures children of node are evaluated before node itself, allowing more possibilities

Tentative Future Features:
- inorder traversal
  - I'm not sure if this is useful, and additionally, is inorder traversal even defined for multifurcating trees?
- something like a `flatten` argument that can report the result as a flat list/vector.
  - traversal method would be very useful here, would function like `rapply` but on internal nodes.


Note that at one point I mistakenly referred to "preorder" traversal as "inorder", which was a mistake. This has been corrected everywhere it appears--the functionality is all correct, just the term was incorrect.
