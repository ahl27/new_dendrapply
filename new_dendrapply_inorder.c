#include <R.h>
#include <Rdefines.h>
#include "dendextend.h"

/*
 * Author: Aidan Lakshman
 * Contact: AHL27@pitt.edu
 *
 * This is a set of C functions that apply an R function to all internal
 * nodes of a dendrogram object. This implementation runs roughly 3x
 * faster than base `stats::dendrapply`, and deals with dendrograms
 * with high numbers of internal branches. Notably, this implementation
 * unrolls the recursion to prevent any possible stack overflow errors. 
 *
 */

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
typedef struct ll_S {
  SEXP node;
  int v;
  int isLeaf;
  struct ll_S *parent;
  struct ll_S *next;
  PROTECT_INDEX protptr;
  char isProtected;
} ll_S;


/* Global variable for on.exit() free */
ll_S *ll;

/* 
 * Frees the global linked list structure.
 *
 * Called using on.exit() in R for cases where
 * execution is stopped early.
 */
void free_dendrapply_list(){
  ll_S *ptr = ll;
  while(ll){
    ll = ll->next;
    free(ptr);
    ptr=ll;
  }

  return;
}

/* Function to allocate a LL node */
ll_S* alloc_link(ll_S* parentlink, SEXP node, int i){
  ll_S *link = malloc(sizeof(ll_S));

  /* lazy evaluation of the nodes to conserve PROTECT calls */
  link->node = NULL;
  link->next = NULL;
  link->v = i;
  link->parent = parentlink;
  link->isLeaf = -1;
  link->isProtected = 0;
  
  return link;
}


/*
 * Main workhorse function.
 * 
 * This function traverses the tree INORDER (as in stats::dendrapply)
 * and applies the function to each node, then adds its children to
 * the linked list. Once all the children of a node have been processed,
 * the child subtrees are combined into the parent. R ensures that the
 * dendrogram isn't a leaf, so this function assmes the dendrogram has 
 * at least two members.
 */
SEXP new_apply_dend_func(ll_S *head, SEXP f, SEXP env){
  ll_S *ptr, *prev, *parent;
  SEXP node, call, newnode;
  PROTECT_INDEX callptr;

  /* Reserve space in the protect stack and process root */
  PROTECT_WITH_INDEX(call = LCONS(f, LCONS(head->node, R_NilValue)), &callptr);
  REPROTECT(head->node = R_forceAndCall(call, 1, env), head->protptr);

  int n;
  ptr = head;
  prev = head;
  while(ptr){
    R_CheckUserInterrupt();
    /* lazily populate node, apply function to it as well */
    if (!(ptr->isProtected)){
      parent = ptr->parent;
      newnode = VECTOR_ELT(parent->node, ptr->v);
      ptr->isLeaf = isNull(getAttrib(newnode, install("leaf"))) ? length(newnode) : 0;
      REPROTECT(call = LCONS(f, LCONS(newnode, R_NilValue)), callptr);
      newnode = PROTECT(R_forceAndCall(call, 1, env));
      SET_VECTOR_ELT(parent->node, ptr->v, newnode);
      UNPROTECT(1);

      /* double ELT because it avoids a protect */
      ptr->node = VECTOR_ELT(parent->node, ptr->v);
      ptr->isProtected = 1;
    }

    if (ptr->isProtected == 2){
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
        /* merge upwards, 
         * protection unneeded since parent already protected 
         */
        prev = ptr->parent;
        SET_VECTOR_ELT(prev->node, ptr->v, ptr->node);
        UNPROTECT(1);
        prev->isLeaf -= 1;

        /* flag node for deletion later */
        ptr->isProtected = 2;
        ptr = prev;
        prev = ptr;
        R_CheckUserInterrupt();
      }

      /* go to the next element so we don't re-add */
      ptr = ptr->next;

    } else {
      /* ptr->isLeaf != 0, so we need to add nodes */
      node = ptr->node;
      n = length(node);

      if(isNull(getAttrib(node, install("leaf")))){
        ll_S *newlink;
        /*
         * iterating from end to beginning to ensure 
         * we traverse depth-first instead of breadth
         */
        for(int i=n-1; i>=0; i--){
          newlink = alloc_link(ptr, node, i);
          newlink->next = ptr->next;
          ptr->next = newlink;
        }
      }
      prev = ptr;
      ptr = ptr->next; 
    }
  }

  /* Unprotect the SEXP for the function call */
  UNPROTECT(1);
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
SEXP do_dendrapply(SEXP tree, SEXP fn, SEXP env){
  PROTECT_INDEX headprot;
  SEXP treecopy;
  PROTECT_WITH_INDEX(treecopy = duplicate(tree), &headprot);

  /* Add the top of the tree into the list */
  ll = malloc(sizeof(ll_S));
  ll->node = treecopy;
  ll->next = NULL;
  ll->parent = NULL;
  ll->isLeaf = length(treecopy);
  ll->v = -1;
  ll->isProtected = 1;
  ll->protptr = headprot;

  /* Build the list */
  //build_list(ll);

  /* Apply the function to the list */
  treecopy = new_apply_dend_func(ll, fn, env);
  
  /* Attempt to free the linked list and unprotect */

  free_dendrapply_list();
  UNPROTECT(1);
  return treecopy;
}



