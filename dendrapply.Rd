\name{dendrapply}
\alias{dendrapply}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Apply a Function to All Nodes of a Dendrogram
}
\description{
Apply function FUN to each node of a dendrogram recursively. When y <- dendrapply(x, fn), then y is a dendrogram of the same graph structure as x and for each node, y.node[j] <- FUN( x.node[j], ...) (where y.node[j] is an (invalid!) notation for the j-th node of y). Also provides flexibility in the order in which nodes are evaluated.
}
\usage{
dendrapply(X, FUN, ..., 
            how = c("in.order", "post.order"))
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{X}{
  An object of class \code{"\link[stats]{dendrogram}"}.
}
  \item{FUN}{
An R function to be applied to each dendrogram node, typically working on its \code{\link[base]{attributes}} alone, returning an altered version of the same node.
}
  \item{\dots}{
potential further arguments passed to \code{FUN}.
}
  \item{how}{
one of \code{c("in.order", "post.order")}, or an unambiguous abbreviation. Determines if nodes should be evaluated according to an inorder (default) or postorder traversal. See details for more information.
}
}
\details{
\code{"in.order"} preserves the functionality of the previous \code{dendrapply}. For each node \code{n}, \code{FUN} is applied first to \code{n}, then to \code{n[[1]]} (and any children it may have), then \code{n[[2]]} and its children, etc. 

\code{"post.order"} allows for calculations that depend on the children of a given node. For each node \code{n}, \code{FUN} is applied first to \emph{all} children of \code{n}, then is applied to \code{n} itself. 
}
\value{
Usually a dendrogram of the same (graph) structure as \code{X}. For that, the function must be conceptually of the form \code{FUN <- function(X) \{ attributes(X) <- .....; X \}}, i.e., returning the node with some attributes added or changed.

If the function provided does not return the node, the result is a nested list of the same structure as \code{X}, or as close as can be achieved with the return values. If the function should only be applied to the leaves of \code{X}, consider using \code{\link[base]{rapply}} instead.
}
\references{
%% ~put references to the literature/web site here ~
}
\author{
%%  ~~who you are~~
}
\note{
The prior implementation of \code{dendrapply} was recursive and inefficient for dendrograms with many non-leaves. This version is no longer recursive, and thus should no longer cause issues stemming from insufficient C stack size (as mentioned in the 'Warning' in \code{\link[stats]{dendrogram}}).
}

%% ~Make other sections like Warning with \section{Warning }{....} ~

\seealso{
\code{\link{as.dendrogram}}, \code{\link[base]{lapply}} for applying a function to each component of a list. 

\code{\link[base]{rapply}} is particularly useful for applying a function to the leaves of a dendrogram, and almost always be used when the function does not need to be applied to interior nodes due to significantly better performance.
}
\examples{
require(graphics)

## a smallish simple dendrogram
dhc <- as.dendrogram(hc <- hclust(dist(USArrests), "ave"))
(dhc21 <- dhc[[2]][[1]])

## too simple:
dendrapply(dhc21, function(n) utils::str(attributes(n)))

## toy example to set colored leaf labels :
local({
  colLab <<- function(n) {
      if(is.leaf(n)) {
        a <- attributes(n)
        i <<- i+1
        attr(n, "nodePar") <-
            c(a$nodePar, list(lab.col = mycols[i], lab.font = i%%3))
      }
      n
  }
  mycols <- grDevices::rainbow(attr(dhc21,"members"))
  i <- 0
 })
dL <- dendrapply(dhc21, colLab)
op <- par(mfrow = 2:1)
 plot(dhc21)
 plot(dL) ## --> colored labels!
par(op)
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory (show via RShowDoc("KEYWORDS")):
% \keyword{ ~kwd1 }
% \keyword{ ~kwd2 }
% Use only one keyword per line.
% For non-standard keywords, use \concept instead of \keyword:
% \concept{ ~cpt1 }
% \concept{ ~cpt2 }
% Use only one concept per line.