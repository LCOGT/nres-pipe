pro test_lam3
; this routine is a tester for lambda3_setup.pro

@nres_comm
@thar_comm

nresroot=getenv('NRESROOT')
nresrooti=nresroot+getenv('NRESINST')
site='lsc'
radian=180./!pi
mjdd=58655.d0           ; 21 June 2019

ncx=5
nco=5

get_specdat,mjdd,err
mm_c=specdat.ord0 + lindgen(specdat.nord)      ; diffraction orders
grspc_c=specdat.grspc                  ; grating groove spacing (mm)
grinc_c=specdat.grinc                  ; grating incidence angle
sinalp_c=sin(specdat.grinc/radian)     ; sin nominal incidence angle
fl_c=specdat.fl                        ; camera nominal fl (mm)
y0_c=specdat.y0                        ; y posn at which gamma=0 (mm)
z0_c=specdat.z0                        ; (n-1) of air in SG (no units)
gltype_c=specdat.gltype                ; cross-disperser glass type (eg 'BK7')
apex_c=specdat.apex                      ; cross-disp prism apex angle (degree)
lamcen_c=specdat.lamcen                ; nominal wavelen at FOV center (micron)
rot_c=specdat.rot                      ; detector rotation angle (degree)
pixsiz_c=specdat.pixsiz                ; detector pixel size (mm)
nx_c=specdat.nx                        ; no of detector columns
nord_c=specdat.nord                    ; no of spectrum orders
dsinalp_c=abs(sin((specdat.grinc+specdat.dgrinc)/radian)-sinalp_c)
dfl_c=specdat.dfl
dy0_c=specdat.dy0
dz0_c=specdat.dz0
coefs_c=specdat.coefs
ncoefs_c=specdat.ncoefs
fibcoefs_c=specdat.fibcoefs

xx=pixsiz_c*(findgen(nx_c)-float(nx_c/2.))
mm=mm_c
fibno=1
lambda3ofx,xx,mm,fibno,specdat,lam_c,y0m_c   ; vacuum wavelengths

stop

lambda3_setup,xx,mm,specdat,pref,ncx,nco,coefx,coefo,residx,resido,y0m

stop

end
