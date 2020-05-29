#!/bin/bash 
#
# This builds the (Outrun) M68000 cross compiler 'suite'.
# - Binutils
# - GCC (C, C++)
# - Newlib
# - libgcc, libstdc++-v3
#
# Prerequisites:
# - MinGW:
#   Download the setup program, and should you have unchecked EVERYTHING including the graphic installer, go to the installation folder and run:
#     bin\mingw-get.exe install msys-base mingw32-base
#  
#   Afterwards, go to the newly created msys\1.0 subfolder and start msys.bat.
#   NOTE: If your user name has a space in it (full name), you should add 'SET USERNAME=SomeUser' to msys.bat before starting.
#
#   In the MSYS prompt, run /postinstall/pi.sh, and set up the MinGW installation folder.
#
# Then copy this script to your home folder and run it.
#
# Packages needed (these are installed as needed by this script):
#   - msys-base (installed above)
#   - mingw32-base (installed above)
#   - msys-wget
#   - mingw32-gmp (dev)
#   - mingw32-mpfr(dev)
#   - mingw32-mpc (dev)
#   - mingw32-gcc-g++

# Test for spaces in the current directory.
homefolder=`pwd`
if [[ $homefolder =~ .\ . ]]
then
  echo "Current directory '$homefolder' contains spaces. Compile will fail. Please change to another directory, or set up another user by adding:

  SET USERNAME=SomeUser

in msys.bat"
  exit 1
fi

# Versions.
# Tested with:
# binutils 2.24, gcc 4.9.0, isl 0.12.2, cloog 0.18.1, newlib 2.1.0
# binutils 2.27, gcc 6.1.0, isl 0.16.1, cloog 0.18.1, newlib 2.4.0
BINUTILS_VERSION=binutils-2.27
GCC_VERSION=gcc-6.1.0
ISL_VERSION=isl-0.16.1
CLOOG_VERSION=cloog-0.18.1
NEWLIB_VERSION=newlib-2.4.0

# Other settings.
PREFIX=/c/outrun/$GCC_VERSION
TARGET=m68k-elf
TEMPFOLDER=gcc-temp
LANGUAGES=c,c++

echo Building in: $PREFIX
echo Building languages: $LANGUAGES
echo Building target: $TARGET
echo Using temporary folder: $TEMPFOLDER

# This makes sure we exit if anything unexpected happens.
set -e

# Install MinGW components.
echo Downloading and installing MinGW packages...
mingw-get install msys-wget
# mingw-get install mingw32-binutils (already installed)
# mingw-get install mingw32-gcc (already installed)

# C++/target runtime libs.
mingw-get install mingw32-gcc-g++
mingw-get install mingw32-gmp
mingw-get install mingw32-mpc
mingw-get install mingw32-mpfr

# Redist only
# mingw-get install msys-zip

# Hack: remove temp folder from failed run.
# echo Removing old temporary data...
# rm -r $TEMPFOLDER

# Download everything.
echo Downloading packages...
mkdir $TEMPFOLDER
mkdir $TEMPFOLDER/downloads
cd $TEMPFOLDER/downloads
wget http://ftp.gnu.org/pub/gnu/binutils/$BINUTILS_VERSION.tar.bz2
wget http://ftp.gnu.org/pub/gnu/gcc/$GCC_VERSION/$GCC_VERSION.tar.bz2
wget ftp://gcc.gnu.org/pub/gcc/infrastructure/$ISL_VERSION.tar.bz2
wget ftp://gcc.gnu.org/pub/gcc/infrastructure/$CLOOG_VERSION.tar.gz
wget ftp://sourceware.org/pub/newlib/$NEWLIB_VERSION.tar.gz
cd ..

# Unpack binutils.
echo Unpacking binutils...
tar jxvf ./downloads/$BINUTILS_VERSION.tar.bz2

# Build binutils.
echo Building binutils...
mkdir binutils-obj
cd binutils-obj
../$BINUTILS_VERSION/configure --prefix=$PREFIX --target=$TARGET
make
make install
cd ..

# Unpack GCC and prerequisites
echo Unpacking GCC and prerequisites
tar jxvf ./downloads/$GCC_VERSION.tar.bz2
tar jxvf ./downloads/$ISL_VERSION.tar.bz2
tar xvf ./downloads/$CLOOG_VERSION.tar.gz

# Move ISL and CLooG into the GCC directory tree.
mv $ISL_VERSION ./$GCC_VERSION/isl
mv $CLOOG_VERSION ./$GCC_VERSION/cloog

# Configure and build GCC (compilers only)
echo Building GCC...
mkdir gcc-obj
cd gcc-obj
../$GCC_VERSION/configure --prefix=$PREFIX --target=$TARGET --enable-languages=$LANGUAGES --with-newlib --disable-libmudflap --disable-libssp --disable-libgomp --disable-libstdcxx-pch --disable-threads --disable-nls --disable-libquadmath --with-gnu-as --with-gnu-ld --without-headers
make all-gcc
make install-gcc
cd ..

# Copying required .dll files.
cp `where libgmp-10.dll` $PREFIX/bin
cp `where libmpc-3.dll` $PREFIX/bin
cp `where libmpfr-4.dll` $PREFIX/bin
cp `where libgcc_s_dw2-1.dll` $PREFIX/bin

# Add the output folder to our search path. We'll need this if we want to cross compile.
export PATH=$PATH:$PREFIX/bin

# Unpack newlib.
tar vxf downloads/$NEWLIB_VERSION.tar.gz

# Patch newlib 2.1.0 compile errors.
# For some reason the -i parameter doesn't work in MinGW, permission errors on the temporary files.
if [ $NEWLIB_VERSION = 'newlib-2.1.0' ]
then

	mv $NEWLIB_VERSION/libgloss/m68k/io-read.c $NEWLIB_VERSION/libgloss/m68k/io-read.bak
	sed -e 's/ssize_t/_READ_WRITE_RETURN_TYPE/g' $NEWLIB_VERSION/libgloss/m68k/io-read.bak > $NEWLIB_VERSION/libgloss/m68k/io-read.c
	rm $NEWLIB_VERSION/libgloss/m68k/io-read.bak

	mv $NEWLIB_VERSION/libgloss/m68k/io-write.c $NEWLIB_VERSION/libgloss/m68k/io-write.bak
	sed -e 's/ssize_t/_READ_WRITE_RETURN_TYPE/g' $NEWLIB_VERSION/libgloss/m68k/io-write.bak > $NEWLIB_VERSION/libgloss/m68k/io-write.c
	rm $NEWLIB_VERSION/libgloss/m68k/io-write.bak

fi

# Compile newlib
echo Compiling newlib...
mkdir newlib-obj
cd newlib-obj
../$NEWLIB_VERSION/configure --prefix=$PREFIX --target=$TARGET --disable-newlib-multithread --disable-newlib-io-float --enable-lite-exit --disable-newlib-supplied-syscalls
make
make install
cd ..

# Now we can build libgcc and libstdc++-v3
cd gcc-obj
echo Building libgcc and libstdc++
make all-target-libgcc all-target-libstdc++-v3
make install-target-libgcc install-target-libstdc++-v3
cd ..

# Build redistributable.
# cd $PREFIX
# zip -r -9 outrun-$GCC_VERSION.zip .

echo All done!
echo Output binaries for $TARGET are in $PREFIX
echo It\'s now safe to wipe $TEMPFOLDER
