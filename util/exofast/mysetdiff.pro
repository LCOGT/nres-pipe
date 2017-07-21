;+
; NAME:
;   MYSETDIFF
;
; PURPOSE: 
;   Finds the difference between two sets. Similar to
;   David Fanning's SETDIFFERENCE, but preserves the order and
;   duplicates at a substantial cost in speed.
;
; CALLING SEQUENCE:
;    setdiff = mysetdiff(vec1, vec2)
; INPUTS:
;    VEC1 - An array of elements
;    VEC2 - Another array of elements
;
; RESULT:
;    The difference between VEC1 and VEC2. 
;
; EXAMPLE:
;   vec1 = indgen(5)
;   vec2 = indgen(5) + 3
;   print, mysetdiff(vec1,vec2)
;          0       1       2
;
; MODIFICATION HISTORY
; 
;  2012/06 -- Public release -- Jason Eastman (LCOGT)
;-

function mysetdiff, vec1, vec2

  for i=0, n_elements(vec2)-1 do vec1 = vec1[where(vec1 ne vec2[i])]
  return, vec1

end
