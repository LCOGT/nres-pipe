/****************************************************************************/
/*                                                                          */
/*    Quick, basic statistics for data in ezImg structures.                 */
/*                                                                          */
/* Rob Siverd                                                               */
/* Created:       2014-06-06                                                */
/* Last modified: 2014-06-06                                                */
/*                                                                          */
/****************************************************************************/
/****************************************************************************/
/*--------------------------------------------------------------------------*/

#include "imageIO.h"

/*--------------------------------------------------------------------------*/
/* Find min/max image values (NaN- and inf-safe):                           */
int ezi_find_minmax     (
                     ezImg  *image,    /*  [in] image data structure */
                    double  *pixmin,   /* [out] minimum image value  */
                    double  *pixmax    /* [out] maximum image value  */
                        );

