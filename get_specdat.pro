pro get_specdat,mjd,err
; This routine reads the spectrograph.csv file from the csv directory
; and returns the properties
; of the spectrograph for the site appearing in nres_common, and for 
; the MJD that is the most recent relative to the input parm mjd.
; Results are placed in common structure specdat.

compile_opt hidden

@nres_comm

err=0
radian=180.d0/!pi

; read the csv file
nresroot=getenv('NRESROOT')
filin=nresrooti+'/reduced/csv/spectrographs.csv'
dats=read_csv(filin,header=spechdr)

; find data for correct site
sites=strupcase(strtrim(dats.field01,2))
s=where(sites eq strupcase(strtrim(site,2)),ns)
if(ns le 0) then begin
  print,'Spectrograph data not found for site = ',site
  err=1
  goto,fini
endif

; choose most recent entry
mjds=dats.field02
mjds=mjds(s)                  ; only for desired site
diff=mjd-mjds                 ; age of each entry
md=min(diff,ix)
ss=s(ix)                      ; index of desired line in csv file
ss=ss(0)

; build the coefs array
coefs=[dats.field25(ss),dats.field26(ss),dats.field27(ss),dats.field28(ss),$
       dats.field29(ss),dats.field30(ss),dats.field31(ss),dats.field32(ss),$
       dats.field33(ss),dats.field34(ss),dats.field35(ss),dats.field36(ss),$
       dats.field37(ss),dats.field38(ss),dats.field39(ss)]
ncoefs=15

; read fibcoefs array
fibcoefs=[[dats.field40(ss),dats.field41(ss),dats.field42(ss),dats.field43(ss),$
           dats.field44(ss),dats.field45(ss),dats.field46(ss),dats.field47(ss),$
           dats.field48(ss),dats.field49(ss)],$
          [dats.field50(ss),dats.field51(ss),dats.field52(ss),dats.field53(ss),$
           dats.field54(ss),dats.field55(ss),dats.field56(ss),dats.field57(ss),$
           dats.field58(ss),dats.field59(ss)]]
 
; make sinalp, for consistency with what we need in thar_amoeba2
grinc=dats.field05(ss)
sinalp=sin(grinc/radian)

; copy info into specdat structure
specdat={site:dats.field01(ss),mjd:dats.field02(ss),ord0:dats.field03(ss),$
  grspc:dats.field04(ss),grinc:dats.field05(ss),dgrinc:dats.field06(ss),$
  fl:dats.field07(ss),dfl:dats.field08(ss),y0:dats.field09(ss),$
  dy0:dats.field10(ss),z0:dats.field11(ss),dz0:dats.field12(ss),$
  gltype:dats.field13(ss),apex:dats.field14(ss),lamcen:dats.field15(ss),$
  rot:dats.field16(ss),pixsiz:dats.field17(ss),nx:dats.field18(ss),$
  nord:dats.field19(ss),nblock:dats.field20(ss),nfib:dats.field21(ss),$
  npoly:dats.field22(ss),ordwid:dats.field23(ss),medboxsz:dats.field24(ss),$
  sinalp:sinalp,coefs:coefs,ncoefs:ncoefs,fibcoefs:fibcoefs}

fini:

end
