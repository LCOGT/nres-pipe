pro plexp,nback
; This routine displays the most recent fits.fz file in the exposure meter
; image directory on Rob's /scratch/rsiverd/... directory.
; If input parameter nback is given, it takes the nback-th most recent file.

; constants
expdir='/scratch/rsiverd/atik_data/cradle_expmeter'

; change to data directory, do an ls
cd,expdir
cmd='ls -t *.fits.fz'
spawn,cmd,list

np=n_params()
if(np eq 1) then nb=nback else nb=0
if(nb ge 0) then fstr=strtrim(list(nb),2)
if(nb lt 0) then fstr='*.fits.fz'

;cmd=['pwd']
;spawn,cmd
print,fstr
cmd='/Applications/DS9.app/Contents/MacOS/ds9 '+fstr
spawn,cmd

end
