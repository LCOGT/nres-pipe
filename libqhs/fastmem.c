/****************************************************************************/
/*                                                                          */
/*    customized and/or optimized memory-management routines.               */
/*                                                                          */
/* Rob Siverd                                                               */
/* Created:       2011-08-02                                                */
/* Last modified: 2013-11-08                                                */
/*                                                                          */
/****************************************************************************/
/****************************************************************************/

/* Various standard libraries: */
#include  <stdlib.h>

/* Specialized memory allocation (if available): */
#if (_POSIX_C_SOURCE >= 200112L || _XOPEN_SOURCE >= 600)
# include  <malloc.h>
# define HAVE_MEMALIGN 1
#endif

/*--------------------------------------------------------------------------*/
/* Allocate array with supplied alignment (if possible), otherwise malloc:  */
double *allocate_aligned_array_dbl (
                                    long size,   /* how many array elements */
                                     int align   /* address alignment bytes */
                                   )
{
   double *array = NULL;
   long bytes = size * sizeof(*array);

   /* Allocate array with best available method: */
#ifdef HAVE_MEMALIGN
   if ( posix_memalign((void**)&array, align, bytes) ) {
#else
   align = 0;  /* avoid 'unused parameter' error */
   if ( (array = malloc(bytes)) == NULL ) {
#endif
      array = NULL; /* enforce NULL on failure */
   }

   /* Return pointer (may be NULL): */
   return array;
}


/*--------------------------------------------------------------------------*/
/* Allocate array with supplied alignment (if possible), otherwise malloc:  */
int allocate_aligned_array (
                            void **array,    /* where to allocate the array */
                            long   bytes,    /* required array size (bytes) */
                             int   align     /* data alignment in new array */
                           )
{
   /* Allocate array with best available method: */
#ifdef HAVE_MEMALIGN
   if ( posix_memalign(array, align, bytes) ) {
#else
   align = 0;  /* avoid 'unused parameter' error */
   if ( (*array = malloc(bytes)) == NULL ) {
#endif
      *array = NULL; /* enforce NULL on failure */
      return 1;      /* report failure */
   } else {
      return 0;      /* report success */
   }
}


/*--------------------------------------------------------------------------*/





