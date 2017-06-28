/****************************************************************************/
/*                                                                          */
/*    Functions to perform the required image arithmetic.                   */
/*                                                                          */
/* Rob Siverd                                                               */
/* Created:       2010-06-21                                                */
/* Last modified: 2014-02-04                                                */
/*                                                                          */
/****************************************************************************/
/****************************************************************************/
/*--------------------------------------------------------------------------*/

#include      <math.h>
#include    <stdlib.h>
//#include "img_arith.h"
#include   "imageIO.h"

///* Extra includes for OpenMP (multi-threading): */
//#ifdef _OPENMP
//   #include    <omp.h>
//#endif
//
//#define OMP_SCHED schedule(guided)

/*--------------------------------------------------------------------------*/
/* Add floating-point value to every pixel:                                 */
void img_add_val(ezImg *img, DTYPE value) 
{
   long i;
//#ifdef _OPENMP
//   #pragma omp parallel for private(i) OMP_SCHED
//#endif
   for ( i = 0; i < img->NumPix; i++ ) (img->pix1D)[i] += value;
   return;
}

/*--------------------------------------------------------------------------*/
/* Subtract floating-point value from every pixel:                          */
void img_sub_val(ezImg *img, DTYPE value) 
{
   long i; 
//#ifdef _OPENMP
//   #pragma omp parallel for private(i) OMP_SCHED
//#endif
   for ( i = 0; i < img->NumPix; i++ ) { (img->pix1D)[i] -= value; }
   return;
}

/*--------------------------------------------------------------------------*/
/* Multiply each pixel by float-point value:                                */
void img_mul_val(ezImg *img, DTYPE value) 
{
   long i; 
//#ifdef _OPENMP
//   #pragma omp parallel for private(i) OMP_SCHED
//#endif
   for ( i = 0; i < img->NumPix; i++ ) (img->pix1D)[i] *= value;
   return;
}

/*--------------------------------------------------------------------------*/
/* Divide each pixel by floating-point value:                               */
void img_div_val(ezImg *img, DTYPE value) 
{
   long i; 
//#ifdef _OPENMP
//   #pragma omp parallel for private(i) OMP_SCHED
//#endif
   for ( i = 0; i < img->NumPix; i++ ) (img->pix1D)[i] /= value;
   return;
}

/****************************************************************************/
/****************************************************************************/

/*--------------------------------------------------------------------------*/
/* Add values from another image:                                           */
void img_add_img(ezImg *img1, ezImg *img2) 
{
   long i;
//#ifdef _OPENMP
//   #pragma omp parallel for private(i) OMP_SCHED
//#endif
   for ( i = 0; i < img1->NumPix; i++ ) {
      (img1->pix1D)[i] += (img2->pix1D)[i];
   }
   return;
}

/*--------------------------------------------------------------------------*/
/* Subtract an image (img1 -= img2):                                        */
void img_sub_img(ezImg *img1, ezImg *img2) 
{
   long i;
//#ifdef _OPENMP
//   #pragma omp parallel for private(i) OMP_SCHED
//#endif
   for ( i = 0; i < img1->NumPix; i++ ) {
      (img1->pix1D)[i] -= (img2->pix1D)[i];
   }
   return;
}

/*--------------------------------------------------------------------------*/
/* Multiply by values from another image:                                   */
void img_mul_img(ezImg * img1, ezImg * img2) 
{
   long i;
 //DTYPE * __restrict__ vec1 = img1->pix1D;
 //DTYPE * __restrict__ vec2 = img2->pix1D;
//#ifdef _OPENMP
//   #pragma omp parallel for private(i) OMP_SCHED
//#endif
   for ( i = 0; i < img1->NumPix; i++ ) {
      (img1->pix1D)[i] *= (img2->pix1D)[i];
    //vec1[i] *= vec2[i];
   }
   return;
}

/*--------------------------------------------------------------------------*/
/* Divide by values from another image:                                     */
void img_div_img(ezImg *img1, ezImg *img2) 
{
   long i;
//#ifdef _OPENMP
//   #pragma omp parallel for private(i) OMP_SCHED
//#endif
   for ( i = 0; i < img1->NumPix; i++ ) {
      (img1->pix1D)[i] /= (img2->pix1D)[i];
   }
   return;
}


/****************************************************************************/
/****************************************************************************/

/*--------------------------------------------------------------------------*/
/* Invert (^-1) pixel values in image:                                      */
void img_pix_inv(ezImg *img)
{
   long i;
//#ifdef _OPENMP
//   #pragma omp parallel for private(i) OMP_SCHED
//#endif
   for ( i = 0; i < img->NumPix; i++ ) {
      (img->pix1D)[i] = (DTYPE)1.0 / (img->pix1D)[i];
   }
   return;
}

/*--------------------------------------------------------------------------*/
/* Take base-10 log of pixel values:                                        */
void img_lg10(ezImg *img)
{
   long i;
//#ifdef _OPENMP
//   #pragma omp parallel for private(i) OMP_SCHED
//#endif
   for ( i = 0; i < img->NumPix; i++ ) {
      (img->pix1D)[i] = (DTYPE)log10( (img->pix1D)[i] );
   }
   return;
}

/*--------------------------------------------------------------------------*/
/* Take natural log of pixel values:                                        */
void img_nlog(ezImg *img)
{
   long i;
//#ifdef _OPENMP
//   #pragma omp parallel for private(i) OMP_SCHED
//#endif
   for ( i = 0; i < img->NumPix; i++ ) {
      (img->pix1D)[i] = (DTYPE)log( (img->pix1D)[i] );
   }
   return;
}

/*--------------------------------------------------------------------------*/
/* Take square-root of pixel values:                                        */
void img_sqrt(ezImg *img)
{
   long i;
   //const long nPix = img->NumPix;
   //DTYPE * restrict pixels = img->pix1D;
//#ifdef _OPENMP
//   #pragma omp parallel for private(i) OMP_SCHED
//#endif
   for ( i = 0; i < img->NumPix; i++ ) {
      //pixels[i] = sqrt( pixels[i] );
      (img->pix1D)[i] = sqrt( (img->pix1D)[i] );
   }
   return;
}

/*--------------------------------------------------------------------------*/
/* Raise pixel values to specified power:                                   */
void img_powr(ezImg *img, DTYPE value)
{
   long i;
//#ifdef _OPENMP
//   #pragma omp parallel for private(i) OMP_SCHED
//#endif
   for ( i = 0; i < img->NumPix; i++ ) {
      (img->pix1D)[i] = (DTYPE)pow( (img->pix1D)[i], value );
   }
   return;
}

/****************************************************************************/
/****************************************************************************/

