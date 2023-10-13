path_to_cfile <- './new_dendrapply.c'
path_to_rfile <- './new_dendrapply.R'
######################################

##### Loading Shared Library #####
rcmdbuild <- paste0("R CMD SHLIB ", path_to_cfile)
path_to_so <- gsub('(.*)\\.c$', '\\1.so', path_to_cfile)
system(rcmdbuild)
#dyn.unload(path_to_so)
dyn.load(path_to_so)
source(path_to_rfile)
##################################


make_balanced_tree <- function(num_leaves){
  return(as.dendrogram(hclust(dist(seq_len(num_leaves)))))
}

# function modifying nodes
exFunc <- function(node){
  attr(node, 'newAttribute') <- 'a'
  return(node)
}

# runs all and checks runtimes, speedup is about 2x for me
to_check <- c(5, 10, 25, 50, 100, 500, 1000, 2500, 5000, 7500, 10000)
resNew <- resOld <- rep(Inf, length(to_check))
for(i in seq_along(to_check)){
  cat(to_check[i], 'leaves\n')
  tree <- make_balanced_tree(to_check[i])
  res <- microbenchmark::microbenchmark(dendrapply(tree, \(x) x),
                                        stats::dendrapply(tree, exFunc)
  )    
  res <- tapply(res$time, res$expr, mean)[sort(unique(res$expr))]
  resNew[i] <- res[1]
  resOld[i] <- res[2]
}
Ex <- data.frame(nleaves = to_check, Oldns=resOld, Newns=resNew)
Ex$speedup = Ex$Oldns / Ex$Newns

cat("\nResults:\n")
print(Ex)

# dhc <- as.dendrogram(hc <- hclust(dist(USArrests), "ave"))
# (dhc21 <- dhc[[2]][[1]])
# #stats::dendrapply(dhc21, function(n) utils::str(attributes(n)))
# #dendrapply(dhc21, function(n) utils::str(attributes(n)))
# str(dendrapply(dhc21, \(x) x))