pro nres_copy,dirname
; This routine makes a copy of a 'bare' nres directory structure, with
; no data except for the essential files that must be migrated to a new
; instance of the IDL reduction code, plus a minimal set of labcam data
; and the reduction products of these data.  The new directory is placed in
; a subdirectory of the CWD, named dirname.

nresroot=getenv('NRESROOT')
nresrooti=nresroot+getenv('NRESINST')

tdn=strtrim(dirname,2)

; make the directory structure
cmd='mkdir '+tdn
spawn,cmd
subdirs=['code','reduced','rawdat']
nd=n_elements(subdirs)
for i=0,nd-1 do begin
  cmd='mkdir '+tdn+'/'+strtrim(subdirs(i),2)
  spawn,cmd
endfor

reddirs=['autog','bias','ccor','class','config','csv','dark','diag',$
         'expm','flat','rv','spec','thar','trace','trip','zero']
nd=n_elements(reddirs)
for i=0,nd-1 do begin
  cmd='mkdir '+tdn+'/reduced/'+strtrim(reddirs(i),2)
  spawn,cmd
end 

; copy contents
cmd='cp '+nresroot+'*.txt '+tdn
;stop
spawn,cmd
cmd='cp -r '+nresroot+'code/* '+tdn+'/code'
spawn,cmd
cmd='cp '+nresrooti+'reduced/config/*.txt '+tdn+'/reduced/config'
spawn,cmd
;cmd='cp '+nresrooti+'reduced/csv/template*.txt '+tdn+'/reduced/csv'
;spawn,cmd
cmd='cp '+nresrooti+'reduced/csv/targets.csv '+tdn+'/reduced/csv'
spawn,cmd
cmd='cp '+nresrooti+'reduced/csv/zeros.csv '+tdn+'/reduced/csv'
spawn,cmd
cmd='cp '+nresrooti+'reduced/csv/spectrographs.csv '+tdn+'/reduced/csv'
spawn,cmd
cmd='cp '+nresrooti+'reduced/csv/ccds.csv '+tdn+'/reduced/csv'
spawn,cmd
cmd='cp '+nresrooti+'reduced/csv/rv.csv '+tdn+'/reduced/csv'
spawn,cmd

goto,skip

cmd='cp '+nresrooti+'reduced/trip/* '+tdn+'/reduced/trip'
spawn,cmd
cmd='cp '+nresrooti+'reduced/bias/* '+tdn+'/reduced/bias'
spawn,cmd
cmd='cp '+nresrooti+'reduced/dark/* '+tdn+'/reduced/dark'
spawn,cmd
cmd='cp '+nresrooti+'reduced/dble/* '+tdn+'/reduced/dble'
spawn,cmd
cmd='cp '+nresrooti+'reduced/flat/* '+tdn+'/reduced/flat'
spawn,cmd
cmd='cp '+nresrooti+'reduced/spec/* '+tdn+'/reduced/spec'
spawn,cmd
cmd='cp '+nresrooti+'reduced/thar/* '+tdn+'/reduced/thar'
spawn,cmd
cmd='cp '+nresrooti+'reduced/trace/* '+tdn+'/reduced/trace'
spawn,cmd
cmd='cp '+nresrooti+'reduced/trip/* '+tdn+'/reduced/trip'
spawn,cmd
cmd='cp '+nresrooti+'reduced/zero/* '+tdn+'/reduced/zero'
spawn,cmd
cmd='cp '+nresrooti+'rawdat/labcam-fl01-20160228*.fits '+tdn+'/rawdat'
spawn,cmd

skip:

; make a gzipped tarball of this stuff
cmd='tar -cvzf nres_copy.gz '+tdn
spawn,cmd

end 
