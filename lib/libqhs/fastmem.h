/****************************************************************************/
/*                                                                          */
/*    Customized and/or optimized memory-management routines.               */
/*                                                                          */
/* Rob Siverd                                                               */
/* Created:       2011-08-02                                                */
/* Last modified: 2013-11-08                                                */
/*                                                                          */
/****************************************************************************/
/****************************************************************************/
/*--------------------------------------------------------------------------*/

#ifdef __cplusplus   /* C++ compatibility */
extern "C" {         /* C++ compatibility */
#endif               /* C++ compatibility */

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/* Include guard prevents redefinition: */
#ifndef HAVE_FASTMEM_H

/*--------------------------------------------------------------------------*/
#define HAVE_FASTMEM_H /* only include once */

#define SHARED_FASTMEM_VERSION 1.1.2

/*--------------------------------------------------------------------------*/
/* Allocate array with supplied alignment (if possible), otherwise malloc:  */
double *allocate_aligned_array_dbl(long, int); 

int allocate_aligned_array(void **, long, int);  /* general-purpose version */

/*--------------------------------------------------------------------------*/

#endif /* end of include-guard */

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

#ifdef __cplusplus   /* C++ compatibility */
}                    /* C++ compatibility */
#endif               /* C++ compatibility */

