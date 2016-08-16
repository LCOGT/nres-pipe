pro zeros_write,fnames,navgs,sites,cameras,jdates,targnames,teffs,loggs,$
    bmvs,jmks,flags
; Writes the vectors in the calling sequence to NRES file zeros.csv,
; overwriting whatever was there.  No warnings are issued.

nresroot=getenv('NRESROOT')
zerofile=nresroot+'reduced/csv/zeros.csv'
hdrs=['Filename','Navg','Site','Camera','JDdata','Targname','Teff','logg','B-V','J-K','Flags']
nline=n_elements(fnames)

dat={f1:fnames,f2:navgs,f3:sites,f4:cameras,f5:jdates,f6:targnames,f7:teffs,$
     f8:loggs,f9:bmvs,f10:jmks,f11:flags}

write_csv,zerofile,dat,header=hdrs

end
