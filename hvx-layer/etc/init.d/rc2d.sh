#! /bin/sh
#

###
### Merge scripts of syslog, klog and pcmcia for fast bootup.
###  by Panasonic 2005/08/31

##
## /etc/init.d/sysklogd: start the system log daemon.
##
## chkconfig: 2345 10 90
##

#PATH=/bin:/usr/bin:/sbin:/usr/sbin

binpath_syslog=/sbin/syslogd
binpath_klog=/sbin/klogd

# Options for start/restart the daemons
#   For remote UDP logging use SYSLOGD="-r"
#
#SYSLOGD=""
#  Panasonic original: for ROM 2005/05/30
SYSLOGD="-p /var/dev-log"

#  Use KLOGD="-k /boot/System.map-$(uname -r)" to specify System.map
#
KLOGD=""

start-stop-daemon --start --quiet --exec $binpath_syslog -- $SYSLOGD
start-stop-daemon --start --quiet --exec $binpath_klog -- $KLOGD


##
## pcmcia
##

. /lib/modules/2.4.20_mvl31-ms7751rse01-sh_sh4_le/pcmcia-config/pcmcia

/sbin/modprobe pcmcia_core
/sbin/modprobe i82365 irq_mode=0
/sbin/modprobe ds
/sbin/modprobe cb_enabler
/sbin/modprobe spd_mod > /dev/null 2>&1
#	/sbin/cardmgr -q -c /lib/modules/`uname -r`/pcmcia-config
/sbin/cardmgr -q -c /lib/modules/2.4.20_mvl31-ms7751rse01-sh_sh4_le/pcmcia-config
: > /var/lock/subsys/pcmcia

exit 0
