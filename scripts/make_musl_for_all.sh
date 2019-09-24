builddir="/musl-cross-build"
outputdir="/musl-cross"


decho () {
    echo $(TZ='America/Toronto' date "+%Y-%m-%d %H:%M:%S") $@
}
secho () {
    if [ $? -eq 0 ]; then
	decho "--success!"
    else
	decho "--failure!"
    fi
}

# build cross compiler for given target ($1) and gcc_options ($2)
build_cross () {
    cd $builddir/musl-cross-make-0.9.8/
    mkdir -p logs
    echo "# $1 soft float setup"  > config.mak
    echo "TARGET = $1"   >> config.mak
    echo "OUTPUT = $outputdir"   >> config.mak
    echo "STAT  = -static --static" >> config.mak
    echo "FLAG  = -g0 -O2 -fno-align-functions -fno-align-jumps -fno-align-loops -fno-align-labels" >> config.mak
    echo "COMMON_CONFIG += --disable-nls CFLAGS=\"\${FLAG}\" CXXFLAGS=\"\${FLAG}\" FFLAGS=\"\${FLAG}\" LDFLAGS=\"-s \${STAT}\"" >> config.mak
    echo "GCC_CONFIG += --enable-languages=c,c++ --disable-libquadmath --disable-decimal-float --disable-multilib $2"  >> config.mak

    decho BUILDING TARGET $1 WITH config.mak:
    cat  config.mak

    decho MAKE
    make > /dev/null #logs/$1-build.log 2>&1
    secho
    
    decho INSTALL
    make install > /dev/null #logs/$1-install.log 2>&1
    secho

    decho CLEAN
    make clean >> /dev/null #logs/$1-install.log 2>&1
    secho

    decho DONE BUILDING TARGET $1
    echo
}

# build a compiler which is just a driver calling another compiler with extra arguments
# args: compiler-name-prefix original-compiler-name-prefix args-before args-after
# prefixes should be given without dash, e.g 'aarch64-linux-musl' to create 'aarch64-linux-musl-gcc'
# creates gcc, g++, cpp
build_driver () {
    decho CREATE DRIVER $1 "->" $2
    outdir=$outputdir/bin
    for cmd in gcc g++ cpp; do
	echo '#!/bin/bash' > $outdir/$1-$cmd
	echo 'eval $(dirname $0)/'$2-$cmd $3' "$@" '$4 >> $outdir/$1-$cmd
	chmod +x $outdir/$1-$cmd
    done
}



build_cross  i486-linux-musl "--with-arch=i486 --with-cpu=i486 --with-tune=i486"
build_driver i586-linux-musl i486-linux-musl "-march=pentium-mmx -mtune=pentium-mmx -mmmx" " "
build_driver i686-linux-musl i486-linux-musl "-march=pentium3    -mtune=pentium3    -mmmx -msse -mfpmath=sse" " "
build_driver i786-linux-musl i486-linux-musl "-march=pentium4    -mtune=pentium4    -mmmx -msse -msse2 -mfpmath=sse" " "

build_cross  arm-linux-musleabi   "--with-arch=armv6"
build_cross  arm-linux-musleabihf "--with-arch=armv6"
build_driver armv6sf-linux-musl arm-linux-musleabi   "-march=armv6k            -mfloat-abi=soft "
build_driver armv6hf-linux-musl arm-linux-musleabihf "-march=armv6k -mfpu=vfp  -mfloat-abi=hard"
build_driver armv7hf-linux-musl arm-linux-musleabihf "-mthumb -march=armv7  -mfpu=neon -mfloat-abi=hard"

build_cross aarch64-linux-musl "--enable-neon"

build_cross x86_64-linux-musl "--with-fpmath=sse --enable-sse --enable-sse2 --enable-mmx"



