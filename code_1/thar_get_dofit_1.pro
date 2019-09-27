pro thar_get_dofit_1,site,dstr,mjdw
;This routine opens the csv file $STAGE2ROOT/dofit.csv and reads from it
; the most recently-written dofit string that is associated with the given
; site.  This string is returned in dstr, and the corresponding date in mjdw.

; constants
nresroot=getenv('NRESROOT')
dffil=nresroot+'/dofit.csv'
;stage2root=getenv('STAGE2ROOT')
;dffil=stage2root+'/dofit.csv'

; open the dofit file, read it
dat=read_csv(dffil) 
mjd=dat.field1
sites=dat.field2
dof=dat.field3

; find the desired string
s=where(strtrim(sites,2) eq strtrim(site,2),ns)
if(ns gt 0) then begin
  mjdg=mjd(s)
  dofg=dof(s)
  mjdw=max(mjdg,ix)      ; find maximum write date
  dstr=dofg(ix)
endif else begin
  print,'No matching sites in thar_get_dofit_stg2!'
  dstr=''
endelse

end
