pro old_red_compare,za,filout
; This routine compares the wavelengths of lines listed in the old ThAr list
; with those from the Redman list.
; Technique is to search Redman for lines falling within thrsh of each old
; line, choose the nearest as a match, and plot dlambda vs lambda for matches.
; After plotting, the routine selects from the matched lines all those with
; differences |old - Redman| less than tight_thrsh, and writes the Redman
; vacuum wavelengths for these lines as an ascii file to filout.

; constants
thrsh=0.3                 ; match tolerance (AA)
tight_thrsh=0.005         ; tight match tolerance (AA)
nresroot=getenv('NRESROOT')
nresrooti=nresroot+getenv('NRESINST')

oldlines=nresrooti+'reduced/config/arc_ThAr0.txt'

; read the old list
openr,iun,oldlines,/get_lun
ss=''
v1=0.d0
readf,iun,ss
readf,iun,ss
lamolda=dblarr(3605)
for i=0,3604 do begin
  readf,iun,v1
  lamolda(i)=v1
endfor
close,iun
free_lun,iun
nold=n_elements(lamolda)

; make a version transformed to vacuum wavelengths in AA
lamoldv=vaclam(lamolda/1000.,za)*1.e4
lamolda=lamolda*10.

; read the Redman list, complete
rd_redman_thar_table6,redlam,lamerr,bright
nred=n_elements(redlam)

goto,skip

; match lines from old (air) list to Redman
imatch=[0L]              ; line indices in old list that have a match in Redman
jmatch=[0L]              ; line indices in Redman matching lines in old list
lammatch=[0.d0]          ; lambda of matching lines in old list
lamdif=[0.0]             ; difference lam(old)-lam(red)

for i=0,nold-1 do begin
  dif=redlam-lamolda(i)
  md=min(abs(dif),ix)
  if(md le thrsh) then begin
    imatch=[imatch,i]
    jmatch=[jmatch,ix]
    lammatch=[lammatch,lamolda(i)]
    lamdif=[lamdif,dif(ix)]
  endif
endfor

; plot results
plot,lammatch(1:*),lamdif(1:*),psym=1,xtit=xtit,ytit=ytit,/xsty,charsiz=1.5,$
  yran=[-.0003,.0003]

ss=''
read,ss

skip:

; match lines from old (vacuum) list to Redman
; match lines from old (air) list to Redman
imatch=[0L]              ; line indices in old list that have a match in Redman
jmatch=[0L]              ; line indices in Redman matching lines in old list
lammatch=[0.d0]          ; lambda of matching lines in old list
lamdif=[0.0]             ; difference lam(old)-lam(red)

for i=0,nold-1 do begin
  dif=redlam-lamoldv(i)
  md=min(abs(dif),ix)
  if(md le thrsh) then begin
    imatch=[imatch,i]
    jmatch=[jmatch,ix]
    lammatch=[lammatch,lamoldv(i)]
    lamdif=[lamdif,dif(ix)]
  endif
endfor

; plot results
xtit='lambda (AA)'
ytit='Diff (AA)'
plot,lammatch(1:*),lamdif(1:*),psym=3,xtit=xtit,ytit=ytit,/xsty,charsiz=1.5,$
   yran=[-.003,.003]

; write Redman wavelengths for lines with tight matches to output file
lammatch=lammatch(1:*)
lamdif=lamdif(1:*)
jmatch=jmatch(1:*)
st=where(abs(lamdif) le tight_thrsh,nst)
if(nst gt 0) then begin
  openw,iun,nresrooti+'reduced/config/'+filout,/get_lun
  printf,iun,'Selected Redman 2013 ThAr lines.  Vacuum lam from energy levels.'
  printf,iun,'lambda(nm)    Bright  dlambda(nm)'
  for i=0,nst-1 do begin
    printf,iun,redlam(jmatch(st(i)))/10.,bright(jmatch(st(i))),$
      lamerr(jmatch(st(i)))/10.,$
     format='(f12.7,2x,f6.0,2x,f9.7)'
  endfor
  close,iun
  free_lun,iun
endif
  
;stop

end
