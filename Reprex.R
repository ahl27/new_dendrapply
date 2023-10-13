## new examples, with bytecode-compiled functions
options(expressions=500)

# 256 is the around the upper limit at expressions=25
# this of course increases as expressions increases
tree1 <- as.dendrogram(hclust(dist(seq_len(257L))))
identity <- function(x) x
try(stats::dendrapply(tree1, identity))
try(stats:::old_dendrapply(tree1, identity))

options(expressions=25)
try(stats::dendrapply(tree1, identity))
try(stats:::old_dendrapply(tree1, identity)) #Error : evaluation nested too deeply: infinite recursion / options(expressions=)?


# Ensuring equality, thanks MM
options(expressions=500)
o1 <- stats::dendrapply(tree1, identity)
oc <- stats:::old_dendrapply(tree1, identity) # *does* work fine - even with expressions = 40 !!
stopifnot(identical(o1, oc))

same <- function(f,g) {
  typeof(f) == typeof(g) && isTRUE(all.equal(body(f), body(g))) &&
    {
      ii <- seq_len(min(length(a1 <- formals(f)),
                        length(a2 <- formals(g))))
      identical(a1[ii], a2[ii])
    }
}

cat("same: ", same(stats::dendrapply, stats:::old_dendrapply), "\n")

if(!same(stats::dendrapply, stats:::old_dendrapply)) {
  oN <- dendrapply(tree1, identity) # Completes successfully
} else oN <- oc

## MM:
d.oN <- deparse(oN)
pd.oN <- eval(parse(text = d.oN))
options(expressions = 500)
# Changed this sum since the tree is now smaller than the original ex
stopifnot(identical(oN, pd.oN),
          sum(nchar(d.oN)) == 48498)
