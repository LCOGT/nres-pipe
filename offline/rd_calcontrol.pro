pro rd_calcontrol,calcontrol
; This routine reads the stage-2 calib control config file.
; Contents are returned in the calcontrol structure.

; constants
root=getenv('NRESROOT')
fname=root+'reduced/config/calcontrol.txt'

openr,iun,fname,/get_lun
ss=''
readf,iun,ss          ; header line
readf,iun,nsites      ; number of sites
readf,iun,ss          ; string with site names, blank-separated
words=get_words(ss,nwd)
sites=words(0:nsites-1)
sites=strupcase(sites)        ; insurance
readf,iun,t1
readf,iun,t2
readf,iun,t2d
readf,iun,t3
close,iun
free_lun,iun

calcontrol={nsites:nsites,sites:sites,t1:t1,t2:t2,t2d:t2d,t3:t3}

end
