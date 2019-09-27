pro mk_flist,gethout,flist
; this routine reads a file written by the command
; gethead regexp fib0 > gethout
; where regexp is a regular expression eg 'dble/DBLElsc20191???.*.fits'
; so that the gethead command yields a list of DBLE filenames, each
; followed by its header's value of fib0 (either 0 or 1).
; The routine reads the gethout file into an array of strings, and
; then makes a list of the unique values of site name and file date
; string apart from the last digit of the day number
; (eg dble/DBLElsc201912).  This will normally yield ~10 filenames
; from a single day, about half with fib0=0 and half with fib0=1.
; These filenames are assembled into a string array temp(nfil,2) in which
; fib0=0 files are matched with fib0-1 files for as many pairs as exist
; in the given day.
; When all lines of input data have been processed in this way, the
; resulting temp array is written out to file flist,
; to be used as input to avg_dbl2trip_1.pro

openr,iun,gethout,/get_lun
aa=[]
ss=''
while(not eof(iun)) do begin
  readf,iun,ss
  aa=[aa,strtrim(ss,2)]
endwhile
close,iun
free_lun,iun
nline=n_elements(aa)

; get length of filenames, fib0 values
aas=strarr(nline)
aav=strarr(nline)
nc=strlen(aa(0))       ; we'll assume all input lines are same length
fib0=intarr(nline)
for i=0,nline-1 do begin
  fib0(i)=fix(strmid(aa(i),nc-1,1))
  aas(i)=strmid(aa(i),0,nc-13)
  aav(i)=strmid(aa(i),0,nc-2)
endfor

; identify and list the unique site/date combinations
so=sort(aas)
aas=aas(so)
aav=aav(so)
fib0=fib0(so)
su=uniq(aas)
au=aas(su)
nunique=n_elements(su)

aout=[]
; loop over the unique site/dates
for i=0,nunique-1 do begin
  ag=where(aas eq au(i),nag)
  fib0g=fib0(ag)
  s0=where(fib0g eq 0,ns0)
  s1=where(fib0g eq 1,ns1)
  nout=ns0 < ns1            ; number of output lines for this date
  aat=strarr(2,nout)
  aat(0,*)=aav[ag(s0(0:nout-1))]
  aat(1,*)=aav[ag(s1(0:nout-1))]
  aat=reform(aat,2*nout)
; aamerge=strarr(nout,2)
; for j=0,nout-1 do begin
;   aamerge(j,0)=aat(j,0)+' '+aat(j,1)
;   aamerge(j,1)=aat
; endfor
  aout=[aout,aat]
endfor

stop

; write out the result
na=n_elements(aout)
openw,iuno,flist,/get_lun
for i=0,na-1 do begin
  printf,iuno,aout(i)
endfor
close,iuno
free_lun,iuno

end
