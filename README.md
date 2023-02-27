# new_dendrapply

New dendrapply implementation. Bug reports and suggestions for improvement are welcome.

See https://www.ahl27.com/posts/2023/02/dendrapply/ for the full write-up on the implementation and changes.

## Highlights:
- Unrolled recursion, no stack issues
- 2-3x runtime speedup
- Significant memory improvement 
  - Observed up to 10x reduction in `profvis`, still working on concrete benchmarks aside from that
  - Difficult to measure difference since `stats` uses R for memory and new implementation allocates in C
- Support for preorder and postorder traversal for applying functions to dendrogram
- Default settings are a drop-in replacement for `stats::dendrapply`, passes all unit tests in `dendextend`
- Postorder traversal ensures children of node are evaluated before node itself, allowing more possibilities for functions to be applied

Note that leaf nodes are identified as elements with an attribute `'leaf'` that is set to `TRUE`, and internal nodes are identified as either elements with no attribute `'leaf'` or an attribute `'leaf'` that is set to `FALSE`. This conforms with how `dendrogram` objects are structured, but users may experience unexpected behavior if they decide to fiddle with the `leaf` attributes. This is recognized as a problem in the same way that users being able to arbitrarily change S3 classes of an object is a problem; normal users should never experience issues from this, and ones that use malformed `dendrogram`s are proceeding at their own risk.

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

Runtime benchmarks were performed using `microbenchmark::microbenchmark` with 100 replications on random balanced trees with the following function:

```{r}
f <- \(x){ x }
```
This function is the fastest possible function we can run in `dendrapply`, and was chosen to ensure the measured time only compares execution speed of the apply statements themselves, not of the called function's execution time. Longer running functions dominate execution time and would bias the results. Speedup for small trees (under 11 leaves) is highly variable; this is likely due to lower accuracy measurements from `microbenchmark` at very fast speeds. Trees with greater than 30,000 leaves are difficult to create due to vector memory limits in R.

 | num_leaves | Old (ms) | New (ms) | speedup | 
 | ----: | ----: | ----: | :----: | 
 | 5 | 0.044 | 0.036 | 1.238x | 
 | 10 | 0.097 | 0.057 | 1.700x | 
 | 25 | 0.270 | 0.131 | 2.056x | 
 | 50 | 0.593 | 0.245 | 2.424x | 
 | 100 | 1.110 | 0.457 | 2.429x | 
 | 500 | 5.865 | 2.306 | 2.544x | 
 | 1000 | 11.896 | 4.716 | 2.523x | 
 | 2500 | 31.095 | 13.305 | 2.337x | 
 | 5000 | 101.890 | 31.200 | 3.266x | 
 | 7500 | 148.487 | 45.634 | 3.254x | 
 | 10000 | 218.167 | 70.168 | 3.109x | 
 | 20000 | 444.836 | 152.145 | 2.924x | 
 | 30000 | 556.671 | 268.679 | 2.072x | 
