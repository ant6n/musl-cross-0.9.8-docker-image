# musl-cross-0.9.8-docker-image
A docker image (Dockerfile) that includes gcc-musl cross-compilers for various architectures/cpu-configurations (including i386-soft-fp).
This is used to build the binaries for a simple static benchmark suite. The intention is to use these as a canonical set of compilers,
to never update.

The image includes cross compilers for the following architectures/cpu-configurations (some of which are implemented with simple shell scripts
acting as a driver for other compilers, enabling certain compilation flags).

- i386 (no fpu)
- i486 (x87)
- i586 (x87+mmx)
- i686 (x87+mmx+sse)
- i786 (x87+mmx+sse+sse2)
- x86_64 (x87+mmx+sse+sse2)
- armv6 (no fpu, arm mode)
- armv6 (vfpv2, arm mode)
- armv7 (neon+vfpv3, thumb mode)
- aarch64

It's based on musl-cross-make 0.9.8, and includes the following dependencies:
- gcc-6.4.0
- musl-1.1.22
- binutils-2.27
- gmp-6.1.1
- linux-4.4.10 kernel headers
- mpc-1.0.3
- mpfr-3.1.4

The cross compilers are in the image at `/musl-cross/bin/<arch>-<compiler>`, where compiler is one of `gcc`, `g++`, `cpp`.

The i386-soft-float target is built using ieeelib (since gcc doesn't provide a complete soft float lib for x86). It's built on a terribly
hacked together build script which patches parts of gcc and musl in the middle of the compilation. It's not a 'true' i386 target, since it
includes `cmpxchg` instructions in it's stdlib, as well as a few load-float-state kind of instructions (so perhaps consider it to be a
486SX target).
