
# functions that still have some float instructions
# - libc.a:
#     feclrearexcept, feraiseecxcept, __fesetround, fegetround, fegetenv, fesetenv
# - libcilkrts.a:
#     restore_x86_fpu_state
# functions that sill have cmpxchg
# - libc.a:
#     many functions related to threads, locks, mutexes, semaphores, cgt, clock
builddir="/musl-cross-build"
outputdir="/musl-cross"
decho () {
    echo $(TZ='America/Toronto' date "+%Y-%m-%d %H:%M:%S") $@
}
decho BUILDING MUSL i386-SF CROSS-COMPILER AT $builddir

    
# ========= INITIAL BUILD ===================
echo DELETE MUSL SO THAT THE ERROR WHILE CONFIGURING MUSL WILL ALWAYS HAPPEN
rm -rf $builddir/musl-cross-make-0.9.8/build/local/i386-linux-musl/src_musl
rm -rf $builddir/musl-cross-make-0.9.8/build/local/i386-linux-musl/obj_musl
rm -rf $builddir/musl-cross-make-0.9.8/musl-1.1.22

decho BUILD UNTIL HITTING AN ERROR WHILE CONFIGURING MUSL
cd $builddir/musl-cross-make-0.9.8

echo "# i386 soft float setup"  > config.mak
echo "TARGET = i386-linux-musl" >> config.mak
echo "OUTPUT = $outputdir"      >> config.mak
echo "DL_CMD = wget -nv -c -O"  >> config.mak
echo "STAT  = -static --static" >> config.mak
echo "FLAG  = -g0 -O2 -fno-align-functions -fno-align-jumps -fno-align-loops -fno-align-labels -mno-fp-ret-in-387 -mlong-double-64" >> config.mak
echo "COMMON_CONFIG += --disable-nls CFLAGS=\"\${FLAG}\" CXXFLAGS=\"\${FLAG}\" FFLAGS=\"\${FLAG}\" LDFLAGS=\"-s \${STAT}\"" >> config.mak
echo "GCC_CONFIG += --enable-languages=c,c++ --disable-libquadmath --disable-decimal-float --enable-softfloat --with-long-double-64 --disable-multilib" >> config.mak
echo "FLAG_SOFT = \${FLAG} -msoft-float" >> config.mak
echo "SOFT_CONFIG = --disable-decimal-float --enable-softfloat --with-long-double-64 CFLAGS=\"\${FLAG_SOFT}\" CXXFLAGS=\"\${FLAG_SOFT}\" FFLAGS=\"\${FLAG_SOFT}\" LDFLAGS=\"-s \${STAT}\" " >> config.mak

echo "MUSL_CONFIG += \$(SOFT_CONFIG)" >> config.mak
echo "TOOCHAIN_CONFIG += \$(SOFT_CONFIG)" >> config.mak
decho MAKE
make > /dev/null
decho AFTER MAKE

# fail happens here - when configuring musl
# ========= PATCH THE INCOMPLETE BUILD =====

decho PATCH XGCC/XG++
cd $builddir/musl-cross-make-0.9.8/build/local/i386-linux-musl/obj_gcc/gcc/
for cmd in xg++ xgcc g++-cross gcc-cross cpp; do
    if [ -f $cmd-original ]; then
	echo $cmd ALREADY PATCHED
    else
	echo PATCHING $cmd
	mv $cmd $cmd-original
	cp $builddir/scripts/patch-i386-compiler.sh $cmd
	echo "#PATCHED $cmd" >> $cmd
    fi
done


decho DOWNLOAD AND INSTALL IEELIB SOFT FLOAT
cd $builddir
git clone https://github.com/ant6n/ieeelib.git
cd ieeelib
make C_FLAGS="-B$builddir/musl-cross-make-0.9.8/build/local/i386-linux-musl/obj_gcc/gcc/ \
              -c -O2 -m32 -msoft-float -mlong-double-64 -mno-fp-ret-in-387 -march=i386 -mtune=i386 \
              -fno-align-functions -fno-align-jumps -fno-align-loops -fno-align-labels" \
     INCLUDE=-I$builddir/musl-cross-make-0.9.8/gcc-6.4.0/include \
     CC=$builddir/musl-cross-make-0.9.8/build/local/i386-linux-musl/obj_gcc/gcc/xgcc \
     OMIT_FIXUNSFFSI=1 > /dev/null
decho FINISHED COMPILING IEELIB 


decho PATCH MUSL
cd $builddir/musl-cross-make-0.9.8/build/local/i386-linux-musl/src_musl/
decho replace float.h
cp arch/arm/bits/float.h arch/i386/bits/float.h
decho remove math/i386/*.s
rm src/math/i386/*.s


decho REMOVE LIBGCC-GCC-ETC SOURCES THAT CAUSE ERRORS
# functions related to 80/128bit floats
echo "" > $builddir/musl-cross-make-0.9.8/build/local/i386-linux-musl/src_gcc/libgcc/soft-fp/extendxftf2.c
echo "" > $builddir/musl-cross-make-0.9.8/build/local/i386-linux-musl/src_gcc/libgcc/soft-fp/trunctfxf2.c
# replace x86 fenv.c with presumably portable version
cp $builddir/musl-cross-make-0.9.8/build/local/i386-linux-musl/src_gcc/libatomic/fenv.c \
   $builddir/musl-cross-make-0.9.8/build/local/i386-linux-musl/src_gcc/libatomic/config/x86/fenv.c


# ========= END OF PATCHING, COMPLETE HTE BUILD =====
decho CONTINUE MAKING i386-gcc-musl!!!!
cd $builddir/musl-cross-make-0.9.8
decho MAKE
make > /dev/null
decho MAKE INSTALL
make install > /dev/null
decho DONE

# ========= COPY CORRECT GCC/G++ =====================
decho PATCH FINAL GCC/G++
cd /
srcdir=$builddir/musl-cross-make-0.9.8/build/local/i386-linux-musl/obj_gcc/gcc
bindir=$outputdir/bin

cp $srcdir/xg++-original $bindir/i386-linux-musl-g++-original
cp $srcdir/cpp-original  $bindir/i386-linux-musl-cpp-original
cp $srcdir/xgcc-original $bindir/i386-linux-musl-gcc-original

# create a bash script driver calling e.g. gcc -> gcc-original with extra needed arguments
# args: name_of_driver name_of_target
create_c_driver() {
    out=$bindir/i386-linux-musl-$1
    echo '#!/bin/bash' > $out
    echo 'eval $(dirname $0)/i386-linux-musl-'$2' "$@" -mlong-double-64 -msoft-float -mno-fp-ret-in-387' >> $out
    chmod +x $out
}
create_c_driver 'c++' 'g++-original'
create_c_driver 'cpp' 'cpp-original'
create_c_driver 'g++' 'g++-original'
create_c_driver 'gcc' 'gcc-original'
create_c_driver 'gcc-6-4.0' 'gcc-original'

# ======== PUT SOFT FLOAT FUNCTIONS IN LIBGCC ========
# merge archives
decho MERGE SOFT-FLOAT LIB INTO LIBGCC.A
cd $outputdir/lib/gcc/i386-linux-musl/6.4.0/
mv libgcc.a libgcc-old.a
echo -e "create libgcc.a\naddlib libgcc-old.a\naddlib $builddir/ieeelib/libsoft-fp.a\nsave\nend" | $bindir/i386-linux-musl-ar -M
rm libgcc-old.a

decho CLEAN UP
cd $builddir/musl-cross-make-0.9.8/
make clean

decho DONE!

# find float instructions objects and archives recursively
# for i in $( find | grep "\.[oa]$" ); do echo $(objdump -d $i | grep fld | wc -l), $i; done | grep -v "0,"



