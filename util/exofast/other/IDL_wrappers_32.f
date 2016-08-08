c these wrappers are for 32 bit architectures
c read the README for compilation instructions
c if adding additional wrappers, DO NOT INCLUDE "_" 
c anywhere in the name -- different compilers assign 
c them different entry point names which make writing 
c robust IDL routines to call them difficult

c IDL wrapper for Eric Agol's occultquad.f routine
      SUBROUTINE occultquadfortran(argc, argv)
      INTEGER*4 argc, argv(*), j
      j = LOC(argc)
      call occultquad(%VAL(argv(1)), %VAL(argv(2)), %VAL(argv(3)),
     &     %VAL(argv(4)), %VAL(argv(5)), %VAL(argv(6)), %VAL(argv(7)))
      RETURN
      END
