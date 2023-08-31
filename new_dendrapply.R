##
## dendrapply: applies function to all nodes of dendrogram object
## -------------
## Aidan Lakshman (AHL27@pitt.edu)
##
dendrapply <- function(X, FUN, ..., how=c("pre.order", "post.order")){
  apply_method <- match.arg(how)
  travtype <- switch(apply_method,
                     pre.order=0L,
                     post.order=1L)

  ## At some point I'd like to open this up to general nested lists
  ## This would require an alternate way to determine what is a leaf
  if (!inherits(X, "dendrogram")) 
        stop("'X' is not a dendrogram")

  ## Free allocated memory in case of early termination
  on.exit(.C("free_dendrapply_list"))

  ## Main function
  wrapper <- function(node) {
    res<-FUN(node, ...)
    if(travtype==0L && !is.leaf(node) && !inherits(res, c("dendrogram", "list"))){
      ## We always have to apply the function to children!
      ## Sometimes application of the function destroys child nodes
      ## ex. `dendrapply(dend, labels)` converts dendrogram nodes to character vectors
      ## So here we overwrite destroyed unevaluated nodes with their original state
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
  return(.Call("C_dendrapply", X, wrapper, parent.frame(), travtype))
}