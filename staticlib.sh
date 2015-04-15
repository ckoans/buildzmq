#! /usr/bin/env bash

#  Built on:
#  * Mac OS X 10.10 (Darwin 14.3.0)
#  * Xcode 6.3
#  * libzmq 4.0.5
#  * libsodium 1.0.2
#
# Create a new working directory some where.
# Download zeromq source (tarball etc) as a sub-directory in this new working directory.
# Download libsodium source (tarball etc) as a sub-directory in this new working directory.
# Run this bash script in the new working directory.
# The compiled static library will exist in $BUILD_DIR_NAME, which is "build_libzmq" for my case.

export TARGETS=(armv7 armv7s i386);
export ZMQ_DIR_NAME="zeromq-4.0.5";
export SODIUM_DIR_NAME="libsodium-1.0.2";
export BUILD_DIR_NAME="build_libzmq";

setenv()
{
    # $1, $BUILD_HOST, $SYSROOT are the 3 variables that control our cross-compilation.
    case "$1" in
        "armv7")
            export BUILD_HOST="arm-apple-darwin11";
            echo "Setting BUILD_HOST as $BUILD_HOST";
            export SYSROOT="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk";
            echo "Setting SYSROOT as $SYSROOT";
            ;;
        "armv7s")
            export BUILD_HOST="arm-apple-darwin11";
            echo "Setting BUILD_HOST as $BUILD_HOST";
            export SYSROOT="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk";
            echo "Setting SYSROOT as $SYSROOT";
            ;;
        "i386")
            export BUILD_HOST="i686-apple-darwin10";
            echo "Setting BUILD_HOST as $BUILD_HOST";
            export SYSROOT="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk";
            echo "Setting SYSROOT as $SYSROOT";
            ;;
        *)
            echo "Failed to set BUILD_HOST";
            exit 1;
            ;;
    esac

    export CC="clang -arch $1 -mios-version-min=7.0 -isysroot $SYSROOT"
    export CXX="clang++ -arch $1 -mios-version-min=7.0 -isysroot $SYSROOT"
    export BUILD_PREFIX="`pwd`/$BUILD_DIR_NAME/$1"
    mkdir -p $BUILD_PREFIX
}

compile_zmq()
{
    [[ -z "$1" ]] && { echo "arch not specified." ; exit 1; }

    echo "Compiling libzmq for "$1".......";

    setenv $1

    echo "BUILD_PREFIX is $BUILD_PREFIX"

    cd $ZMQ_DIR_NAME;

    ./configure --enable-static --with-libsodium=../$SODIUM_DIR_NAME --with-libsodium-include-dir=../$SODIUM_DIR_NAME/src/libsodium/include --prefix=$BUILD_PREFIX --host=$BUILD_HOST

    sudo make && sudo make install

    sudo make clean && unset CC CXX BUILD_PREFIX BUILD_HOST SYSROOT

    cd ..
}

create_universal_library()
{
    echo "Creating universal static library"
    mkdir -p "`pwd`/$BUILD_DIR_NAME/universal/lib"
    lipo -create "`pwd`/$BUILD_DIR_NAME/${TARGETS[0]}/lib/libzmq.a" \
                "`pwd`/$BUILD_DIR_NAME/${TARGETS[1]}/lib/libzmq.a" \
                "`pwd`/$BUILD_DIR_NAME/${TARGETS[2]}/lib/libzmq.a" \
         -output "`pwd`/$BUILD_DIR_NAME/universal/lib/libzmq.a"
    echo "Checking that our universal static library has been compiled correctly"
    lipo -info "`pwd`/$BUILD_DIR_NAME/universal/lib/libzmq.a"
}

copy_zmq_headers()
{
    echo "Copying libzmq headers in universal library's include directory"
    mkdir -p "`pwd`/$BUILD_DIR_NAME/universal/include"
    cp -R "`pwd`/$ZMQ_DIR_NAME/include" "`pwd`/$BUILD_DIR_NAME/universal"
}

begin_compile()
{
    for item in ${TARGETS[*]}
    do
        compile_zmq $item
    done
    create_universal_library
    copy_zmq_headers
}

begin_compile
