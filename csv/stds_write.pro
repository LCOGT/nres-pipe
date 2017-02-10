pro stds_write,types,fnames,navgs,sites,cameras,jdates,flags,hdrs
; Writes the vectors in the calling sequence to NRES file standards.csv,
; overwriting whatever was there.  No warnings are issued.

nresroot=getenv('NRESROOT')
nresrooti=nresroot+getenv('NRESINST')
stdfile=nresrooti+'reduced/csv/standards.csv'
hdrs=['Type','Filename','Navg','Site','Camera','JDdata','Flags']

write_csv,stdfile,types,fnames,navgs,sites,cameras,jdates,flags,header=hdrs
; this works only for max of 8 columns.  To add a column, need to embed
; the column vectors in a structure.

end
