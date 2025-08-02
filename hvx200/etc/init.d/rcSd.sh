### rcS.d scripts

## checkroot.sh
mount -n /proc

## mountall.sh
mount -at  noproc
kill -USR1 1

## mkvar.sh (Panasonic original)
mkdir -p /var/log /var/lib /var/lib/pcmcia /var/lock /var/lock/subsys /var/run /var/tmp

# sticky bit
chmod 1777 /var/tmp

# for GUI
: > /var/log/.p2

## hostname.sh
hostname -F /etc/hostname

# bootmisc.sh
: > /var/run/utmp
chmod 664 /var/run/utmp
chgrp utmp /var/run/utmp
