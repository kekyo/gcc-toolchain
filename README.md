# gcc cross toolchain builder on MSYS2/MinGW

## Prerequisities

* MSYS2 (http://www.msys2.org/)
  * [Currently tested on MSYS2 64bit environment (20161025)](http://repo.msys2.org/distrib/x86_64/msys2-x86_64-20161025.exe)

## Install

### MSYS2

* You have to choose "final-result of target toolchain (gcc.exe, ld.exe ...) arch" for 64bit or 32bit.
  * 64bit: Open MinGW 64bit console.
  * 32bit: Open MinGW 32bit console.

```
pacman -Syuu
pacman -S bzip2 base-devel gcc gmp mpfr mpc isl mingw-w64-`arch`-toolchain
```

### Build gcc toolchains

* And execute `build-mingw.sh`
  * Default target configuration is "arm-none-eabi"
  * Build for binutils, gcc, newlib (with reentrant) and gdb.

## License

* MIT
