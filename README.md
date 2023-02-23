# new_dendrapply

New dendrapply implementation.

See https://www.ahl27.com/posts/2023/02/dendrapply/ for a quick writeup, I'll improve the formatting later.

Highlights:
- Unrolled recursion, no stack issues
- 2x runtime speedup
- Significant memory improvement (still working on concrete benchmarks aside from `profvis`)
- Support for inorder and postorder traversal for applying functions to dendrogram
- inorder traversal exactly replicates `stats::dendrapply`, passes all unit tests in `dendextend`
