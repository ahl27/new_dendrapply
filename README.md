# new_dendrapply

New dendrapply implementation.

See https://www.ahl27.com/posts/2023/02/dendrapply/ for the full write-up on the implementation and changes.

Highlights:
- Unrolled recursion, no stack issues
- 2-3x runtime speedup
- Significant memory improvement (observed up to 10x reduction in `profvis`, still working on concrete benchmarks aside from that)
- Support for preorder and postorder traversal for applying functions to dendrogram
- default settings are a drop-in replacement for `stats::dendrapply`, passes all unit tests in `dendextend`
- postorder traversal ensures children of node are evaluated before node itself, allowing more possibilities

Tentative Future Features:
- detection of leaves depends on the nodes having an attribute `'leaf'` that is non-null. Some type of failsafe should be added in the event a user overwrites the `leaf` attribute of a leaf node.
- inorder traversal
  - I'm not sure if this is useful, and additionally, is inorder traversal even defined for multifurcating trees?
  - Inorder traversals are defined as "visit all children except the rightmost, then root, then the final node". What would be the use case for this kind of traversal?
- breadth-first traversal
  - This could be useful, but I find the result a little counterintuitive for `dendrogram` objects. 
- something like a `flatten` argument that can report the result as a flat list/vector.
  - traversal method would be very useful here, would function like `rapply` but on internal nodes.
  - This is probably the highest priority next feature


Note that at one point I mistakenly referred to "preorder" traversal as "inorder", which was a mistake. This has been corrected everywhere it appears--the functionality is all correct, just the term was incorrect.
