pro mk_spectrograph,site,filin
; This routine reads the TRIPLE file identified in filin, which should be a
; string of the form '/trip/TRIPLEyyyyddd.fffff.fits'.  It massages data
; describing the spectrograph configuration from the fits header, and writes
; a corresponding new line into csv/spectrographs.csv 

; constants
radian=180.d0/!pi
nresroot=getenv('NRESROOT')
nresinst=getenv('NRESINST')
nresrooti=nresroot+nresinst
trippath=nresrooti+'reduced/'+filin
csvpath=nresrooti+'reduced/csv/spectrographs.csv'
siteo=strtrim(strlowcase(site))

; get the data mjd, for a time tag on the new spectrographs.csv line
;jdc=systime(/julian)
;mjdc=jdc-2450000.5d0

; read the data
dd=readfits(trippath,hdr)

; extract the needed info
mjdd=sxpar(hdr,'MJD-OBS')
ord0=sxpar(hdr,'ORD0')
grspc=sxpar(hdr,'GRSPC')
sinalp=sxpar(hdr,'SINALP')
grinc=radian*asin(sinalp)
dsinalp=sxpar(hdr,'DSINALP')
dgrinc=radian*asin(dsinalp)
fl=sxpar(hdr,'FL')
dfl=sxpar(hdr,'DFL')
y0=sxpar(hdr,'Y0')
dy0=sxpar(hdr,'DY0')
z0=sxpar(hdr,'Z0')
dz0=sxpar(hdr,'DZO')
glass=sxpar(hdr,'GLASS')
apex=sxpar(hdr,'APEX')
lamcen=sxpar(hdr,'LAMCEN')
rot=sxpar(hdr,'ROT')
pixsiz=sxpar(hdr,'PIXSIZ')
nx=sxpar(hdr,'NX')
nord=sxpar(hdr,'NORD')
nblock=sxpar(hdr,'NBLOCK')
nfib=sxpar(hdr,'NFIB')
npoly=sxpar(hdr,'NPOLY')
ordwid=sxpar(hdr,'ORDWID')
medboxsz=sxpar(hdr,'MEDBOXSZ')
ncoefs=sxpar(hdr,'NCOEFS')

coefs00=sxpar(hdr,'COEFS00')
coefs01=sxpar(hdr,'COEFS01')
coefs02=sxpar(hdr,'COEFS02')
coefs03=sxpar(hdr,'COEFS03')
coefs04=sxpar(hdr,'COEFS04')
coefs05=sxpar(hdr,'COEFS05')
coefs06=sxpar(hdr,'COEFS06')
coefs07=sxpar(hdr,'COEFS07')
coefs08=sxpar(hdr,'COEFS08')
coefs09=sxpar(hdr,'COEFS09')
coefs10=sxpar(hdr,'COEFS10')
coefs11=sxpar(hdr,'COEFS11')
coefs12=sxpar(hdr,'COEFS12')
coefs13=sxpar(hdr,'COEFS13')
coefs14=sxpar(hdr,'COEFS14')

fibcoe00=sxpar(hdr,'FIBCOE00')
fibcoe10=sxpar(hdr,'FIBCOE10')
fibcoe20=sxpar(hdr,'FIBCOE20')
fibcoe30=sxpar(hdr,'FIBCOE30')
fibcoe40=sxpar(hdr,'FIBCOE40')
fibcoe50=sxpar(hdr,'FIBCOE50')
fibcoe60=sxpar(hdr,'FIBCOE60')
fibcoe70=sxpar(hdr,'FIBCOE70')
fibcoe80=sxpar(hdr,'FIBCOE80')
fibcoe90=sxpar(hdr,'FIBCOE90')
fibcoe01=sxpar(hdr,'FIBCOE01')
fibcoe11=sxpar(hdr,'FIBCOE11')
fibcoe21=sxpar(hdr,'FIBCOE21')
fibcoe31=sxpar(hdr,'FIBCOE31')
fibcoe41=sxpar(hdr,'FIBCOE41')
fibcoe51=sxpar(hdr,'FIBCOE51')
fibcoe61=sxpar(hdr,'FIBCOE61')
fibcoe71=sxpar(hdr,'FIBCOE71')
fibcoe81=sxpar(hdr,'FIBCOE81')
fibcoe91=sxpar(hdr,'FIBCOE90')

; Get the spectrographs.csv file
dats=read_csv(csvpath,header=spechdr)

stop

; merge in the new data
datso={field01:[dats.field01,siteo],$
field02:[dats.field02,mjdd],$
field03:[dats.field03,ord0],$
field04:[dats.field04,grspc],$
field05:[dats.field05,grinc],$
field06:[dats.field06,dgrinc],$
field07:[dats.field07,fl],$
field08:[dats.field08,dfl],$
field09:[dats.field09,y0],$
field10:[dats.field10,dy0],$
field11:[dats.field11,z0],$
field12:[dats.field12,dz0],$
field13:[dats.field13,glass],$
field14:[dats.field14,apex],$
field15:[dats.field15,lamcen],$
field16:[dats.field16,rot],$
field17:[dats.field17,pixsiz],$
field18:[dats.field18,nx],$
field19:[dats.field19,nord],$
field20:[dats.field20,nblock],$
field21:[dats.field21,nfib],$
field22:[dats.field22,npoly],$
field23:[dats.field23,ordwid],$
field24:[dats.field24,medboxsz],$

field25:[dats.field25,coefs00],$
field26:[dats.field26,coefs01],$
field27:[dats.field27,coefs02],$
field28:[dats.field28,coefs03],$
field29:[dats.field29,coefs04],$
field30:[dats.field30,coefs05],$
field31:[dats.field31,coefs06],$
field32:[dats.field32,coefs07],$
field33:[dats.field33,coefs08],$
field34:[dats.field34,coefs09],$
field35:[dats.field35,coefs10],$
field36:[dats.field36,coefs11],$
field37:[dats.field37,coefs12],$
field38:[dats.field38,coefs13],$
field39:[dats.field39,coefs14],$

field40:[dats.field40,fibcoe00],$
field41:[dats.field41,fibcoe10],$
field42:[dats.field42,fibcoe20],$
field43:[dats.field43,fibcoe30],$
field44:[dats.field44,fibcoe40],$
field45:[dats.field45,fibcoe50],$
field46:[dats.field46,fibcoe60],$
field47:[dats.field47,fibcoe70],$
field48:[dats.field48,fibcoe80],$
field49:[dats.field49,fibcoe90],$
field50:[dats.field50,fibcoe01],$
field51:[dats.field51,fibcoe11],$
field52:[dats.field52,fibcoe21],$
field53:[dats.field53,fibcoe31],$
field54:[dats.field54,fibcoe41],$
field55:[dats.field55,fibcoe51],$
field56:[dats.field56,fibcoe61],$
field57:[dats.field57,fibcoe71],$
field58:[dats.field58,fibcoe81],$
field59:[dats.field59,fibcoe91]}

; write everything out
write_csv,csvpath,datso,header=spechdr

end


