/****************************************************************************/
/*                                                                          */
/*    Miscellaneous routines.  This is the master copy, shared among all    */
/* utilities for simplicity.                                                */
/*                                                                          */
/* Rob Siverd                                                               */
/* Created:       2010-06-16                                                */
/* Last modified: 2015-06-19                                                */
/*                                                                          */
/****************************************************************************/
/****************************************************************************/
/*--------------------------------------------------------------------------*/

//#include    <errno.h>
#include    <stdio.h>
#include   <stdlib.h>
#include   <string.h>
#include <sys/time.h>

/*--------------------------------------------------------------------------*/
/* Determine the basename of a file (remove the path if necessary):         */
char *basename(char *full_path)
{
   char *base = strrchr(full_path, '/');  /* move to position of last '/'   */

   if ( base == NULL ) return full_path;  /* return input if no '/' found   */

   return (base + 1);                     /* otherwise, point string past / */
}

/*--------------------------------------------------------------------------*/
/* Determine the basename of a file (remove the path if necessary):         */
char *file_ext(char *FullName)
{
   char *ext = strrchr(FullName, '.');   /* Move to position of last '.'    */

   if ( ext == NULL ) {
      ext = FullName + strlen(FullName);
   } else {
      ext += 1;
   }
   
   return ext;
}

/*--------------------------------------------------------------------------*/
/* Even/odd integer testing:                                                */
//long is_odd(long value)
//{
//   return (value & 1);
//}

/*--------------------------------------------------------------------------*/
/* Get the current time in decimal seconds since beginning of epoch:        */
#define T_OFFSET 1310000000
double now(void)
{
   struct timeval tim;
   double Seconds;
   long   macrosec;

   gettimeofday(&tim, NULL); /* get current time */

   macrosec = (long)tim.tv_sec - T_OFFSET;  /* adjust for sane number */
   Seconds  = (double)tim.tv_usec / 1000000.0;
   Seconds += (double)macrosec;
   
   return Seconds;
}
#undef T_OFFSET

/*--------------------------------------------------------------------------*/
/* Return pointer to duplicate of input string (mimics strdup()):           */
char *strclone(const char *in_str)
{
   int nchars = strlen(in_str) + 2;
   char *newstr = malloc(nchars * sizeof(*newstr));
   return strncpy(newstr, in_str, nchars);
}

/****************************************************************************/
/****************************************************************************/

/*--------------------------------------------------------------------------*/
/*    Quickly select the minimum or maximum of two integers:                */
/* inline int imin( int a, int b ) { return (a < b) ? a : b; } */
/* inline int imax( int a, int b ) { return (a > b) ? a : b; } */

/*--------------------------------------------------------------------------*/

