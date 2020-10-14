#!/usr/bin/env bash
# Copyright (C) 2018 Abubakar Yagob (blacksuan19)
# Copyright (C) 2018 Rama Bondan Prakoso (rama982)
# SPDX-License-Identifier: GPL-3.0-or-later

# Main Environment
KERNEL_DIR=$PWD
KERN_IMG=$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb
ZIP_DIR=$KERNEL_DIR/AnyKernel3
CONFIG_DIR=$KERNEL_DIR/arch/arm64/configs
CORES=$(grep -c ^processor /proc/cpuinfo)
THREAD="-j$CORES"
CROSS_COMPILE+="ccache "
CROSS_COMPILE+="$PWD/aarch64-linux-android-4.9/bin/aarch64-linux-android-"

# Modules environtment
OUTDIR="$PWD/out/"
SRCDIR="$PWD/"
MODULEDIR="$PWD/AnyKernel3/modules/vendor/lib/modules/"
STRIP="$PWD/aarch64-linux-android-4.9/bin/$(echo "$(find "$PWD/aarch64-linux-android-4.9/bin" -type f -name "aarch64-*-gcc")" | awk -F '/' '{print $NF}' |\
			sed -e 's/gcc/strip/')"

# Export
export ARCH=arm64
export SUBARCH=arm64
export PATH=/usr/lib/ccache:$PATH
export CROSS_COMPILE
export KBUILD_BUILD_USER=reza
export KBUILD_BUILD_HOST=unique

# Is this logo
echo -e "╔╗─╔╗╔═╗─╔╗╔══╗╔═══╗╔╗─╔╗╔═══╗";
echo -e "║║─║║║║╚╗║║╚╣─╝║╔═╗║║║─║║║╔══╝";
echo -e "║║─║║║╔╗╚╝║─║║─║║─║║║║─║║║╚══╗";
echo -e "║║─║║║║╚╗║║─║║─║╚═╝║║║─║║║╔══╝";
echo -e "║╚═╝║║║─║║║╔╣─╗╚══╗║║╚═╝║║╚══╗";
echo -e "╚═══╝╚╝─╚═╝╚══╝───╚╝╚═══╝╚═══╝";

echo -e "\n(i) Cloning ToolChain..."
git clone https://github.com/raza231198/aarch64-linux-android-4.9 aarch64-linux-android-4.9

echo -e "\n(i) Staring Build..."
make  O=out $CONFIG $THREAD
make  O=out $THREAD

echo -e "\n(i) Cloning AnyKernel3..."
git clone https://github.com/raza231198/AnyKernel3 AnyKernel3

if [ $(find "${OUTDIR}" -name 'wlan.ko') ]; then
	echo -e "\n(i) Strip and move modules to AnyKernel3..."
	# thanks to @adekmaulana
	for MOD in $(find "${OUTDIR}" -name 'wlan.ko') ; do
		"${STRIP}" --strip-unneeded --strip-debug "${MOD}" &> /dev/null
		"${SRCDIR}"/scripts/sign-file sha512 \
		"${OUTDIR}/signing_key.priv" \
		"${OUTDIR}/signing_key.x509" \
		"${MOD}"
	find "${OUTDIR}" -name 'wlan.ko' -exec cp {} "${MODULEDIR}" \;
		done
	echo -e "\n(i) Done moving modules"
fi
echo -e "\n(i) Making ZiP"
cd $ZIP_DIR
cp $KERN_IMG $ZIP_DIR
make normal &>/dev/null
ghr -t ${GITHUB_TOKEN} -u ${CIRCLE_PROJECT_USERNAME} -r ${CIRCLE_PROJECT_REPONAME} -n "Latest Release for $(echo $DEVICE)" -b "Kernel $(echo $VERSION)" -c ${CIRCLE_SHA1} -delete ${VERSION} ${ZIP_DIR}
