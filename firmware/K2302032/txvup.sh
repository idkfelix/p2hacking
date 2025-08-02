#!/bin/ash
# ===========================================================
# txvup.sh - TX system controller update script
#  command:
#    txvup.sh
# ===========================================================
# -----------------------------------------------------------
#   Global definitions
# -----------------------------------------------------------
#TX_ROM=k230.bin
#TX_VUPFLAG_START=k230vups.bin
#TX_VUPFLAG_END=k230vupe.bin
PARAM_FILE_TX=param_tx
PARAM_FILE_RX=param_rx


# -----------------------------------------------------------
#   Shell functions
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

	cat $PARAM_FILE_TX
	cat $PARAM_FILE_RX

	exit $errcode
    fi
    return 0
}


# -----------------------------------------------------------
#   Shell Functions
# -----------------------------------------------------------

# mkparam
#  make vupcom parameter file
# 
# $1 : parameter file
# $2 : vupcom command name
# $3 : vupcom param0
# $4 : vupcom param1
#  :
#  :
# $15 : vupcom param13
# 
mkparam()
{
    local counter
    local parameter_file=$1

    # shift parameter
    if [ $# -ne 0 ]; then
	shift 1
    fi

    local command_str=$1
    local command_num=0

    # ƒRƒ}ƒ“ƒh”Ô†‚ðŒˆ’è!
    case "$command_str" in
     "read" )
	command_num=1
	;;
     "write" )
	command_num=2
	;;
     "call" )
	command_num=3
	;;
     "flasherase" )
	command_num=4
	;;
     "flashwrite" )
	command_num=5
	;;
     "ack" )
	command_num=6
	;;
     "nack" )
	command_num=7
	;;
     * )
	command_num=0
	;;
    esac

    rm -rf $parameter_file
    echo "----- Command memory status -----" > $parameter_file
    echo "___command_flag      : 42405" >> $parameter_file
    echo "___unused            : 0" >> $parameter_file
    echo "___command           : $command_num" >> $parameter_file

    # shift parameter
    if [ $# -ne 0 ]; then
	shift 1
    fi

    for counter in 0 1 2 3 4 5 6 7 8 9 ; do
	if [ -n "$1" ]; then
	    param=$1
	else
	    param=0
	fi
	echo "___param[$counter]          : $param" >> $parameter_file
	# shift parameter
	if [ $# -ne 0 ]; then
	    shift 1
	fi
    done
    for counter in 10 11 12 13 ; do
	if [ -n "$1" ]; then
	    param=$1
	else
	    param=0
	fi
	echo "___param[$counter]         : $param" >> $parameter_file
	# shift parameter
	if [ $# -ne 0 ]; then
	    shift 1
	fi
    done

    return 0
}


# -----------------------------------------------------------
#   Main
# -----------------------------------------------------------
#TX VERSION UP
echo "Tx VersionUp Start"

#FLASH WRITE <TX VERSION UP START SIGN>
#ERASE‚Å0xFFFFFFF‚É‚³‚ê‚é‚½‚ß
echo "WRITE VUP SIGN"
vupcom -l $TX_VUPFLAG_START
chkerr $? "Data Writing Error!" 11
vupcom -t flashwrite 0x00000000 0x0017fffc 0x0004
chkerr $? "Command Transmit Error!" 11
mkparam $PARAM_FILE_TX flashwrite $((0x00000000)) $((0x0017fffc)) $((0x0004))
vupcom -r > $PARAM_FILE_RX
chkerr $? "Command Receive Error!" 11
cmp $PARAM_FILE_TX $PARAM_FILE_RX
chkerr $? "Command Error!" 11
#if [ $? -ne 0 ];then
#    echo "***Param differ!!"
#    echo "return status: $?"
#    echo "transmit param:"
#    cat $PARAM_FILE_TX
#    echo "receive param:"
#    cat $PARAM_FILE_RX
#fi


# Erase TX flash
txflashblock=1
while [ $txflashblock -lt 11 ]
do
    # Message
    echo "TX-VUP:Erasing block $txflashblock ..."

    # Flash Erase
    vupcom -t flasherase $txflashblock
    chkerr $? "Flash Erase Error!" 11
    mkparam $PARAM_FILE_TX flasherase $txflashblock
    vupcom -r > $PARAM_FILE_RX
    chkerr $? "Command Receive Error!" 11
    cmp $PARAM_FILE_TX $PARAM_FILE_RX
    chkerr $? "Command Error!" 11
#    if [ $? -ne 0 ];then
#	echo "***Param differ!!"
#	echo "return status: $?"
#	echo "transmit param:"
#	cat $PARAM_FILE_TX
#	echo "receive param:"
#	cat $PARAM_FILE_RX
#    fi
    txflashblock=$(($txflashblock + 1))
done

# Write TX flash
txarea=0
romaddr=$((0x20000))
while [ $txarea -lt 40 ]
do
    # Message
    echo "TX-VUP:Writing area $txarea ..."

    # Flash Write
    dd if=$TX_ROM of=$TX_ROM.$txarea bs=1 count=$((32*1024)) skip=$romaddr > /dev/null 2>&1
    vupcom -l $TX_ROM.$txarea
    chkerr $? "Data Writing Error!" 11
    vupcom -t flashwrite 0x00000000 $romaddr 0x8000
    chkerr $? "Flash Write Error!" 11
    mkparam $PARAM_FILE_TX flashwrite $((0x00000000)) $romaddr $((0x8000))
    vupcom -r > $PARAM_FILE_RX
    chkerr $? "Command Receive Error!" 11
    cmp $PARAM_FILE_TX $PARAM_FILE_RX
    chkerr $? "Command Error!" 11
#    if [ $? -ne 0 ];then
#	echo "***Param differ!!"
#	echo "return status: $?"
#	echo "transmit param:"
#	cat $PARAM_FILE_TX
#	echo "receive param:"
#	cat $PARAM_FILE_RX
#    fi
    
    # Verify
    vupcom -t read $romaddr 0x00000000 0x8000
    chkerr $? "Flash Write Error!" 11
    mkparam $PARAM_FILE_TX read $romaddr $((0x00000000)) $((0x8000))
    vupcom -r > $PARAM_FILE_RX
    chkerr $? "Command Receive Error!" 11
    cmp $PARAM_FILE_TX $PARAM_FILE_RX
    chkerr $? "Command Error!" 11
#    if [ $? -ne 0 ];then
#	echo "***Param differ!!"
#	echo "return status: $?"
#	echo "transmit param:"
#	cat $PARAM_FILE_TX
#	echo "receive param:"
#	cat $PARAM_FILE_RX
#    fi

    echo -n "TX-VUP:Verifing data..."
    vupcom -s $TX_ROM.$txarea.chk
    cmp $TX_ROM.$txarea $TX_ROM.$txarea.chk
    chkerr $? "Data verify error!" 11
    echo "OK"

    # Clean files
    rm -f $TX_ROM.$txarea
    rm -f $TX_ROM.$txarea.chk

    txarea=$(($txarea + 1))
    romaddr=$(($romaddr+32*1024))
done


#FLASH WRITE <TX VERSION UP END SIGN>
echo "FLASH ERASE(BLOCK B) DELETE VUP SIGN"
vupcom -t flasherase 0xb
chkerr $? "Flash Erase Error!" 11
mkparam $PARAM_FILE_TX flasherase $((0xb))
chkerr $? "Command Error!" 11
#if [ $? -ne 0 ];then
#    echo "***Param differ!!"
#    echo "return status: $?"
#    echo "transmit param:"
#    cat $PARAM_FILE_TX
#    echo "receive param:"
#    cat $PARAM_FILE_RX
#fi
vupcom -r > $PARAM_FILE_RX
chkerr $? "Command Receive Error!" 11
cmp $PARAM_FILE_TX $PARAM_FILE_RX
chkerr $? "Command Error!" 11
#if [ $? -ne 0 ];then
#    echo "***Param differ!!"
#    echo "return status: $?"
#    echo "transmit param:"
#    cat $PARAM_FILE_TX
#    echo "receive param:"
#    cat $PARAM_FILE_RX
#fi

echo "Tx VersionUp End"

exit 0
