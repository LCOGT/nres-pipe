/****************************************************************************/
/*                                                                          */
/*    Miscellaneous header modification routines.                           */
/*                                                                          */
/* Rob Siverd                                                               */
/* Created:       2013-04-07                                                */
/* Last modified: 2013-04-17                                                */
/*                                                                          */
/****************************************************************************/
/****************************************************************************/
/*--------------------------------------------------------------------------*/

/* Define ezImg structure: */
#include "imageIO.h"

/****************************************************************************/

/* Copy all header cards to new image. Optionally adjust header size:       */
int cpy_all_hdr(  ezImg *src,               /*  source image data structure */
                  ezImg *dst,               /*  target image data structure */
                    int  hdr_mode,          /* controls meaning of new_keys */
                    int  new_keys  );       /*   number of keys to add/have */

/*--------------------------------------------------------------------------*/
/* Remove the specified header card image:                                  */
int delete_hcard ( ezImg *image,        /* structure with image and headers */
                    char *keyword,      /* name of header keyword to remove */
                     int  silent   );   /* disables missing keyword warning */

/*--------------------------------------------------------------------------*/
/* FITS header manipulation: */
int add_hdr_comment(ezImg *, char *);  /* add comment string to FITS header */
int extend_header(ezImg *, int size);  /* extend header length (adds space) */
int set_new_hsize(ezImg *, int size);  /* set header length to chosen size  */

/* Specialized keywords: */
int add_hist_card(ezImg *, char *);    /* adds history card to image header */
int add_date_card(ezImg *);            /* adds creation date+time to header */


/****************************************************************************/
/***********************   arbitrary additions:   ***************************/
/****************************************************************************/

/*--------------------------------------------------------------------------*/
/*    Add a new header card to the specified FITS image header.             */
int add_hdr_key (  ezImg *img,       /* structure with pointer to FITS file */
                     int  type,      /* data type for new FITS keyword      */
                    char *keyName,   /*       name of new FITS keyword      */
                    void *keyVal,    /*     pointer to new keyword value    */
                    char *comment ); /*  optional header key comment string */

/*--------------------------------------------------------------------------*/
/*    Update or write the given keyword in the specified FITS image header. */
int upd_hdr_key (  ezImg *img,       /* structure with pointer to FITS file */
                     int  type,      /* CFITSIO type for new FITS keyword   */
                    char *keyName,   /*       name of new FITS keyword      */
                    void *keyVal,    /*     pointer to new keyword value    */
                    char *comment ); /*  optional header key comment string */

