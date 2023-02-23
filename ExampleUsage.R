path_to_cfile <- './new_dendrapply_inorder.c'
path_to_rfile <- './new_dendrapply.R'
######################################

##### Loading Shared Library #####
library(dendextend)
rcmdbuild <- paste0("R CMD SHLIB ", path_to_cfile)
path_to_so <- gsub('(.*)\\.c$', '\\1.so', path_to_cfile)
system(rcmdbuild)
#dyn.unload(path_to_so)
dyn.load(path_to_so)
source(path_to_rfile)
##################################


make_balanced_tree <- function(num_leaves){
  seq_len(num_leaves) %>%
    dist() %>%
    hclust() %>%
    as.dendrogram() 
}

# function modifying nodes
exFunc <- function(node){
  attr(node, 'newAttribute') <- 'a'
  return(node)
}

# function calling a recursive function
exFuncRecur <- \(x){
  if(!is.null(attr(x, 'leaf')))
    return(x)
  attr(x, 'members') <- sum(rapply(x, \(y){
    attr(y, 'members')
  }))
  return(x)
}

# function that doesn't return a dendrogram
j <- 0
exFuncNoMod <- \(x){
  j <<- attr(x, "members")
}

# runs all and checks runtimes, speedup is about 2x for me
to_check <- c(5, 10, 25, 50, 100, 500, 1000, 2500, 5000, 7500, 10000)
resNew <- resOld <- rep(Inf, length(to_check))
resNewR <- resOldR <- rep(Inf, length(to_check))
resNewN <- resOldN <- rep(Inf, length(to_check))
for(i in seq_along(to_check)){
  cat(to_check[i], 'leaves\n')
  tree <- make_balanced_tree(to_check[i])
  res <- microbenchmark::microbenchmark(dendrapply(tree, exFunc),
                                        stats::dendrapply(tree, exFunc),
                                        unit = 'millisecond', times=10
  )  
  resR <- microbenchmark::microbenchmark(dendrapply(tree, exFuncRecur),
                                         stats::dendrapply(tree, exFuncRecur),
                                         unit = 'millisecond', times=10
  )  
  resN <- microbenchmark::microbenchmark(dendrapply(tree, exFunc),
                                         stats::dendrapply(tree, exFunc),
                                         unit = 'millisecond', times=10
  )  
  res <- tapply(res$time, res$expr, mean)[sort(unique(res$expr))]
  resNew[i] <- res[1]
  resOld[i] <- res[2]
  res <- tapply(resN$time, resN$expr, mean)[sort(unique(resN$expr))]
  resNewN[i] <- res[1]
  resOldN[i] <- res[2]
  res <- tapply(resR$time, resR$expr, mean)[sort(unique(resR$expr))]
  resNewR[i] <- res[1]
  resOldR[i] <- res[2]
}
Recur <- data.frame(nleaves = to_check, Oldns=resOldR, Newns=resNewR)
NoMod <- data.frame(nleaves = to_check, Oldns=resOld, Newns=resNew)
WithMod <- data.frame(nleaves = to_check, Oldns=resOldN, Newns=resNewN)
Recur$speedup = Recur$Oldns / Recur$Newns
NoMod$speedup = NoMod$Oldns / NoMod$Newns
WithMod$speedup = WithMod$Oldns / WithMod$Newns
