#include <R.h>
#include <Rdefines.h>

/*
 * Linked list struct
 *
 * Each node of the tree is added with the following args:
 *  -   node: tree node, as a pointer to SEXPREC object
 *  -      v: location in parent node's list
 *  - isLeaf: Counter encoding unmerged children. 0 if leaf or leaf-like subtree.
 *  - parent: pointer to node holding the parent node in the tree
 *  -   next: next linked list element
 * 
 */
typedef struct ll_S_dendrapply {
  SEXP node;
  int v;
  unsigned int remove : 1;
  signed int isLeaf : 7;
  unsigned int origLength;
  struct ll_S_dendrapply *parent;
  struct ll_S_dendrapply *next;
} ll_S_dendrapply;

/* helper functions */
ll_S_dendrapply* assign_dendnode_child(ll_S_dendrapply* link, ll_S_dendrapply* parentnode_R, int i, int fast);
ll_S_dendrapply* alloc_link(ll_S_dendrapply* parentlink, int i);
SEXP get_dend_child(ll_S_dendrapply* link, int i, int fast, int shouldReclass);
SEXP apply_func_dend_node(ll_S_dendrapply* link, SEXP f, SEXP env);
SEXP main_apply_dend_func(ll_S_dendrapply *head, SEXP f, SEXP env, short travtype, int fast);


/* .C Interface Functions */
void free_dendrapply_list(void);

/* .Call Interface Functions */
SEXP C_dendrapply(SEXP tree, SEXP fn, SEXP env, SEXP order, SEXP isFast);