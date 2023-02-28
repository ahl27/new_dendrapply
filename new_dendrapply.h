#include <R.h>
#include <Rdefines.h>

/* .C Inteface Functions */
void free_dendrapply_list(void);

/* .Call Interface Functions */
SEXP do_dendrapply(SEXP tree, SEXP fn, SEXP env, SEXP order);