#!/bin/bash
if [ -z "$1" ] ; then
    echo "Usage: $0 source [CFLAGS]"
    exit 1
fi
FLAGS_VAR="${@:2}"
make all MAKE_OBJECT="$1" MAKE_FLAGS="$FLAGS_VAR"
#make V=1 all MAKE_OBJECT="$1" MAKE_FLAGS="$FLAGS_VAR" # Verbose (for debugging)
COMP_STATUS="$?"
if [ $COMP_STATUS -eq "0" ] ; then
    echo "Compilation succeeded"
else
    echo "Compilation failed"
fi
rm -rf .tmp_versions
rm -f modules.order
rm -f Module.symvers
rm -f .*.cmd
rm -f *.mod.c
rm -f *.mod.o
rm -f *.o
rm -f .cache.mk
exit $COMP_STATUS
