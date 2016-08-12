pro gethead,path,keyword,value,flist
; This routine searches the given path string (which may contain wildcards)
; for fits files in which keyword = value.
; Matches are returned in flist.
; All of the distinguishing features of the desired filenames should be
; included in the 'path' argument (e.g. '*.fits')

u=findfile(path,count=nf)
flist=['']
nn=0
val=strtrim(strlowcase(value),2)
if(nf gt 0) then begin
  for i=0,nf-1 do begin
    dd=readfits(u(i),hdr)
    v=sxpar(hdr,keyword)
    print,v
    if(strtrim(strlowcase(v),2) eq val) then begin
      flist=[flist,u(i)]
      nn=nn+1
    endif
  endfor
endif


stop

if(nn gt 0) then begin
  flist=flist(1:*)
endif

end
