/****************************************************************************/
/*                                                                          */
/*    Function prototypes for simplified FITS image I/O.                    */
/*                                                                          */
/* Rob Siverd                                                               */
/* Created:       2010-06-25                                                */
/* Last modified: 2013-04-18                                                */
/*                                                                          */
/****************************************************************************/
/****************************************************************************/
/*--------------------------------------------------------------------------*/

#include "imageIO.h"

/*--------------------------------------------------------------------------*/
/* Basic image arithmetic:                                                  */
void img_add_val(ezImg *img, DTYPE val);           /*  img += val           */
void img_sub_val(ezImg *img, DTYPE val);           /*  img -= val           */
void img_mul_val(ezImg *img, DTYPE val);           /*  img *= val           */
void img_div_val(ezImg *img, DTYPE val);           /*  img /= val           */

/*--------------------------------------------------------------------------*/
/* More advanced image arithmetic:                                          */
void img_pix_inv(ezImg *img);                      /*  img = 1.0 / img      */
void    img_sqrt(ezImg *img);                      /*  img = sqrt(img)      */
void    img_lg10(ezImg *img);                      /*  img = log10(img)     */
void    img_nlog(ezImg *img);                      /*  img = ln(img)        */
void    img_powr(ezImg *img, DTYPE val);           /*  img = pow(img, val)  */

/*--------------------------------------------------------------------------*/
/* Basic two-image arithmetic:                                              */
void img_add_img(ezImg *img1, ezImg *img2);        /*  img1 += img2         */
void img_sub_img(ezImg *img1, ezImg *img2);        /*  img1 -= img2         */
void img_mul_img(ezImg *img1, ezImg *img2);        /*  img1 *= img2         */
void img_div_img(ezImg *img1, ezImg *img2);        /*  img1 /= img2         */

