/****************************************************************************/
/*                                                                          */
/*    Function prototypes for simplified FITS image I/O.                    */
/*                                                                          */
/* Rob Siverd                                                               */
/* Created:       2010-06-25                                                */
/* Last modified: 2015-11-27                                                */
/*                                                                          */
/****************************************************************************/
/****************************************************************************/
/*--------------------------------------------------------------------------*/

/* Include guard prevents redefinition: */
#ifndef HAVE_IMAGEIO_H

#define HAVE_IMAGEIO_H /* take note of header inclusion */

/* Shared source version: */
#define SHARED_IMAGEIO_VERSION 3.0.4

/* Memory alignment for image data: */
#define IMG_ALIGN  64

/* Need CFITSIO: */
#include  <fitsio.h>

/* Make sure DTYPE is defined: */
#ifndef DTYPE
#  warning "DTYPE not defined!  Using float ..."
#  define  DTYPE  float
#  define TDTYPE TFLOAT
#endif

/* Define TDTYPE for CFITSIO implicit conversion: */
#ifndef TDTYPE
#  error "TDTYPE not defined!!"
#endif

/*--------------------------------------------------------------------------*/

/* Track images with a structure: */
#define MAXDIM 9
typedef struct {
   int       BitPix;
   int       naxis;
   long      NumPix;
   long      naxes[MAXDIM];
   long      pstep[MAXDIM];
   DTYPE    *pix1D;
   DTYPE   **pix2D;
   fitsfile *fptr;
   int       FType;    /* BITPIX of output image */
   char     *fname;
   int       fmode;
   int       eqType;
   int       nKeys;
}  ezImg;

/*--------------------------------------------------------------------------*/
/* Header/key addition modes (for cpy_all_hdr() function):                  */

#define HDR_ADD_EXTRA 0       /* specify desired number of blank/extra keys */
#define HDR_SET_TOTAL 1       /* specify total number of output header keys */

/*--------------------------------------------------------------------------*/

/* Sanity checks (names, structures, etc.): */
void check_fits_name(char *fname);
int  name_check_fail(char *fname);
void parse_frootname(char *fname, char *rstring);
int has_bad_dims(ezImg *img);             /* check dimensional consistency */

/*--------------------------------------------------------------------------*/
/*--------------------------------------------------------------------------*/
/* Convert 1-D pixel coordinate to N-dimensions (NOT ARRAY COORDS):         */
int ezi_pixcoo_1d_to_Nd (
                       ezImg *img,       /*  in: image data structure       */
                        long  pixpos_1,  /*  in: 1-D/linear pixel position  */
                        long *pixpos_n   /* out: array with N-D coordinate  */
                        );


/*--------------------------------------------------------------------------*/
/* FITS I/O function prototypes: */
int get_img_size(ezImg *img, char *imname); /* check image dimensions */


/* Low-level CFITSIO wrappers: */
int   ez_open_FITS(ezImg *, char *, int);    /* open image, fill structure   */
int  ez_close_FITS(ezImg *img);              /* closes an open image         */
int ez_create_FITS(ezImg *, char *imname);   /* Creates a new FITS image     */
int  ezImg_is_open(ezImg *img);        /* check if ezImg open (in structure) */
int    ez_checksum(ezImg *img);               /* update CHECKSUM and DATASUM */

/* Miscellaneous ezImg-related functions: */
int   same_size(ezImg *, ezImg *);     /* checks if two ezImgs are same size */
int  init_ezImg(ezImg *img);           /* sets obviously-wrong defaults      */
int alloc_ezImg(ezImg *img);           /* allocate image memory and pointers */
int  free_ezImg(ezImg *img);           /* free image memory resources        */
int  copy_ezImg(ezImg *, ezImg *);     /* copy existing ezImg structure      */
int  copy_imgSS(ezImg *, ezImg *);     /* copy ezImg size & shape to another */
int swap_pixels(ezImg *, ezImg *);     /* swap data ptrs between two ezImgs  */
int copy_pixels(ezImg *, ezImg *);     /* copy pixel data between two ezImgs */
void print_size(ezImg *,  FILE *);     /* report basic image attributes      */
int ezi_zero_fill(ezImg *img);         /* set all pixels in structure to 0.0 */


/* Load and store image data: */
int  ez_savepix(ezImg *img);           /* write current pixel data to file   */
int  ez_loadpix(ezImg *img);           /* load complete image from file      */

#endif

