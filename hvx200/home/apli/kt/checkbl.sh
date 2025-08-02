#!/bin/ash
# ===========================================================
# checkbl.sh - Bootloader check script
#  command:
#    checkbl.sh
# ===========================================================
# -----------------------------------------------------------
#   Global definitions
# -----------------------------------------------------------
RAMFS=/mnt/ramfs
IMG_1STBL=netboot-1st.binary
MTD_1STBL=/dev/mtd0
IMG_2NDBL1=netboot1.binary
MTD_2NDBL1=/dev/mtd1
IMG_2NDBL2=netboot2.binary
MTD_2NDBL2=/dev/mtd2
IMG_KERNEL=vmlinux.bin
MTD_KERNEL=/dev/mtd3
IMG_HOME=home.image
MTD_HOME=/dev/mtd4
IMG_ROOTFS=rootfs.image
MTD_ROOTFS=/dev/mtd5
IMG_VUPKERNEL=vmlinux-vup.bin
MTD_VUPKERNEL=/dev/mtd6
IMG_VUPRAMDISK=ramdisk.gz
MTD_VUPRAMDISK=/dev/mtd7
TARFILELIST=tarfilelist
ROMLIST=/etc/romlist
BS=4096
BLFLAG_ENABLE=1112493908
BMP_PATH=/usr/lib/p16
BMP_START=update_title.p16
BMP_END=update_end_title.p16
BMP_ERROR=update_error_title.p16

# -----------------------------------------------------------
#   Functions
# -----------------------------------------------------------

# disp_end()
#
#  Display VUP end screen.
#
disp_end()
{
    # Extract data
    zcat $BMP_PATH/$BMP_END.gz > $BMP_END
    vupfb f $BMP_END
    rm -f $BMP_END
    vupfb m "BL OK"
}

# disp_error()
#
#  Display error message.
#
disp_error()
{
    # Extract data
    zcat $BMP_PATH/$BMP_ERROR.gz > $BMP_ERROR
    vupfb f $BMP_ERROR
    rm -f $BMP_ERROR
    vupfb m "BL ERROR"
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
	echo "*** BL check error !!! ***"
	echo $errmsg
	disp_error
	cd /
	umount $RAMFS
	exit $errcode
    fi
    return 0
}

# cmp_sum()
#
#  Compare checksum text file.
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

# check_flash()
#
#  Update MTD partition.
#
#   $1 : flash image file
#   $2 : flash partition
#
check_flash()
{
	# Veryfy data
	echo "Verifing data..."
	filesize=$(grep " $1$" $ROMLIST | awk '{print $1}')
	block_count=$(($filesize/$BS))
	dd if=$2 bs=$BS count=$block_count > $1.chk
	dd if=$2 bs=1 count=$(($filesize-$block_count*$BS)) skip=$(($block_count*$BS)) >> $1.chk
	md5sum $1.chk | awk '{print $1}' > chksum1
	grep " $1$" $ROMLIST | awk '{print $2}' > chksum2
	cmp_sum chksum1 chksum2
	chkerr $? "Check sum error $2" 1
	# Check for busybox exit bug.
	if [ $? -ne 0 ] ; then
	    exit 1
	fi
	echo "OK."

	# clean files
	rm -rf $1.chk
	rm -rf chksum1 chksum2

	return 0
}


# -----------------------------------------------------------
#   Main
# -----------------------------------------------------------

# Initialize shell
unalias -a
mount -t ramfs ramfs $RAMFS
cd $RAMFS

check_flash $IMG_2NDBL1 $MTD_2NDBL1
chkerr $? "Check sum error 2ndBL1" 1
# Check for busybox exit bug.
if [ $? -ne 0 ] ; then
    exit 1
fi

check_flash $IMG_2NDBL2 $MTD_2NDBL2
chkerr $? "Check sum error 2ndBL2" 1
# Check for busybox exit bug.
if [ $? -ne 0 ] ; then
    exit 1
fi

# Check BL1 flag
bl1_flag=$(vupflag g BL1)
echo "BL1 flag: $bl1_flag"
if [ "$bl1_flag" -ne "$BLFLAG_ENABLE" ] ; then
    echo "BL1 flag error : $bl1_flag"
    echo "Set BL1 flag value. : $BLFLAG_ENABLE"
    vupflag s BL1 $BLFLAG_ENABLE
fi

# Check BL2 flag
bl2_flag=$(vupflag g BL2)
echo "BL2 flag: $bl2_flag"
if [ "$bl2_flag" -ne "$BLFLAG_ENABLE" ] ; then
    echo "BL2 flag error : $bl2_flag"
    echo "Set BL2 flag value. : $BLFLAG_ENABLE"
    vupflag s BL2 $BLFLAG_ENABLE
fi

echo "Bootloader area check : OK."

disp_end

cd /
umount $RAMFS

exit 0
