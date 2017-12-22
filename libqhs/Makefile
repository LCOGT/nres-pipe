#
#    Try to build a dynamic library that IDL can use ...
#
# Rob Siverd
# Created:      2015-12-10
# Last updated: 2015-12-10
#--------------------------------------------------------------------------
#**************************************************************************
#--------------------------------------------------------------------------

# GNU compiler:
#GCC    := gcc -std=gnu99 -static -static-libgcc
GCC    := gcc -std=gnu99
GCWARN := -Wall -Wextra #
GCPERF := -O3 -msse2 -msse3 -ftree-vectorize -ftree-vectorizer-verbose=2 \
            -fPIC
         #-fpeel-loops -funroll-loops -DUSE_RESTRICT

# Which to use:
CC     := $(GCC)
CWARN  := $(GCWARN)
CPERF  := $(GCPERF)
COPTS  := $(CWARN) $(CPERF)

# --------------------------------------------

# Where custom libraries live:
MYPKG32 := $(HOME)/pkg32
MYPKG64 := $(HOME)/pkg64

# Libraries and such:
CDEFS  := -DCOMP="$(CC)" -DWARN="$(CWARN)" -DPERF="$(CPERF)" \
          -DDTYPE="float" -DTDTYPE="TFLOAT"
IDIRS  := -I$(MYPKG32)/include -I$(MYPKG64)/include
LDIRS  := -L$(MYPKG32)/lib -L$(MYPKG64)/lib
CFLAGS := $(COPTS) $(LDIRS) $(IDIRS) $(CDEFS)
CLIBS  := -lcfitsio -lm -lpthread


# What to make:
PROG = libqhs.so.1.0
MACLIB = libqhs.dylib

# How to make it:
#SRCS = mtest.c
#OBJS = imageIO.o img_arith.o
OBJS = run_qhs.o imageIO.o \
		 fastmem.o img_arith.o img_hdr.o simpleIO.o misc.o \
		 qhsmooth.o load_hist_rows.o load_kern_cols.o kern_calc.o

WATCH = Makefile hsmooth.h imageIO.h \
		  fastmem.h img_arith.h img_hdr.h simpleIO.h misc.h \
		  qhsmooth.h load_hist_rows.h load_kern_cols.h kern_calc.h

#--------------------------------------------------------------------------

#mandel: 
#  \rm $(PROG)

$(PROG) : $(OBJS)
	$(CC) -shared -Wl,-soname,libderp.so.1 -o $(PROG) $(OBJS)

mac : $(OBJS)
	$(CC) -dynamiclib -o $(MACLIB) $(OBJS)

%.o : %.c $(WATCH)
	$(CC) --static $(COPTS) $(IDIRS) $(CDEFS) -c $<

clean:
	\rm $(PROG) $(MACLIB) *.o


