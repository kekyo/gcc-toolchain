# gcc cross toolchain builder on MSYS2/MinGW

## Built binaries

* See release page: https://github.com/kekyo/gcc-toolchain/releases

## Prerequisities

* MSYS2 (http://www.msys2.org/)
  * [Currently tested on MSYS2 64bit environment (20161025)](http://repo.msys2.org/distrib/x86_64/msys2-x86_64-20161025.exe)

## Build

### Install and setup MSYS2

* You have to choose "final-result of target toolchain (gcc.exe, ld.exe ...) arch" for 64bit or 32bit.
* Be careful: You have to choose "MinGW console" instead "MSYS2 console".

#### 64bit: Open MinGW 64bit console and execute below:

```
pacman -Syuu
pacman -S bzip2 base-devel mingw-w64-x86_64-toolchain
```

#### 32bit: Open MinGW 32bit console and execute below:

```
pacman -Syuu
pacman -S bzip2 base-devel mingw-w64-i686-toolchain
```

### Build gcc toolchains

1. Execute `build-prerequisities.sh`
  * It downloads gcc related source codes from gnu.org.
  * Build prerequisity libraries into "stage/gcc-bootstrap/".
  * It requires execution only once.
2. Execute `build.sh` with required [target specific.](https://gcc.gnu.org/install/specific.html)
  * ex: `build.sh arm-none-eabi`
  * ex: `build.sh arm-none-eabi avr xtensa-none-elf`
  * You can set arguments of multiple targets. And it can execute multiple times.
  * If building finished normally, toolchains store into "artifacts/gcc-\*\_\*\_\*.tar.bz2"
  * ex: "artifacts/gcc-7.2_mingw-w64-i686_arm-none-eabi.tar.bz2"

#### Note:

* When received error executing at 'configure autoconf':

```
C:/msys64/usr/bin/gawk.exe: error while loading shared libraries: msys-readline7.dll: cannot open shared object file: No such file or directory
```

* You have to copy (or link) the '/usr/bin/msys-readline6.dll' to '/usr/bin/msys-readline7.dll'.
  * MSYS2's bug? (Cause at 2018.01.08)

## License

* MIT
