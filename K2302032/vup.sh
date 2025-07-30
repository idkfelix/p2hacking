#!/bin/ash
# ===========================================================
# vup.sh - Update VUP Area and VUP Flag
#  command:
#    vup.sh <VUP file path>
# ===========================================================
# -----------------------------------------------------------
#   Global definitions
# -----------------------------------------------------------
RAMFS=/mnt/ramfs
SD_MOUNT_POINT=/mnt/sdcarda
PKG_PATH=PRIVATE/MEIGROUP/PAVCN/SBG/P2SD/FW
IMG_VUPKERNEL=vmlinux-vup.bin
MTD_VUPKERNEL=/dev/mtd6
IMG_VUPRAMDISK=ramdisk.gz
MTD_VUPRAMDISK=/dev/mtd7
TARFILELIST=tarfilelist
BS=4096

# -----------------------------------------------------------
#   Functions
# -----------------------------------------------------------

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
	exit $errcode
    fi
    return 0
}

# get_filesize()
#
#  Print file size.
#
#  $1 : filename
#
get_filesize() {
    ls -l $1 | awk '{print $5}'
}

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

# update_flash()
#
#  Update MTD partition.
#
#   $1 : flash image file
#   $2 : flash partition
#
update_flash()
{
	# Extract data
	echo "$1" > $TARFILELIST
	tar -z -x -v -T $TARFILELIST -f $ROMIMAGE
	chkerr $? "$1 not found." 9
	# Check for busybox exit bug.
	if [ $? -ne 0 ] ; then
	    exit 9
	fi
	# Veryfy image files
	md5sum $1 | awk '{print $1}' > chksum1
	grep $1 filelist  | awk '{print $1}' > chksum2
	cmp_sum chksum1 chksum2
	chkerr $? "File checksum error $1" 9
	# Check for busybox exit bug.
	if [ $? -ne 0 ] ; then
	    exit 9
	fi
	# clean files
	rm -rf chksum1 chksum2
	rm -rf $TARFILELIST

	# Write data
	eraseall $2
	chkerr $? "eraseall failed $2" 10
	# Check for busybox exit bug.
	if [ $? -ne 0 ] ; then
	    exit 10
	fi
	cp $1 $2
	chkerr $? "MTD writing error $1" 11
	# Check for busybox exit bug.
	if [ $? -ne 0 ] ; then
	    exit 11
	fi

	# Veryfy data
	echo "Verifing data..."
	filesize=$(get_filesize $1)
	block_count=$(($filesize/$BS))
	dd if=$2 bs=$BS count=$block_count > $1.chk
	dd if=$2 bs=1 count=$(($filesize-$block_count*$BS)) skip=$(($block_count*$BS)) >> $1.chk
	md5sum $1.chk | awk '{print $1}' > chksum1
	grep $1 filelist  | awk '{print $1}' > chksum2
	cmp_sum chksum1 chksum2
	chkerr $? "Check sum error $MTD_VUPKERNE" 11
	# Check for busybox exit bug.
	if [ $? -ne 0 ] ; then
	    exit 11
	fi
	echo "OK."

	# clean files
	rm -rf $1 $1.chk
	rm -rf chksum1 chksum2
	rm -rf $TARFILELIST

	return 0
}

# update_vupkernel()
#
#  Update VUP kernel area.
#
update_vupkernel()
{
    update_flash $IMG_VUPKERNEL $MTD_VUPKERNEL
}

# update_vupramdisk()
#
#  Update VUP ramdisk area.
#
update_vupramdisk()
{
    update_flash $IMG_VUPRAMDISK $MTD_VUPRAMDISK
}


# -----------------------------------------------------------
#   Main
# -----------------------------------------------------------

# Initialize shell
unalias -a

# Get ROM image file path
ROMIMAGE=$(echo $1 | sed "s#\.\/##g")

# Check VUP file path
## It matches the new file search processing result?
## (for K230 VUP file searching problem.)

# New file search process.
cd $SD_MOUNT_POINT/$PKG_PATH
echo "directory is $(pwd)"
CHECK_IMAGE=$SD_MOUNT_POINT/$PKG_PATH/$(ls -1 k230????.img | grep -v "\~" | sort | tail -1 | sed "s#\.\/##g")

echo "It matches the new file search processing result?"
echo " ROMIMAGE:"
echo "   $ROMIMAGE"
echo " CHECK_IMAGE:"
echo "   $CHECK_IMAGE"
if [ "$ROMIMAGE" != "$CHECK_IMAGE" ] ; then
    chkerr 5 "Update file not found." 5
    # Check for busybox exit bug.
    if [ $? -ne 0 ] ; then
	exit 5
    fi
fi
echo "Update file : $ROMIMAGE"

cd $RAMFS

# Extract file list
echo "filelist" > $TARFILELIST
tar -z -x -v -T $TARFILELIST -f $ROMIMAGE
chkerr $? "filelist not found." 9
# Check for busybox exit bug.
if [ $? -ne 0 ] ; then
    exit 9
fi
rm -f $TARFILELIST

# Update flash area
for update in tx kernel home rootfs vupkernel vupramdisk ; do
    case "$update" in 
     "tx" )
	;;
     "1stbl" )
	;;
     "2ndbl1" )
	;;
     "2ndbl2" )
	;;
     "kernel" )
	;;
     "home" )
	;;
     "rootfs" )
	;;

     "vupkernel" )
	update_vupkernel
	;;

     "vupramdisk" )
	update_vupramdisk
	;;

     * )
	echo "*** Error!"
	echo "*** Unknown area name : $update"
	;;
    esac
done

# Set VUP system boot flag
echo "UPDATE Flag -> ON ..."
vupflag s UPDATE 1448431616
chkerr $? "VUP Flag Writing Error." 11
# Check for busybox exit bug.
if [ $? -ne 0 ] ; then
    exit 11
fi
echo "UPDATE Flag -> ON ...OK"

sync
sleep 3

exit 0
