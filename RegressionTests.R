### Testing current functionality ###
D <- as.dendrogram(hclust(dist(cbind(setNames(c(0,1,4), LETTERS[1:3])))))

## Testing traversals -- are we visiting nodes in the right order?
test_labels <- LETTERS[1:5]
i <- 1L

test_preorder <- dendrapply(D, \(x) {
  if(is.leaf(x))
    attr(x, 'label') <- test_labels[i]
  i <<- i+1L
  x
  })

stopifnot(identical(c("B","D","E"), labels(test_preorder)))

i <- 1L
test_postorder <- dendrapply(D, \(x){
  if(is.leaf(x))
    attr(x, 'label') <- test_labels[i]
  i <<- i+1L
  x
  }, how='post.order')
stopifnot(identical(c("A","B","C"), labels(test_postorder)))

## Testing functions that don't return dendrogram objects
test_nonleaf_post <- dendrapply(D, \(x){
  if(is.leaf(x)) return(attr(x,'label'))
  return(unlist(x))
  }, how='post.order')

stopifnot(identical(labels(D), test_nonleaf_post))

## This should throw a warning!
test_nonleaf_pre <- dendrapply(D, \(x){
  if(is.leaf(x)) return(attr(x,'label'))
  return(unlist(x))
  }, how='pre.order')

stopifnot(identical(test_nonleaf_pre, list("C", list("A","B"), "C")))

# What happens when the function returns NULL?
stopifnot(is.null(dendrapply(D, \(x) NULL, how='post.order')))
stopifnot(identical(dendrapply(D, \(x) NULL), list(NULL, list(NULL, NULL))))
