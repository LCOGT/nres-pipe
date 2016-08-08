/*
These are wrapper functions that will be called by IDL to interface to
the corresponding CUDA routines. These must be compiled, along with
the original routines, into a shared library called
$EXOFAST_PATH/cuda/exofast.so. An NVIDIA GeForce GTX 295 or better
graphics card is recommended (required?).

These have only been tested on a 64-bit Ubuntu machine with an NVIDIA
GeForce GTX 295 graphics card.
*/

extern "C" {
  #include <stdio.h>
  #include "idl_export.h"
  
  double keplereq_cuda(int argc, void *argv[]) {
    keplereq_wrapper_c((double *) argv[0], (double *) argv[1], 
		       (IDL_LONG64) argv[2], (double *) argv[3]);  
    return -1; 
  }
  
  double occultquad_cuda(int argc, void *argv[]) {
    occultquad_wrapper_c((double *) argv[0], (double *) argv[1], 
			 (IDL_LONG64) argv[2], (double *) argv[3]);  
    return -1; 
  }
}

