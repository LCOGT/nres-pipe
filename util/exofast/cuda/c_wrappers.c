#include <stdio.h>
#include "idl_export.h"		/* IDL external definitions */

void keplereq_wrapper_c(double *, double *, int, double *);

void keplereq_cuda(int argc, void *argv[])
{
  keplereq_wrapper_c((double *) argv[0], (double *) argv[1], 
		     (IDL_LONG) argv[2], (double *) argv[3]);   
  return;
}
