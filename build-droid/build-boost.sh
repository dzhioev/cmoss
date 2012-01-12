#!/bin/sh
set -e

# Copyright (c) 2011, Mevan Samaratunga
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * The name of Mevan Samaratunga may not be used to endorse or
#       promote products derived from this software without specific prior
#       written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL PIERRE-OLIVIER LATOUR BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

BOOST_SOURCE_NAME=boost_${BOOST_VERSION//./_}

# Download source
if [ ! -e "${BOOST_SOURCE_NAME}.tar.gz" ]
then
  curl $PROXY -O "http://surfnet.dl.sourceforge.net/project/boost/boost/${BOOST_VERSION}/${BOOST_SOURCE_NAME}.tar.gz"
fi

# Extract source
rm -rf "${BOOST_SOURCE_NAME}"
tar zxvf "${BOOST_SOURCE_NAME}.tar.gz"

pushd "${BOOST_SOURCE_NAME}"
tar zxvf "${TOPDIR}/build-droid/droid-boost-patch.tar.gz"

# Build

# ---------
# Bootstrap
# ---------

# Make the initial bootstrap
echo "Performing boost boostrap"

./bootstrap.sh
if [ $? != 0 ] ; then
	echo "ERROR: Could not perform boostrap! See $TMPLOG for more info."
	exit 1
fi

# -------------------------------------------------------------
# Patching will be done only if we had a successfull bootstrap!
# -------------------------------------------------------------

# Apply patches to boost
PATCHES_DIR=droid-boost-patch/build
if [ ! -d "$PATCHES_DIR" ] ; then
	echo "ERROR: Could not locate droid build patch files."
	exit 1
fi

PATCHES=`(cd $PATCHES_DIR && find . -name "*.patch" | sort) 2> /dev/null`
if [ -z "$PATCHES" ] ; then
	echo "No patches files in $PATCHES_DIR"
else
	PATCHES=`echo $PATCHES | sed -e s%^\./%%g`
	SRC_DIR=${TMPDIR}/${BOOST_SOURCE_NAME}
	for PATCH in $PATCHES; do
		PATCHDIR=`dirname $PATCH`
		PATCHNAME=`basename $PATCH`
		echo "Applying $PATCHNAME into $SRC_DIR/$PATCHDIR"
		patch -p1 < $PATCHES_DIR/$PATCH
		if [ $? != 0 ] ; then
			dump "ERROR: Patch failure !! Please check your patches directory! Try to perform a clean build using --clean"
			exit 1
		fi
	done
fi

BOOSTPATCH=${TMPDIR}/${BOOST_SOURCE_NAME}/droid-boost-patch

cat >> tools/build/v2/user-config.jam <<EOF

using android : i686 : ${DROIDTOOLS}-g++ :
<compileflags>-Os
<compileflags>-O2
<compileflags>-g
<compileflags>-fexceptions
<compileflags>-frtti
<compileflags>-fpic
<compileflags>-ffunction-sections
<compileflags>-funwind-tables
<compileflags>-fomit-frame-pointer
<compileflags>-fno-strict-aliasing
<compileflags>-finline-limit=64
<compileflags>-DANDROID
<compileflags>-D__ANDROID__
<compileflags>-DNDEBUG
<compileflags>-I${BOOSTPATCH}/crystax-ndk-headers/platforms/android-14/arch-x86/usr/include
<compileflags>-I${BOOSTPATCH}/crystax-ndk-headers/sources/cxx-stl/gnu-libstdc++/include/4.4.3
<compileflags>-I${BOOSTPATCH}/crystax-ndk-headers/sources/cxx-stl/gnu-libstdc++/libs/x86/4.4.3/include
<compileflags>-I${ROOTDIR}/include
<linkflags>-nostdlib
<linkflags>-lc
<linkflags>-Wl,-rpath-link=${SYSROOT}/usr/lib
<linkflags>-L${SYSROOT}/usr/lib
<linkflags>-L${BOOSTPATCH}/crystax-ndk-headers/sources/cxx-stl/gnu-libstdc++/libs/x86/4.4.3
<linkflags>-L${ROOTDIR}/lib
# Flags above are for android
<architecture>x86
<compileflags>-fvisibility=hidden
<compileflags>-fvisibility-inlines-hidden
<compileflags>-fdata-sections
<cxxflags>-D_REENTRANT
<cxxflags>-D_GLIBCXX__PTHREADS
<cxxflags>-DBOOST_THREAD_LINUX
<cxxflags>-DBOOST_HAS_PTHREADS
<cxxflags>-DBOOST_HAS_GETTIMEOFDAY
;

using android : arm : ${DROIDTOOLS}-g++ :
<compileflags>-Os
<compileflags>-O2
<compileflags>-g
<compileflags>-fexceptions
<compileflags>-frtti
<compileflags>-fpic
<compileflags>-ffunction-sections
<compileflags>-funwind-tables
<compileflags>-march=armv5te
<compileflags>-mtune=xscale
<compileflags>-msoft-float
<compileflags>-mthumb
<compileflags>-fomit-frame-pointer
<compileflags>-fno-strict-aliasing
<compileflags>-finline-limit=64
<compileflags>-D__ARM_ARCH_5__
<compileflags>-D__ARM_ARCH_5T__
<compileflags>-D__ARM_ARCH_5E__
<compileflags>-D__ARM_ARCH_5TE__
<compileflags>-DANDROID
<compileflags>-D__ANDROID__
<compileflags>-DNDEBUG
<compileflags>-I${BOOSTPATCH}/crystax-ndk-headers/platforms/android-14/arch-arm/usr/include
<compileflags>-I${BOOSTPATCH}/crystax-ndk-headers/sources/cxx-stl/gnu-libstdc++/include/4.4.3
<compileflags>-I${BOOSTPATCH}/crystax-ndk-headers/sources/cxx-stl/gnu-libstdc++/libs/armeabi-v7a/4.4.3/include
<compileflags>-I${ROOTDIR}/include
<linkflags>-nostdlib
<linkflags>-lc
<linkflags>-Wl,-rpath-link=${SYSROOT}/usr/lib
<linkflags>-L${SYSROOT}/usr/lib
<linkflags>-L${BOOSTPATCH}/crystax-ndk-headers/sources/cxx-stl/gnu-libstdc++/libs/armeabi-v7a/4.4.3
<linkflags>-L${ROOTDIR}/lib
# Flags above are for android
<architecture>arm
<compileflags>-fvisibility=hidden
<compileflags>-fvisibility-inlines-hidden
<compileflags>-fdata-sections
<cxxflags>-D__arm__
<cxxflags>-D_REENTRANT
<cxxflags>-D_GLIBCXX__PTHREADS
<cxxflags>-DBOOST_THREAD_LINUX
<cxxflags>-DBOOST_HAS_PTHREADS
<cxxflags>-DBOOST_HAS_GETTIMEOFDAY
;
EOF

cat >> project-config.jam <<EOF
libraries = --with-date_time --with-filesystem --with-program_options --with-regex --with-signals --with-system --with-thread --with-iostreams ;

option.set prefix : ${ROOTDIR}/ ;
option.set exec-prefix : ${ROOTDIR}/bin ;
option.set libdir : ${ROOTDIR}/lib ;
option.set includedir : ${ROOTDIR}/include ;
EOF

if [ "${PLATFORM}" == "arm-linux-androideabi" ]
then
	./b2 threading=multi --layout=versioned target-os=linux toolset=android-arm install
else
	./b2 threading=multi --layout=versioned target-os=linux toolset=android-i686 install
fi

mv ${ROOTDIR}/include/boost-*/boost ${ROOTDIR}/include
rm -fr ${ROOTDIR}/include/boost-*

#===============================================================================

# Clean up
popd
rm -rf "${BOOST_SOURCE_NAME}"