#include "new_dendrapply.h"

/*
 * Author: Aidan Lakshman
 * Contact: AHL27@pitt.edu
 *
 * This is a set of C functions that apply an R function to all internal
 * nodes of a dendrogram object. This implementation runs roughly 2x
 * faster than base `stats::dendrapply`, and deals with dendrograms
 * with high numbers of internal branches. Notably, this implementation
 * unrolls the recursion to prevent any possible stack overflow errors. 
 * 
 * Full Description of implementation:
 *
 * ll_S_dendrapply is essentially a doubly-linked list node struct with 
 * some additional data. For each node, we lazily allocated a node containing
 * a pointer to the SEXP object, a pointer to the next element of the linked list,
 * and a pointer to the node containing the parent SEXP object from R. For each
 * node in the dendrogram, we create a linked list node for it in C, allowing
 * us to traverse the linked list iteratively to evaluate the function at all nodes.
 * The secondary link is to reconstruct the original dendrogram structure.
 * See the header file for description of the additional data in the struct.
 *
 */

/* Global variable for on.exit() free */
ll_S_dendrapply *dendrapply_ll;
static SEXP leafSymbol, iSEXPval, class;
static PROTECT_INDEX headprot;

/* 
 * Function to allocate a dummy LL node 
 * Lazy, values are filled with assign_dendnode_child
 */
ll_S_dendrapply* alloc_link(ll_S_dendrapply* parentlink, int i){
  ll_S_dendrapply *link = malloc(sizeof(ll_S_dendrapply));
  link->node = NULL;
  link->isLeaf = -1;
  link->origLength = 0;
  link->next = NULL;
  link->v = i;
  link->parent = parentlink;
  link->remove = 0;

  return link;
}

/* 
 * Assign the child of a node to a link
 * Some traversals use lazy evaluation; this fills in these unevaluated nodes
 */
ll_S_dendrapply* assign_dendnode_child(ll_S_dendrapply* link, ll_S_dendrapply* parentlink, int i, int fast){
  SEXP curnode = get_dend_child(parentlink, i, fast, 1);
  link->node = curnode;
  SEXP ls = getAttrib(curnode, leafSymbol);
  link->isLeaf = (isNull(ls) || (!LOGICAL(ls)[0])) ? length(curnode) : 0;
  link->origLength = link->isLeaf;

  return link;
}

/*
 * Get the i'th element of a dendrogram node
 *
 * If fast is TRUE, we just use stats:::`[[.dendrogram`
 * If fast is FALSE, we build and apply a call to node[[i]] (NOT YET IMPLEMENTED)
 */
SEXP get_dend_child(ll_S_dendrapply* link, int i, int fast, int shouldReclass){
  /*
  SEXP curnode;
  if(fast){
    curnode = VECTOR_ELT(link->node, i);
    if(shouldReclass)
      classgets(curnode, class);
  } else {
     * Build call like in lapply: FUN(X[[<ind>]], ...)
     * does this need to be protected?
    Rprintf("i: %d\n");
    INTEGER(iSEXPval)[0] = i;
    SEXP tmp = PROTECT(lang3(install("[["), link->node, iSEXPval));
    curnode = R_forceAndCall(tmp, 1, env);
    UNPROTECT(1);
  }
  */

  SEXP curnode = VECTOR_ELT(link->node, i);
  if(shouldReclass)
    classgets(curnode, class);
  return(curnode);
}

/*
 * Apply function to a dendrogram node
 * CONSUMES TWO SPACES ON PROTECT STACK
 */
SEXP apply_func_dend_node(ll_S_dendrapply* link, SEXP f, SEXP env){
  SEXP call = PROTECT(LCONS(f, LCONS(link->node, R_NilValue)));
  SEXP newnode = PROTECT(R_forceAndCall(call, 1, env));
  return(newnode);
}

/* 
 * Frees the global linked list structure.
 *
 * Called using on.exit() in R for cases where
 * execution is stopped early.
 */
void free_dendrapply_list(){
  ll_S_dendrapply *ptr = dendrapply_ll;
  while(dendrapply_ll){
    dendrapply_ll = dendrapply_ll->next;
    free(ptr);
    ptr=dendrapply_ll;
  }

  return;
}


/*
 * Main workhorse function.
 * 
 * This function traverses the tree INORDER (as in stats::dendrapply)
 * or POSTORDER and applies the function to each node, then adds its 
 * children to the linked list. Once all the children of a node have 
 * been processed, the child subtrees are combined into the parent. 
 * R ensures that the dendrogram isn't a leaf, so this function assmes 
 * the dendrogram has at least two members.
 */
SEXP dendrapply_internal_func(ll_S_dendrapply* head, SEXP f, SEXP env, short travtype, int fast){
  ll_S_dendrapply *ptr, *prev;
  SEXP node, call, newnode, leafVal;

  /* for inorder traversal, apply function to root and reprotect it */
  if(travtype == 0){
    call = PROTECT(LCONS(f, LCONS(head->node, R_NilValue)));
    REPROTECT(head->node = R_forceAndCall(call, 1, env), headprot);
    UNPROTECT(1);
  }

  int n, nv;
  ptr = head;
  prev = head;
  while(ptr){
    R_CheckUserInterrupt();
    /* lazily populate node, apply function to it as well */
    if (travtype==0 && ptr->isLeaf==-1){
      ptr = assign_dendnode_child(ptr, ptr->parent, ptr->v, fast);
      ptr->node = apply_func_dend_node(ptr, f, env);

      n = length(ptr->parent->node);
      nv = ptr->v;
      while(nv < n){
        /* trying to replicate a weird stats::dendrapply quirk */
        /* this may need to be removed later */
        SET_VECTOR_ELT(ptr->parent->node, nv, ptr->node);
        nv += ptr->parent->origLength;
      }

      UNPROTECT(2);

      /* double child access because it avoids a protect */
      ptr->node = get_dend_child(ptr->parent, ptr->v, fast, 0);
    }

    if (ptr->remove){
      /* these are nodes flagged for deletion */
      prev->next = prev->next->next;
      free(ptr);
      ptr = prev->next;

    } else if(ptr->isLeaf == 0){
      /* 
      * If the LL node is a leaf or completely merged subtree,
      * apply the function to it and then merge it upwards
      */
      while(ptr->isLeaf == 0 && ptr != head){
        /* 
         * merge upwards, 
         * protection unneeded since parent already protected 
         */
        prev = ptr->parent;
        if(travtype == 0){
          SET_VECTOR_ELT(prev->node, ptr->v, ptr->node);
        } else if(travtype == 1){
          newnode = apply_func_dend_node(ptr, f, env);
          prev = ptr->parent;
          SET_VECTOR_ELT(prev->node, ptr->v, newnode);
          UNPROTECT(2);
        }
        prev->isLeaf -= 1;

        /* flag node for deletion later */
        ptr->remove = 1;
        ptr = prev;
        prev = ptr;
        R_CheckUserInterrupt();
      }

      /* go to the next element so we don't re-add */
      ptr = ptr->next;

    } else {
      /* ptr->isLeaf != 0, so we need to add nodes */
      node = ptr->node;
      n = ptr->origLength;
      leafVal = getAttrib(node, leafSymbol);
      
      if(isNull(leafVal) || (!LOGICAL(leafVal)[0])){
        ll_S_dendrapply *newlink;
        /*
         * iterating from end to beginning to ensure 
         * we traverse depth-first instead of breadth
         */
        for(int i=n-1; i>=0; i--){
          newlink = alloc_link(ptr, i);
          if(travtype == 1)
            newlink = assign_dendnode_child(newlink, ptr, i, fast);
          newlink->next = ptr->next;
          ptr->next = newlink;
        }
      }
      prev = ptr;
      ptr = ptr->next; 
    }
  }

  /* apply function to the root node (last) if post-order traversal */
  if (travtype == 1){
    call = PROTECT(LCONS(f, LCONS(head->node, R_NilValue)));
    REPROTECT(head->node = R_forceAndCall(call, 1, env), headprot);
    UNPROTECT(1);
  }
  
  return head->node;
}

/*
 * Main Function
 * 
 * Calls helper functions to build linked list,
 * apply function to all nodes, and reconstruct
 * the dendrogram object. Attempts to free the linked list 
 * at termination, but note memory free not guaranteed to 
 * execute here due to R interrupts. on.exit() used in R to 
 * account for this.
 */
SEXP C_dendrapply(SEXP tree, SEXP fn, SEXP env, SEXP order, SEXP isFast){
  /* 0 for preorder, 1 for postorder */
  leafSymbol = install("leaf");
  short travtype = INTEGER(order)[0];
  int fast = LOGICAL(isFast)[0];
  if(fast){
    /* fast execution replicates `[[.dendrogram` in C */
    class = PROTECT(allocVector(STRSXP, 1));
    SET_STRING_ELT(class, 0, mkChar("dendrogram"));
  } else {
    /* slow execution asks R for `[[` on the object z*/
    iSEXPval = PROTECT(allocVector(INTSXP, 1));
  }
  SEXP treecopy;
  PROTECT_WITH_INDEX(treecopy = duplicate(tree), &headprot);

  /* Add the top of the tree into the list */
  dendrapply_ll = alloc_link(NULL, -1);
  dendrapply_ll->node = treecopy;
  dendrapply_ll->isLeaf = length(treecopy);
  dendrapply_ll->origLength = dendrapply_ll->isLeaf;

  /* Apply the function to the list */
  treecopy = dendrapply_internal_func(dendrapply_ll, fn, env, travtype, fast);
  
  /* Attempt to free the linked list and unprotect */
  free_dendrapply_list();
  UNPROTECT(2);
  return treecopy;
}