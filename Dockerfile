FROM debian:jessie-20190910-slim
WORKDIR static-benchmarks

# install some basic software
RUN apt-get update \
 && apt-get -y install xz-utils wget curl cpio gettext bzip2 make build-essential libncurses5-dev git nano

# install musl-cross-make
WORKDIR /musl-cross-build
RUN wget -nv https://github.com/richfelker/musl-cross-make/archive/v0.9.8.tar.gz \
 && tar xzf v0.9.8.tar.gz \
 && rm v0.9.8.tar.gz

# build/install i386-sf and all other compilers
WORKDIR /
COPY scripts/make_i386_sf.sh scripts/patch-i386-compiler.sh /musl-cross-build/scripts/
RUN  bash /musl-cross-build/scripts/make_i386_sf.sh
COPY scripts/make_musl_for_all.sh /musl-cross-build/scripts/
RUN  bash /musl-cross-build/scripts/make_musl_for_all.sh



# OLD GRABAGE
## compile for all targets
## for i386-soft, compile the float library (using the created compiler) -> copy into /lib
## $ cd libgcc/soft-fp/
## $ gcc -c -O2 -msoft-float -m32 -march=i386 -mtune=i386  -I../config/arm/ -I..  *.c
## $ ar -crv libsoft-fp.a *.o
## based off https://stackoverflow.com/questions/1018638/using-software-floating-point-on-x86-linux
#
## ieeelib: gcc -I../musl-cross-make-0.9.8/gcc-6.4.0/include/ -c -O2 -msoft-float -m32 -march=i386 -mno-fp-ret-in-387 -mtune=i386  sfieeelib.c dfieeelib.c sfdfcvt.c
## append  -lsoft-fp to musl-make
#
#
#i386 notes:
#- run usual i386 target to get compiler
#- compile ieee lib
#    make CC=../musl-cross-make-0.9.8/output/bin/i386-linux-musl-gcc AR=../musl-cross-make-0.9.8/output/bin/i386-linux-musl-ar INCLUDE=-I/static-benchmarks/musl-cross-make-0.9.8/gcc-6.4.0/include
#- delete musl, set -msoft-float etc. and use the following adaptations to remove float instructions
#
#musl compile soft
#musl-cross-make-0.9.8/build/local/i386-linux-musl/src_musl
## delete i386 math assembly functions
#  musl-cross-make-0.9.8/build/local/i386-linux-musl/src_musl/src/math/i386# rm *
## use float.h of arm (64 bit long double)
#  cp ./arch/arm/bits/float.h ./arch/i386/bits/float.h
## run make, it will complain about missing float functions - add them to the musl makefile
##  lib/libc.so: $(LOBJS) $(LDSO_OBJS)
##        $(CC) $(CFLAGS_ALL) $(LDFLAGS_ALL) -nostdlib -shared \
##        -Wl,-e,_dlstart -o $@ $(LOBJS) $(LDSO_OBJS) $(LIBCC) -lsoft-fp -L/static-benchmarks/ieeelib
#
##make[2]: Entering directory '/static-benchmarks/musl-cross-make-0.9.8/build/local/i386-linux-musl/obj_gcc'
##make[2]: *** No rule to make target 'all-target-libgcc'.  Stop.
#
## rm libgcc, etc. etc., patch
## /static-benchmarks/musl-cross-make-0.9.8/build/local/i386-linux-musl/obj_gcc/gcc/ xgcc xg++
## -> insert -msoft-float, -mlong-double-64
## OLD MAKE of ieeelib: make CC=../musl-cross-make-0.9.8/output/bin/i386-linux-musl-gcc AR=../musl-cross-make-0.9.8/output/bin/i386-linux-musl-ar INCLUDE=-I/static-benchmarks/musl-cross-make-0.9.8/gcc-6.4.0/include
#
#
#
## i386sf script
## - compile ieeelib
##      C_FLAGS := -c -O2 -msoft-float -mlong-double-64 -mno-fp-ret-in-387 -march=i386 -mtune=i386 -fno-align-functions -fno-align-jumps -fno-align-loops -fno-align-labels
##      
##      
## - make project, let it complain at musl float
## - replace xgcc/xg++, patch musl, delete all object files
## - 
#
#
#== new config mak ==
#TARGET = i386-linux-musl
#
#STAT  = -static --static
#FLAG  = -g0 -O2 -fno-align-functions -fno-align-jumps -fno-align-loops -fno-align-labels -mno-fp-ret-in-387 -mlong-double-64
#COMMON_CONFIG += --disable-nls CFLAGS="${FLAG}" CXXFLAGS="${FLAG}" FFLAGS="${FLAG}" LDFLAGS="-s ${STAT}"
#GCC_CONFIG += --enable-languages=c,c++ --disable-libquadmath --disable-decimal-float --enable-softfloat --with-long-double-64 --disable-multilib
#
#FLAG_SOFT = -g0 -O2 -fno-align-functions -fno-align-jumps -fno-align-loops -fno-align-labels -mno-fp-ret-in-387 -mlong-double-64 -msoft-float
#SOFT_CONFIG = --disable-decimal-float --enable-softfloat --with-long-double-64 CFLAGS="${FLAG_SOFT}" CXXFLAGS="${FLAG_SOFT}" FFLAGS="${FLAG_SOFT}" LDFLAGS="-s ${STAT}"
#
#MUSL_CONFIG += $(SOFT_CONFIG)
#TOOCHAIN_CONFIG += $(SOFT_CONFIG)
#
#
#
#
#
#
#== old config.mak: ==
#STAT = -static --static
#FLAG = -g0 -O2 -fno-align-functions -fno-align-jumps -fno-align-loops -fno-align-labels -mno-fp-ret-in-387 -mlong-double-64
## -msoft-float -mno-fp-ret-in-387
#
## By default source archives are downloaded with wget. curl is also an option.
#
## DL_CMD = wget -c -O
## DL_CMD = curl -C - -L -o
#
## Something like the following can be used to produce a static-linked
## toolchain that's deployable to any system with matching arch, using
## an existing musl-targeted cross compiler. This only works if the
## system you build on can natively (or via binfmt_misc and qemu) run
## binaries produced by the existing toolchain (in this example, i486).
#
## COMMON_CONFIG += CC="i486-linux-musl-gcc -static --static" CXX="i486-linux-musl-g++ -static --static"
#
## Recommended options for smaller build for deploying binaries:
#
## COMMON_CONFIG += CFLAGS="-g0 -Os" CXXFLAGS="-g0 -Os" LDFLAGS="-s"
#COMMON_CONFIG += CFLAGS="${FLAG}" CXXFLAGS="${FLAG}" FFLAGS="${FLAG}" LDFLAGS="-s ${STAT}"
#
## Recommended options for faster/simpler build:
#
#COMMON_CONFIG += --disable-nls
#GCC_CONFIG += --enable-languages=c,c++
## --disable-libquadmath 
#GCC_CONFIG += --disable-decimal-float --enable-softfloat --with-long-double-128
## GCC_CONFIG += --disable-multilib
#
#MUSL_FLAG = -mno-fp-ret-in-387 ${FLAG}
## MUSL_FLAG = -msoft-float -mno-fp-ret-in-387 ${FLAG}
#MUSL_CONFIG += CFLAGS="${MUSL_FLAG}" CXXFLAGS="${MUSL_FLAG}" FFLAGS="${MUSL_FLAG}" LDFLAGS="-s ${STAT}"
#
#
#
#
#
#
#
#
#
## TARGETS
## i386-soft
## i486-fpu
## i586-mmx
## i686-sse
## i686-sse2
## amd64-sse2
#
## armeabi
## armeabi-hf (vfp2)
## armeabi-hf (vfp4)
## armeabi-hf (neon)
## aarch64
#
#
## BUILDROOT
##apt-get install gettext cpio
##RUN useradd -ms /bin/bash builder
##USER builder
##WORKDIR /static-benchmarks
##RUN wget -nv http://buildroot.uclibc.org/downloads/buildroot-2013.05.tar.bz2 \
##    && tar -xjf buildroot-2013.05.tar.bz2 \
##    && rm buildroot-2013.05.tar.bz2 \
##    && cd buildroot-2013.05
##    && make menuconfig
##
#
#
#
#
#
#
#
#
#
#
#
#
#
## download clang 6.0.0 binary
##RUN wget -nv http://releases.llvm.org/6.0.0/clang+llvm-6.0.0-x86_64-linux-gnu-debian8.tar.xz \
## && tar -xJf clang+llvm-6.0.0-x86_64-linux-gnu-debian8.tar.xz \
## && mv clang+llvm-6.0.0-x86_64-linux-gnu-debian8 clang6 \
## && rm clang+llvm-6.0.0-x86_64-linux-gnu-debian8.tar.xz
#
## CROSSTOOL
##RUN apt-get -y install build-essential libncurses5-dev automake libtool bison flex texinfo gawk curl zip libtool-bin cvs subversion
##RUN apt-get -y install libexpat1-dev python help2man
##RUN apt-get -y install gcj-jdk 
##RUN wget http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.24.0.tar.xz
##RUN tar -xJf crosstool-ng-1.24.0.tar.xz 
##WORKDIR crosstool-ng-1.24.0
##RUN ./configure --prefix=/static-benchmarks/crosstool-ng
##RUN make
##RUN make install
## (i386 - linux kernel 3.4.*)
#
#
## install some required build tools
##RUN apt-get -y install make
#
#
#
#
#
## download all sources
##WORKDIR /static-benchmarks
#
##RUN wget -nv http://anduin.linuxfromscratch.org/LFS/bzip2-1.0.6.tar.gz \
##RUN wget -nv https://www.python.org/ftp/python/2.7.16/Python-2.7.16.tgz
## v5.0: git clone https://git.tukaani.org/xz.git
#
## && tar -xzf bzip2-1.0.6.tar.gz \
## && rm bzip2-1.0.6.tar.gz 
### make CC="ecc -static -target arm32v6-linux" LDFLAGS="-static"
#
#
## Python md5 f1a2ace631068444831d01485466ece0

