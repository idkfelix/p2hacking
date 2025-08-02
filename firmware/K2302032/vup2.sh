#!/bin/ash
# ===========================================================
# vup2.sh - ROM update script
#  command:
#    vup2.sh <VUP file path>
# ===========================================================
# -----------------------------------------------------------
#   Global definitions
# -----------------------------------------------------------
RAMFS=/mnt/ramfs
SD_MOUNT_POINT=/mnt/sdcarda
SD_DEVICE_FILE=/dev/sdcarda1
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
TX_ROM=tx.bin
TX_VUPSCRIPT=txvup.sh
TX_VUPFLAG_START=txvups.bin
TX_VUPFLAG_END=txvupe.bin
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
	grep " $1" filelist  | awk '{print $1}' > chksum2
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
	grep " $1" filelist  | awk '{print $1}' > chksum2
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


# update_tx()
#
#  Update TX system controller.
#
update_tx()
{
	# Extract data
	echo "$TX_ROM" > $TARFILELIST
	echo "$TX_VUPSCRIPT" >> $TARFILELIST
	echo "$TX_VUPFLAG_START" >> $TARFILELIST
	echo "$TX_VUPFLAG_END" >> $TARFILELIST
	tar -z -x -v -T $TARFILELIST -f $ROMIMAGE
	chkerr $? "$1 not found." 9
	# Check for busybox exit bug.
	if [ $? -ne 0 ] ; then
	    exit 9
	fi
	# Veryfy image files
	md5sum $TX_ROM | awk '{print $1}' > chksum1
	grep " $TX_ROM" filelist  | awk '{print $1}' > chksum2
	cmp_sum chksum1 chksum2
	chkerr $? "File checksum error $1" 9
	# Check for busybox exit bug.
	if [ $? -ne 0 ] ; then
	    exit 9
	fi
	md5sum $TX_VUPSCRIPT | awk '{print $1}' > chksum1
	grep " $TX_VUPSCRIPT" filelist  | awk '{print $1}' > chksum2
	cmp_sum chksum1 chksum2
	chkerr $? "File checksum error $1" 9
	# Check for busybox exit bug.
	if [ $? -ne 0 ] ; then
	    exit 9
	fi
	md5sum $TX_VUPFLAG_START | awk '{print $1}' > chksum1
	grep " $TX_VUPFLAG_START" filelist  | awk '{print $1}' > chksum2
	cmp_sum chksum1 chksum2
	chkerr $? "File checksum error $1" 9
	# Check for busybox exit bug.
	if [ $? -ne 0 ] ; then
	    exit 9
	fi
	md5sum $TX_VUPFLAG_END | awk '{print $1}' > chksum1
	grep " $TX_VUPFLAG_END" filelist  | awk '{print $1}' > chksum2
	cmp_sum chksum1 chksum2
	chkerr $? "File checksum error $1" 9
	# Check for busybox exit bug.
	if [ $? -ne 0 ] ; then
	    exit 9
	fi

	# clean files
	rm -rf chksum1 chksum2
	rm -rf $TARFILELIST

	# Run TX VUP script
	chmod a+x $TX_VUPSCRIPT
	export TX_ROM
	export TX_VUPFLAG_START
	export TX_VUPFLAG_END
	./$TX_VUPSCRIPT
	chkerr $? "MTD writing error $1" 11
	# Check for busybox exit bug.
	if [ $? -ne 0 ] ; then
	    exit 11
	fi

	# clean files
	rm -rf $TX_ROM $TX_VUPSCRIPT $TX_VUPFLAG_START $TX_VUPFLAG_END
	rm -rf $TARFILELIST
}

# update_1stbl()
#
#  Update 1st Boot Loader area.
#
update_1stbl()
{
    update_flash $IMG_1STBL $MTD_1STBL
}

# update_2ndbl1()
#
#  Update 2nd Boot Loader 1 area.
#
update_2ndbl1()
{
    update_flash $IMG_2NDBL1 $MTD_2NDBL1
}

# update_2ndbl2()
#
#  Update 2nd Boot Loader 2 area.
#
update_2ndbl2()
{
    update_flash $IMG_2NDBL2 $MTD_2NDBL2
}

# update_kernel()
#
#  Update kernel area.
#
update_kernel()
{
    update_flash $IMG_KERNEL $MTD_KERNEL
}

# update_home()
#
#  Update application(home) area.
#
update_home()
{
    update_flash $IMG_HOME $MTD_HOME
}

# update_rootfs()
#
#  Update root filelistem area.
#
update_rootfs()
{
    update_flash $IMG_ROOTFS $MTD_ROOTFS
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

ROMIMAGE=$1

# Initialize shell
unalias -a

echo "TXROM=$TXROM"

# Extract file list
echo "filelist" > $TARFILELIST
tar -z -x -v -T $TARFILELIST -f $ROMIMAGE
chkerr $? "filelist not found." 9
# Check for busybox exit bug.
if [ $? -ne 0 ] ; then
    exit 9
fi

# Check update flag area
update_flag=$(vupflag g UPDATE)
if [ "$update_flag" -ne "1448431616" ];then
    echo "*** Invalid VUP flag area! Initialize update area."
    vupflag i
    vupflag s BL1 1112493908
    vupflag s BL2 1112493908
    vupflag s UPDATE 1448431616
fi

# Check Bootflag and change sequence of update.
updatearea="tx kernel home rootfs vupkernel vupramdisk"
blupdate=$(echo $updatearea | grep "2ndbl")
if [ -n "$blupdate" ];then
  updatearea="$(echo "$updatearea" | sed "s/2ndbl.//g")"
  blflag=$(vupflag g BL1)
  if [ "$blflag" = "1112493908" ];then
    updatearea="$(echo 2ndbl2 2ndbl1 $updatearea)"
  else
    updatearea="$(echo 2ndbl1 2ndbl2 $updatearea)"
  fi
fi

kill $(pidof vupfb) > /dev/null 2>&1

# Update flash
echo "Update Area:"
echo "  $updatearea"
for update in $updatearea ; do
    case "$update" in 
     "1stbl" )
	update_1stbl
	;;

     "2ndbl1" )
	vupfb m "P2CS_OS1"
	vupfb bp 50 40 1000000 800000 0 &
	vupflag s BL1 0
	update_2ndbl1
	vupflag s BL1 1112493908
	kill $(pidof vupfb) > /dev/null 2>&1
	;;

     "2ndbl2" )
	vupfb m "P2CS_OS1"
	vupfb bp 50 40 1000000 800000 0 &
	vupflag s BL2 0
	update_2ndbl2
	vupflag s BL2 1112493908
	kill $(pidof vupfb) > /dev/null 2>&1
	;;

     "tx" )
	if [ "$TXROM" -eq "0" ];then
	    echo "Update TX Flash."
	    vupfb m "P2SYS"
	    vupfb bp 60 50 1000000 800000 0 &
	    update_tx
	    kill $(pidof vupfb) > /dev/null 2>&1
	else
	    echo "TX's internal program area is ROM. Can't update TX. Skip this process."
	fi
	;;

     "kernel" )
	vupfb m "P2CS_OS2"
	vupfb bp 70 60 1000000 800000 0 &
	update_kernel
	kill $(pidof vupfb) > /dev/null 2>&1
	;;

     "home" )
	vupfb m "P2CS_AP"
	vupfb bp 80 70 1000000 800000 0 &
	update_home
	kill $(pidof vupfb) > /dev/null 2>&1
	;;

     "rootfs" )
	vupfb m "P2CS_OS3"
	vupfb bp 90 80 1000000 800000 0 &
	update_rootfs
	kill $(pidof vupfb) > /dev/null 2>&1
	;;

     "vupkernel" )
#	update_vupkernel
	;;

     "vupramdisk" )
#	update_vupramdisk
	;;

     * )
	echo "*** Error!"
	echo "*** Unknown area name : $update"
	;;
    esac
done

vupfb m "CHECK"
vupfb bp 100 90 1000000 800000 0 &

# Set VUP system boot flag
echo "UPDATE Flag -> OFF ..."
vupflag s UPDATE 0
chkerr $? "VUP Flag Writing Error." 11
# Check for busybox exit bug.
if [ $? -ne 0 ] ; then
    exit 11
fi
echo "UPDATE Flag -> OFF ...OK"

kill $(pidof vupled) > /dev/null 2>&1
kill $(pidof vupfb) > /dev/null 2>&1

exit 0
