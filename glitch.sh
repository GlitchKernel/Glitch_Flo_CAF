#!/bin/bash

# Glitch kernel build-script
#
# clean : clean the build directory.
# cleank : clean the built kernel packages
# aosp : build an aosp compatible kernel

# CM repo path :
repo=~/android/system

# Toolchain :
export ARCH="arm"
#export CROSS_PREFIX="$repo/prebuilts/gcc/linux-x86/arm/arm-eabi-4.6/bin/arm-eabi-"
#export CROSS_PREFIX="$repo/prebuilts/gcc/linux-x86/arm/linaro_4.8.2-2013.09/bin/arm-gnueabi-"
export CROSS_PREFIX="$repo/prebuilts/gcc/linux-x86/arm/sabermod-androideabi-4.8/bin/arm-linux-androideabi-"

setup ()
{

    if [ x = "x$repo" ] ; then
        echo "Android build environment must be configured"
        exit 1
    fi
    . "$repo"/build/envsetup.sh

#   Arch-dependent definitions
    case `uname -s` in
        Darwin)
            KERNEL_DIR="$(dirname "$(greadlink -f "$0")")"
            CROSS_PREFIX="$repo/prebuilts/gcc/darwin-x86/arm/arm-eabi-4.8/bin/arm-eabi-"
            ;;
        *)
            KERNEL_DIR="$(dirname "$(readlink -f "$0")")"
            CROSS_PREFIX="$CROSS_PREFIX"
            ;;
    esac

    BUILD_DIR="../glitch-build/kernel"

    if [ x = "x$NO_CCACHE" ] && ccache -V &>/dev/null ; then
        CCACHE=ccache
        CCACHE_BASEDIR="$KERNEL_DIR"
        CCACHE_COMPRESS=1
        CCACHE_DIR="$repo/kernel/Asus/.ccache"
        export CCACHE_DIR CCACHE_COMPRESS CCACHE_BASEDIR
    else
        CCACHE=""
    fi

}

build ()
{

    local target=flo
    echo "Building for N7"
    local target_dir="$BUILD_DIR/N7"
    local module
    rm -fr "$target_dir"
    mkdir -p "$target_dir"

    mka -C "$KERNEL_DIR" O="$target_dir" cyanogen_flo_defconfig HOSTCC="$CCACHE gcc"
    mka -C "$KERNEL_DIR" O="$target_dir" HOSTCC="$CCACHE gcc" CROSS_COMPILE="$CCACHE $CROSS_PREFIX" zImage modules

[[ -d release ]] || {
	echo "must be in kernel root dir"
	exit 1;
}

echo "copying modules and zImage"
mkdir -p $KERNEL_DIR/release/aroma/system/lib/modules/
cd $target_dir
find -name '*.ko' -exec cp -av {} $KERNEL_DIR/release/aroma/system/lib/modules/ \;
"$CROSS_PREFIX"strip --strip-unneeded $KERNEL_DIR/release/aroma/system/lib/modules/*
cd $KERNEL_DIR
mv $target_dir/arch/arm/boot/zImage $KERNEL_DIR/release/aroma/boot/glitch.zImage

echo "packaging it up"
cd release/aroma

. $KERNEL_DIR/../rev

if [ "$aosp" = "y" ] ; then

mkdir -p $KERNEL_DIR/release/Flashable-flo-AOSPfriendly
REL=Glitch-N7-r$counter-CAF4AOSP.zip

	zip -q -r ${REL} boot config META-INF system
	#sha256sum ${REL} > ${REL}.sha256sum
	mv ${REL}* $KERNEL_DIR/release/Flashable-flo-AOSPfriendly/
else

mkdir -p $KERNEL_DIR/release/Flashable-flo-CM11
REL=Glitch-N7-r$counter-CM11.zip

	zip -q -r ${REL} boot config META-INF system
	#sha256sum ${REL} > ${REL}.sha256sum
	mv ${REL}* $KERNEL_DIR/release/Flashable-flo-CM11/

fi

rm boot/glitch.zImage
rm -r system/lib/modules/*
cd $KERNEL_DIR
echo ""
echo ${REL}
}
    
setup

if [ "$1" = clean ] ; then
    rm -fr "$BUILD_DIR"/*
    cd release
    rm `find ./ -name '*.*~'` -rf
    rm `find ./ -name '*~'` -rf
    cd $KERNEL_DIR
    echo ""
    echo "Old build cleaned"

else

if [ "$1" = cleank ] ; then
    rm -fr "$KERNEL_DIR"/release/Flashable-flo-CM11/*
    rm -fr "$KERNEL_DIR"/release/Flashable-flo-AOSPfriendly/*
    echo "Built kernels cleaned"

else

if [ "$1" = aosp ] ; then

aosp="y"

	git apply ../CMpatch
    echo "--------------------------------------------------------"
    echo "------------Patched tree for AOSP compat----------------"
    echo "--------------------------------------------------------"

time {
		build flo
}

	git apply --reverse ../CMpatch
    echo "--------------------------------------------------------"
    echo "-----------Patched tree back to CM compat---------------"
    echo "--------------------------------------------------------"

else

time {

    build flo

}
fi
fi
fi
