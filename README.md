# new_dendrapply

New dendrapply implementation. Bug reports and suggestions for improvement are welcome.

**NOTE**: I am not keeping this code updated. The only file that I am committing to keeping up to date is the `new_dendrapply.patch`, which should work to patch R when building from source. If you're interested in using this implementation, please use the patch file. If you're just interested in seeing how it's implemented, the code available should be close enough.

See https://www.ahl27.com/posts/2023/02/dendrapply/ for the full write-up on the implementation and changes.

## Highlights:
- Unrolled recursion, no stack issues
- ~5x runtime speedup
- Significant memory improvement 
  - Observed up to 10x reduction in `profvis`, still working on concrete benchmarks aside from that
  - Difficult to measure difference since `stats` allocates in R and new implementation allocates in C
- Support for preorder and postorder traversal for applying functions to dendrogram
- Default settings are a drop-in replacement for `stats::dendrapply`, passes all unit tests in `dendextend`
- Postorder traversal ensures children of node are evaluated before node itself, allowing more possibilities for functions to be applied

Note that leaf nodes are identified as elements with an attribute `'leaf'` that is set to `TRUE`, and internal nodes are identified as either elements with no attribute `'leaf'` or an attribute `'leaf'` that is set to `FALSE`. This conforms with how `dendrogram` objects are structured, but users may experience unexpected behavior if they decide to fiddle with `leaf` attributes. This is recognized as a problem in the same way that users being able to arbitrarily change S3 classes of an object is a problem; normal users should never experience issues from this, and ones that use malformed `dendrogram`s are proceeding at their own risk.

## Tentative Future Features:
- Inorder traversal
  - I'm not sure if this is useful, especially for multifurcating trees.
  - Inorder traversals are defined as "visit all children except the rightmost, then root, then the final node". What would be the use case for this kind of traversal?
- Breadth-first traversal
  - This could be useful, but I find the result a little counterintuitive for `dendrogram` objects. 
  - Not critical for release, maybe something to visit in the distant future. Implementation slightly harder than I expected.
- Something like a `flatten` argument that can report the result as a flat list/vector.
  - traversal method would be very useful here, would function like `rapply` but on internal nodes.
  - This is probably the highest priority next feature.
  - This would probably require a bit of a code refactor, there's a lot of special cases that make it difficult with the current approach.

Note that at one point I mistakenly referred to "preorder" traversal as "inorder", which was a mistake. This has been corrected everywhere it appears--the functionality is all correct, just the nomeclature was wrong.

## Benchmarking:

Runtime benchmarks were performed using `microbenchmark::microbenchmark` with 100 replications on random fully balanced trees with the following function:

```{r}
f <- \(x){ x }
```
This function is the fastest possible function we can run in `dendrapply`, and was chosen to ensure the measured time only compares execution speed of the apply statements themselves, not of the called function's execution time. Longer running functions dominate execution time and would bias the results. Speedup for small trees (under 11 leaves) is highly variable; this is likely due to lower accuracy measurements from `microbenchmark` at very fast speeds. Trees with greater than 30,000 leaves are difficult to create due to vector memory limits in R. 

This represents the worst-case runtime, since `stats::dendrapply` has the lowest overhead running on balanced trees. On deeper nested trees, more recursion is necessary, and thus the runtime speedup of the new version should only improve.


|   nleaves |        Old (ns) |       New (ns) |   speedup |
| ----: | ----: | ----: | :----: | 
|       5 |     54030.21 |    62688.59 | 0.8618827 |
|      10 |    114704.47 |    24695.12 | 4.6448233 |
|      25 |    278841.00 |    52103.21 | 5.3517048 |
|      50 |    582525.13 |   105611.90 | 5.5157149 |
|     100 |   1168812.01 |   202253.41 | 5.7789483 |
|     500 |   6923588.00 |  1493233.53 | 4.6366411 |
|    1000 |  15031297.41 |  2662651.11 | 5.6452373 |
|    2500 |  41285587.96 |  8304542.62 | 4.9714463 |
|    5000 |  90713364.28 | 19828996.05 | 4.5747835 |
|    7500 | 114983915.75 | 34886414.15 | 3.2959511 |
|   10000 | 167687000.44 | 49033674.48 | 3.4198335 |
