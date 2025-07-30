#!/bin/ash
# ===========================================================
# vup-start.sh - VUP start script
# ===========================================================
# -----------------------------------------------------------
#   Global definitions
# -----------------------------------------------------------
TARFILELIST=tarfilelist
SD_MOUNT_POINT=/mnt/sdcarda
SD_DEVICE_FILE=/dev/sdcarda1
PKG_PATH=PRIVATE/MEIGROUP/PAVCN/SBG/P2SD/FW
RAMFS=/mnt/ramfs
MEM_NEEDS=8192
BMP_PATH=/usr/lib/p16
BMP_START=update_title.p16
BMP_END=update_end_title.p16
BMP_ERROR=update_error_title.p16
export VUPFB_MESSAGE_Y=16
export VUPFB_MESSAGE_W=360
# -----------------------------------------------------------
#   Functions
# -----------------------------------------------------------

# cmp_sum()
#
#  Compare check sum text file.
#
#  $1 : text file1
#  $2 : text file2
#
cmp_sum()
{
    str1=$(cat $1)
    str2=$(cat $2)
    echo $str1
    echo $str2
    if [ "$str1" = "$str2" ];then
	return 0
    else
	return 1
    fi
}

# disp_start()
#
#  Display VUP start message.
#
disp_start()
{
    # Turn off FB operations
    kill $(pidof vupfb) > /dev/null 2>&1
    vupfb bm "LOADING" "VUP SYS" 1500000 1500000 0 &
}

# disp_end()
#
#  Display VUP end message.
#
disp_end()
{
    # Turn off FB operations
    kill $(pidof vupfb) > /dev/null 2>&1
    vupfb m "VUP READY"
}

# disp_error()
#
#  Display error message.
#
disp_error()
{
    # Turn off FB operations
    kill $(pidof vupfb) > /dev/null 2>&1
    # Extract data
    zcat $BMP_PATH/$BMP_ERROR.gz > $BMP_ERROR
    vupfb f $BMP_ERROR
    rm -f $BMP_ERROR
    # Blinking LED
    kill $(pidof vupled) > /dev/null 2>&1
    vupled 1 0 1
}

# chkerr()
#
#  Check error value and error exit.
#
#  $1 : check value
#  $2 : error message
#  $3 : error exit code
#
chkerr() {
    if [ -n "$2" ]; then
	errmsg=$2
    else
	errmsg="*** error! ***"
    fi
    if [ -n "$3" ]; then
	errcode=$3
    else
	errcode=100
    fi
    if [ $1 != 0 ]; then
	echo "*** VUP error !!! ***"
	echo $errmsg
	disp_error
	cd /
	umount $SD_MOUNT_POINT
	umount $RAMFS
	exit $errcode
    fi
    return 0
}

# -----------------------------------------------------------
#   Main
# -----------------------------------------------------------

# Initialize shell
unalias -a

disp_start

# Check usable memory
freemem=$(free | grep "Mem:" | awk '{print $4}')
echo " Free memory = $freemem "
echo " Memory needs for VUP = $MEM_NEEDS "
if [ $freemem -lt $MEM_NEEDS ] ; then
    echo "Memory error!"
    echo "There is not enough memory to extract update files."
    disp_error
    exit 1
fi
echo "Memory OK."

mount -t ramfs ramfs $RAMFS
cd $RAMFS

# install osdfpga driver
insmod /lib/modules/`uname -r`/kernel/drivers/spd/osdfpga/osdfpga.o > /dev/null 2>&1

# install sdcard driver
insmod /lib/modules/`uname -r`/kernel/drivers/sdcard/sdcard.o > /dev/null 2>&1
mount -r -o noatime -t msdos /dev/sdcarda1 $SD_MOUNT_POINT
chkerr $? "SD card error." 6
# Check for busybox exit bug.
if [ $? -ne 0 ] ; then
    exit 6
fi
echo "SD mount O.K."

# Check VUP file
cd $SD_MOUNT_POINT/$PKG_PATH
echo "directory is $(pwd)"
ROMIMAGE=$(ls -1 k230????.img | grep -v "\~" | sort | tail -1)

cd $RAMFS
if [ -z "$ROMIMAGE" ] ; then
    chkerr 5 "Update file not found." 5
    # Check for busybox exit bug.
    if [ $? -ne 0 ] ; then
	exit 5
    fi
fi
echo "Update file : $ROMIMAGE"

echo "vup.sh" > $TARFILELIST
echo "filelist" >> $TARFILELIST
tar -z -x -v -T $TARFILELIST -f $SD_MOUNT_POINT/$PKG_PATH/$ROMIMAGE
chkerr $? "VUP file error!" 8
# Check for busybox exit bug.
if [ $? -ne 0 ] ; then
    exit 8
fi
# Veryfy vup script
md5sum vup.sh | awk '{print $1}' > chksum1
grep "  vup.sh" filelist | awk '{print $1}' > chksum2
cmp_sum chksum1 chksum2
chkerr $? "Check sum error vup.sh" 8
# Check for busybox exit bug.
if [ $? -ne 0 ] ; then
    exit 8
fi
rm -rf chksum1 chksum2 $TARFILELIST

chmod a+x vup.sh

./vup.sh $SD_MOUNT_POINT/$PKG_PATH/$ROMIMAGE
errcode=$?
chkerr $errcode "VUP error!" $errcode
# Check for busybox exit bug.
if [ $? -ne 0 ] ; then
    exit $errcode
fi

disp_end

reboot

exit 0
