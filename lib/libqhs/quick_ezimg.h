/*--------------------------------------------------------------------------*/
/* Initialize an ezImg structure with useful (wrong) default values:        */
int init_ezImg(ezImg *img)    /* ezImg structure stores data and attributes */
{
   img->BitPix = 0;
   img->naxis  = 0;
   img->NumPix = 0;
 //img->naxes[0] = 0;
 //img->naxes[1] = 0;
   for ( int i = 0; i < MAXDIM; i++ ) img->naxes[i] = 0;
   for ( int i = 0; i < MAXDIM; i++ ) img->pstep[i] = 0;
   img->pix1D  = NULL;
   img->pix2D  = NULL;
   img->fptr   = NULL;
   img->FType  = 0;
   img->fname  = NULL;
   img->fmode  = 0;      /* file access mode (READONLY or READWRITE) */
   img->eqType = 0;      /* equivalent image type */
   img->nKeys  = 0;      /* number of header keywords */

   return 0; /* success */
}

/*--------------------------------------------------------------------------*/
/* Print basic image attributes (e.g., size, shape, & BITPIX) to screen:    */
void print_size( ezImg *img,       /* ezImg structure to store attributes   */
                  FILE *dest )     /* where to print image attributes       */
{
   fprintf(dest,
         "\n"
         "  ----------------------\n"
         "  |  BITPIX:   %6ld  |\n"
         "  |  NAXIS:    %6ld  |\n",
         (long)img->BitPix, (long)img->naxis);

   for ( int i = 0; i < img->naxis; i++ ) {
      fprintf(dest,
         "  |  NAXIS%d:   %6ld  |\n",
         i + 1, img->naxes[i]);
   }

   fprintf(dest,
         "  ----------------------\n"
         "\n");
   return;
}

