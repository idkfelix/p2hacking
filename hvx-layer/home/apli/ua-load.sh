#!/bin/sh

# note: no argument test
insmod /home/usb/scullp.o \
	buf0_bus_addr=$5 buf0_size=$1 \
	buf1_bus_addr=$4 buf1_size=$1 \
	buf2_bus_addr=$3 buf2_size=$1 \
	buf3_bus_addr=$2 buf3_size=$1
RET=$?
if test 0 -ne $RET; then
	exit 255
fi

insmod /lib/modules/2.4.20_mvl31-ms7751rse01-sh_sh4_le/kernel/drivers/usb/gadget/net2280.o
RET=$?
if test 0 -ne $RET; then
	exit 255
fi

insmod /home/usb/g_ms.o
RET=$?
if test 0 -ne $RET; then
	exit 255
fi

exit 0
