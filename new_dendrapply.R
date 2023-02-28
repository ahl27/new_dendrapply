##
## dendrapply: applies function recursively to dendrogram object
## -------------
## Aidan Lakshman (AHL27@pitt.edu)
##
dendrapply <- function(X, FUN, ..., how=c("pre.order", "post.order")){
  apply_method <- match.arg(how)
  travtype <- switch(apply_method,
                     pre.order=0L,
                     post.order=1L)
  ## Free allocated memory in case of early termination
  on.exit(.C("free_dendrapply_list"))
  stopifnot(is(X, 'dendrogram'))
  wrapper <- \(node) {
    # I'm not sure why VECTOR_ELT unclasses the object
    # nodes coming in should always be dendrograms
    class(node) <- 'dendrogram'
    res<-FUN(node, ...)
    if(!is.leaf(node)){
      if(!(inherits(res,c('dendrogram', 'list')))){
        res <- lapply(unclass(node), \(x) x)
      } 
    }
    res
  }
  # If we only have one node, it'll hang
  # We can get around this by just applying the function to the leaf
  # and returning--no need for C code here.
  if(is.leaf(X)){
    return(wrapper(X))
  }
  return(.Call("do_dendrapply", X, wrapper, parent.frame(), travtype))
}