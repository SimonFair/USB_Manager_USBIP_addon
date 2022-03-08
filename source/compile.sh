# Create necessary directories
mkdir -p /USBIP/lib/modules/${UNAME}/kernel/drivers/usb/usbip

# Compile usbip binaries and install them to a temporary directory
cd ${DATA_DIR}/linux-$UNAME/tools/usb/usbip
./autogen.sh
./configure --prefix=/usr --libdir=/usr/lib64
make -j${CPU_COUNT}
make DESTDIR=/USBIP install -j${CPU_COUNT}

# Patch .config with necessary module for USBIP_HOST
sed -i 's/# CONFIG_USBIP_HOST is not set/CONFIG_USBIP_HOST=m/g' ${DATA_DIR}/linux-$UNAME/.config

# Compile the modules and install them to a temporary directory
cd ${DATA_DIR}/linux-$UNAME/
make modules SUBDIRS=drivers/usb/usbip/ -j${CPU_COUNT}
make INSTALL_MOD_PATH=/USBIP M=drivers/usb/usbip/ modules_install -j${CPU_COUNT}
mv /USBIP/lib/modules/$UNAME/extra/* /USBIP/lib/modules/$UNAME/kernel/drivers/usb/usbip/
cd /USBIP/lib/modules/$UNAME/

# Cleanup modules directory
find . -maxdepth 1 -not -name 'kernel' -print0 | xargs -0 -I {} rm -R {} 2&>/dev/null

#Create Slackware package
PLUGIN_NAME="usbip"
BASE_DIR="/USBIP"
TMP_DIR="/tmp/${PLUGIN_NAME}_"$(echo $RANDOM)""
VERSION="$(date +'%Y.%m.%d')"
mkdir -p $TMP_DIR/$VERSION
cd $TMP_DIR/$VERSION
cp -R $BASE_DIR/* $TMP_DIR/$VERSION/
mkdir $TMP_DIR/$VERSION/install
tee $TMP_DIR/$VERSION/install/slack-desc <<EOF
       |-----handy-ruler------------------------------------------------------|
$PLUGIN_NAME: $PLUGIN_NAME Package contents:
$PLUGIN_NAME:
$PLUGIN_NAME: Source: https://github.com/torvalds/linux/tree/master/tools/usb/usbip
$PLUGIN_NAME:
$PLUGIN_NAME:
$PLUGIN_NAME: Custom $PLUGIN_NAME package for Unraid Kernel v${UNAME%%-*} by ich777
$PLUGIN_NAME:
EOF
${DATA_DIR}/bzroot-extracted-$UNAME/sbin/makepkg -l n -c n $TMP_DIR/$PLUGIN_NAME-plugin-$UNAME-1.txz
md5sum $TMP_DIR/$PLUGIN_NAME-plugin-$UNAME-1.txz | awk '{print $1}' > $TMP_DIR/$PLUGIN_NAME-plugin-$UNAME-1.txz.md5
