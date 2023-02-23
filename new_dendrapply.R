path_to_cfile <- '~/Documents/new_dendrapply/new_dendrapply.c'

##### Loading Shared Library #####
rcmdbuild <- paste0("R CMD SHLIB ", path_to_cfile)
path_to_so <- gsub('(.*)\\.c$', '\\1.so', path_to_cfile)
system(rcmdbuild)
dyn.load(path_to_so)
##################################

## Main Function
##
## Bugs:
## - Getting nodes as unclass(node) for some reason
new_dendrapply <- function(X, FUN, ...){
  ## Free allocated memory in case of early termination
  on.exit(.C("free_dendrapply_list"))
  stopifnot(is(X, 'dendrogram'))
  wrapper <- \(node) {
    # I'm not sure why VECTOR_ELT unclasses the object
    # nodes coming in should always be dendrograms
    class(node) <- 'dendrogram'
    res<-FUN(node, ...)
    if(length(node)!=1){
      if(!(inherits(res, c('dendrogram', 'list')))){
        res <- vapply(seq_along(node), \(i) list(list(i)), list(list()))
      }
    }
    res
  }
  # If we only have one node, it'll hang
  # We can get around this by just applying the function to the leaf
  # and returning--no need for C code here.
  if(!is.null(attr(X, 'leaf')) && attr(X,'leaf')){
    return(wrapper(X))
  }
  return(.Call("do_dendrapply", X, wrapper, parent.frame()))
}

new_dendrapply(tree, exFunc)