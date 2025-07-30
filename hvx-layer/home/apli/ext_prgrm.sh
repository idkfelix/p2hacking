#!/bin/ash
######################################################################
# FILENAME  : ext_prgrm.sh
# COPYRIGHT :
# DIVISION  : Panasonic AVCN Co.,Ltd.
# AUTHOR    : Original Wasai Michio
#           : Modify   Koji Sakurai (sakurai.kj@jp.panasonic.com)
# COMMENT   : Start ext maintanance script
# LANGUAGE  : BASH script
# REVISION  : $Revision: 1.1 $
# DATE      : $Date: 2005-10-17 05:21:05 $
# CREATED   : 2004/06/02, 2005/10/14
#####################################################################
# $Header: /cvsroots/p2pf/src/bin/sg/ext_prgrm.sh,v 1.1 2005-10-17 05:21:05 sakurai Exp $
######################################################################
#
SD_MOUNT_POINT=/mnt/sdcarda
SD_DEVICE_FILE=/dev/sdcarda1
PKG_PATH=PRIVATE/MEIGROUP/PAVCN/SBG/P2SD/MNTNC

######################################################################
# FUNCTION      : err_exit
# INPUT         : error code
# RETURN        :
# NOTE          : 
# AUTHOR        : Wasai
# CREATED       : 2004/02/23
#####################################################################
err_exit () {
    cd /
    umount $SD_MOUNT_POINT

    exit $1
}
######################################################################
# FUNCTION      : MAIN
# INPUT         : 
# RETURN        :
# NOTE          : 
# AUTHOR        : Wasai 
# CREATED       : 2004/06/02
#####################################################################
##
## Start External Prog.
##
echo "Start external program."

##
## Mount SD card
##
modprobe sdcard > /dev/null 2>&1
mount -t msdos $SD_DEVICE_FILE $SD_MOUNT_POINT -o noatime 2>&1
#modprobe sdcard >& /dev/null
#mount $SD_DEVICE_FILE $SD_MOUNT_POINT -o noatime 2>&1
if [ $? -ne 0 ] ; then
    echo "SD card error!"
    err_exit 6
fi
echo "SD mount O.K."

##
## Check program  package on SD card.
##
cd $SD_MOUNT_POINT/$PKG_PATH
filename=$(find . -name "*.sh" | tail -1)
if [ -z $filename ] ; then
    echo "Ext program file not found."
    err_exit 5
fi
echo "Ext program file found:"$filename

##
## Execute external program 
##
$SD_MOUNT_POINT/$PKG_PATH/$filename
if [ $? -ne 0 ] ; then
    echo "File execute error!"
    err_exit 8
fi

##
## Mount SD card
##
cd
umount $SD_MOUNT_POINT

##
## End External Prog.
##
echo "Ext program End Exit"
exit 0

