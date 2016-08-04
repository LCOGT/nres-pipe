pro targs_write,names,ras,decs,vmags,bmags,gmags,rmags,imags,jmags,kmags,$
      pmras,pmdecs,plaxs,rvs,teffs,logg,zeros
; Writes the vectors in the calling sequence to NRES file targets.csv,
; overwriting whatever was there.  No warnings are issued.

nresroot=getenv('NRESROOT')
targfile=nresroot+'reduced/csv/targets.csv'
hdrs=['Targname','RA','Dec','Vmag','Bmag','gmag','rmag','imag','Jmag','Kmag',$
      'PMRA','PMDE','Plax','RV','Teff','Logg','ZERO']
nline=n_elements(names)

dat={f1:names,f2:ras,f3:decs,f4:vmags,f5:bmags,f6:gmags,f7:rmags,$
     f8:imags,f9:jmags,f10:kmags,f11:pmras,f12:pmdecs,f13:plaxs,$
     f14:rvs,f15:teffs,f16:loggs,f17:zeros}

write_csv,stdfile,dat,header=hdrs

end
