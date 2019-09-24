#!/bin/bash
builddir="/musl-cross-build"
outputdir="/musl-cross"

# this script patches a compiler into one targeting i386/soft-float
# calls $0-original with soft-float arguments
i=0
args=()
for arg in "$@"; do
    arg=${arg//-march=*/-march=i386}
    arg=${arg//-mlong-double-*/-mlong-double-64}
    args[$i]="$arg"
    ((++i))
done
# for debugging: print current dir and command in stderr
#>&2 echo IN DIRECTORY "$(pwd)"
#>&2 echo $0-original -mlong-double-64 -msoft-float -mno-fp-ret-in-387 "${args[@]}" -lsoft-fp -L$builddir/ieeelib
eval $0-original -mlong-double-64 -msoft-float -mno-fp-ret-in-387 "${args[@]}" -lsoft-fp -L$builddir/ieeelib

