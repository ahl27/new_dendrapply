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

  if (!inherits(X, "dendrogram")) 
        stop("'X' is not a dendrogram")

  ## If a user has their own subset operations, we have to handle them
  vf <- unlist(lapply(class(X), \(cls) getS3method("[[", cls, optional=TRUE)))
  shouldUseFast <- length(vf) <= 1 && identical(environment(vf), environment(stats::dendrapply))

  ## Free allocated memory in case of early termination
  on.exit(.C("free_dendrapply_list"))

  ## Main function
  wrapper <- function(node) {
    res<-FUN(node, ...)
    if(!is.leaf(node)){
      ## We always have to apply the function to children!
      ## Sometimes application of the function destroys child nodes
      ## ex. `dendrapply(dend, labels)` converts dendrogram nodes to character vectors
      ## So here we overwrite destroyed unevaluated nodes with their original state
      if(!(inherits(res,c("dendrogram", "list"))))
        res[seq_along(node)] <- node[]
    }
    res
  }
  
  ## If we only have one node, it'll hang
  ## We can get around this by just applying the function to the leaf
  ## and returning--no need for C code here.
  if(!is.null(attr(X, "leaf")) && attr(X,"leaf")){
    return(wrapper(X))
  }

  ## Else we apply the function to all nodes
  return(.Call("C_dendrapply", X, wrapper, parent.frame(), travtype, shouldUseFast))
}