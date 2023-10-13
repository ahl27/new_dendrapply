library(microbenchmark)

identity <- function(x) x
to_test_leaves <- c(5, 10, 25, 50, 100, 250, 500, 1000, 2000)
timeOld <- timeNew <- timeSpeedup <- rep(0, length(to_test_leaves))
for(i in seq_along(to_test_leaves)){
  nleaf <- to_test_leaves[i]
  tree <- as.dendrogram(hclust(dist(seq_len(nleaf))))
  res <- microbenchmark::microbenchmark(stats:::dendrapply(tree, identity),
                                        stats:::old_dendrapply(tree, identity))
  res <- tapply(res$time, res$expr, mean)[sort(unique(res$expr))]
  timeNew[i] <- res[1]
  timeOld[i] <- res[2]
}
timeSpeedup <- timeOld / timeNew
results <- cbind(to_test_leaves, timeOld, timeNew, round(timeSpeedup,3))
colnames(results) <- c("num_leaves", "old_dendrapply", "new_dendrapply", "speedup")
print(results)
