### execute application for MontaVista Linux Pro. 3.1
##   by Panasonic

#########################
# preload drivers       #
# set environment value #
#########################
. /etc/p2pfenv

ulimit -c 0

#####################
# application start #
#####################
cd /var
/home/apli/sg &
