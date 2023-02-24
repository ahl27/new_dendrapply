# new_dendrapply

New dendrapply implementation.

See https://www.ahl27.com/posts/2023/02/dendrapply/ for a quick writeup, I'll improve the formatting later.

Highlights:
- Unrolled recursion, no stack issues
- 2-3x runtime speedup
- Significant memory improvement (still working on concrete benchmarks aside from `profvis`)
- Support for inorder and postorder traversal for applying functions to dendrogram
- default settings are a drop-in replacement for `stats::dendrapply`, passes all unit tests in `dendextend`
- postorder traversal ensures children of node are evaluated before node itself, allowing more possibilities
