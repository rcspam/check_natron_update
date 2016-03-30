#!/bin/bash
# tray-icon app to check update of natron
# Natron Tray Icon blink if it is the case
#
# REQUIREMENTs
# * 'yad' dialog must be installed
# * On ubuntu/unity you must install an 'old school tray' manager to display tray icons:
#   (i.e.: indicator-systemtray-unity see http://www.webupd8.org/2015/05/on-demand-system-tray-for-ubuntu.html) 

### FUNCTIONS/ ###############

# usage
function usage () {
    cat << FIN
${0##*/} [-r version]
    -h : This help.
    -r version : version must 'releases' for the last release
                 or 'snapshots' for the snapshot
                (default: releases)
FIN
}
# quit
function quit () {
    exec 3<> $4 # ${PIPE}
    echo "function quit()" # DEBUG
    # remove tmp files
    for i in $3 $4 $5 # ${BLINK} ${PIPE} ${BLINKING}
    do
	[[ -e $i ]] && rm $i
    done
    if [ -n $UNITY ];then
	exec 4<> $7 # ${LAUNCHER}
	kill $6 # $PID_UPDATE_COUNT_SCRIPT
	exec 4>&-
	rm $7 $8 #${LAUNCHER} ${UPDATE_COUNT_SCRIPT}
    fi
    # quit yad tray
    echo "quit" >&3
    exec 3>&-
    if ps -eo pid | grep -q $1;then
	kill -15 $1 # ${PID}
    fi
    if ps -eo pid | grep -q $2;then
	kill -15 $2 # ${PID_YAD}
    fi
}

# Blink icon function
function tray_clignote () {
	exec 3<> $PIPE
	echo "function tray_clignote()" # DEBUG
	while [ -e $BLINK ] && cat $BLINK | grep -q "1"; do
		echo "icon:${ICON_NATRON_BLINK}" >&3
		sleep 0.5
		echo "icon:${ICON_NATRON}" >&3
		sleep 0.5
	done &
}

# Check commit number
function check_commit () {
    NATRON_SITE="downloads.natron.fr"
    exec 3<> $PIPE
    echo "function check_commit()" # DEBUG
    while ! ping -W 3 -c 1 $NATRON_SITE > /dev/null 2>&1;do
	echo "$NATRON_SITE is unreachable" # DEBUG
	echo tooltip:"Natron Updates\n$NATRON_SITE is unreachable" >&3
	sleep 3
    done
    if uname -m | grep -q x86_64;then
	BIT=64
    else
	BIT=32
    fi
    echo "$NATRON_SITE is UP."
    LOG=$(wget -qO - http://downloads.natron.fr/Linux/${RELEASES}/${BIT}bit/logs/ | grep -e "natron.Linux${BIT}.*\.log" | sed -e 's/^.*href="//' -e 's/">natron.*$//')
    COMMIT=$(wget -qO - http://downloads.natron.fr/Linux/${RELEASES}/${BIT}bit/logs/${LOG} | sed -e '/Building Natron/!d' | cut -d" " -f3 | sed 's/^\(.......\).*/\1/')
    COMMIT_INFO="Commit:  <span color='blue'>${COMMIT}</span>\n\n"
    COMMIT_TEXT="Commit: $(echo ${COMMIT})"
    
    echo "function check_commit(): ${COMMIT_TEXT}" # DEBUG
    echo tooltip:"Natron Updates\n${COMMIT_TEXT}" >&3
}

# check if an update is avalaible
function check () {
    BLINKING=$1
    BLINK=$2
    exec 3<> $PIPE
    echo "function check()" # DEBUG
    check_commit
    if ! $NATRON_CHECK | grep 'no updates' ; then
        # check if already blinking to avoid multiple tray_clignote()
	if cat $BLINKING | grep -q 0;then
	    echo "Start blinking..." # DEBUG
	    echo 1 > $BLINK && tray_clignote && echo 1 > $BLINKING
	else
	    echo "Already blinking..." # DEBUG
	fi
	if [ -n $UNITY ];then
	    exec 4<> $LAUNCHER
	    update_launcher 1 # set flag launcher to 1
	fi
	echo "function check(): Updates are available for Natron ${RELEASES} - ${COMMIT_TEXT}" # DEBUG
	notify-send "NATRON ${RELEASES}" "\nUpdates are available for Natron ${RELEASES}\n${COMMIT_TEXT}" -i "${ICON_NATRON}"
    else
	if [ -n $UNITY ];then
	    exec 4<> $LAUNCHER
	    update_launcher 0 # reset launcher flag 
	fi
	echo "Stop blinking..." # DEBUG	
	echo 0 > ${BLINK} && echo 0 > ${BLINKING} && echo "icon:${ICON_NATRON}" >&3
    fi
}

# read xml from 'NatronSetup --checkupdates'
function read_xml () {
    echo "function read_xm()" >&2 # DEBUG
    while read line
    do
	eval $line
	# set '!' as separator and re-sort date version 
	echo $name! $(echo -n $version | sed -n -e "s%\(....\)\(..\)\(..\)\(..\)\(..\)%\1-\2-\3 \4:\5%p")
    done < <(${NATRON_CHECK} | sed -e '/<update /!d' -e 's/<update //g' -e 's/\/>//g' -e 's/^.*v/v/g')
}

# Display info updates
# wget -qO -  http://downloads.natron.fr/Linux/${RELEASES}/64bit/logs/^Ctron.Linux64.201509241204.log | sed -e '/Building Natron/!d' | cut -d" " -f3
# wget -qO - http://downloads.natron.fr/Linux/${RELEASES}/${bit}bit/logs/ | grep -e "natron.Linux${bit}.*\.log" | sed -e 's/^.*href="//' -e 's/<\/a>.*$//'
function info_update () {
    echo "function info_update()" # DEBUG
    SUF="\n\t\t<big><b>Natron Updates:\n\t\t-------------------------</b></big>\n\n\n"
    #if ! ps aux | grep -v grep | grep "NatronSetup"
    if ! pidof "NatronSetup" >/dev/null
    then
	INFO_TEXT=$(read_xml | awk -F "!" '{printf "<big><b>%s</b></big>  Version %s\n",$1,$2}')
	check_commit
	if cat $BLINK | grep -q "1";then
	    INFO="<big>${SUF}${COMMIT_INFO}${INFO_TEXT}</big>"
	else
	    INFO="<big>${SUF}<span color='red'>\t\tNo Updates for now !</span></big>"
	fi
    else
	INFO="<big>${SUF}<span color='red'>\t\tImpossible to display Infos,\n\t\t'NatronSetup' already running !</span></big>"
    fi
    yad --center --on-top --title="Natron Update Info" --width=425 --height=280 --image="info" --text="${INFO}" --button="Fermer:0"  &
    }

# Warning if yad is not installed
function no_yad () {
    SUF="\n\t<big><b>Natron Updates:\n\t------------------------</b></big>\n\n\n"
    INFO="<big>${SUF}<span color='red'><b>'yad' dialog must be installed</b></span></big>\n\t(yum/apt-get install yad)"
    echo -e "\n${RED}WARNING: yad' dialog must be installed (yum/apt-get install yad)${COL_RAZ}\n"
    if which zenity >/dev/null;then zenity --warning --title="Check Natron Update" --text="${INFO}";fi
    exit 1
}

## USED ONLY BY UBUNTU UNITY/
# update launcher icon
function update_launcher () {
	exec 4<> $LAUNCHER
	#echo send $1 to $LAUNCHER
	echo $1 >&4 # Update count on icon launcher
}
# Create python script on the fly to manage unity 'dash launcher'
function create_python_scripts () {
    cat << EOF > ${UPDATE_COUNT_SCRIPT}
#!/usr/bin/python
# -*- coding: utf-8 -*-

import os, sys, time
from gi.repository import Unity, Gio, GObject, Dbusmenu

launcher_name = sys.argv[1] +".desktop"
loop = GObject.MainLoop()

launcher = Unity.LauncherEntry.get_for_desktop_id (launcher_name)
launcher.set_property("count_visible", True)

def update_line():
	line = sys.stdin.readline()
	while line :
		#print line  # Debug
		ee = int(0)
		line = float(line)
		launcher.set_property("count", line)
		if line :
		    launcher.set_property("urgent", True)
		#Laisse le temps a 'launcher.set_property' d'etre interprete
		context = loop.get_context()
		while context.pending():
			context.iteration(False)
		line = sys.stdin.readline()
	loop.quit()
	return True
		
GObject.idle_add(update_line)
loop.run()
EOF

    chmod +x ${UPDATE_COUNT_SCRIPT} 
}
## /USED ONLY BY UBUNTU UNITY

### /FUNCTIONS ###############


### TRAP ###############
trap 'quit ${PID} ${PID_YAD} ${BLINK} ${PIPE} ${BLINKING} ${PID_UPDATE_COUNT_SCRIPT} ${LAUNCHER} ${UPDATE_COUNT_SCRIPT}'  EXIT
### /TRAP ###############

## OPTIONS
while getopts ":hr:" OPT   # ':' au début, permet de gérer les erreurs
do
    case "${OPT}" in
        h)
            usage
            exit 0
            ;;
        r)
            RELEASES="${OPTARG}"
            ;; 
        :)
            echo "L'option $OPTARG requiert un argument" >&2
            exit 1
            ;;
        \?)
            echo "Option invalide: -$OPTARG" >&2 
            exit 1 
            ;;
    esac
done
shift $((OPTIND-1))
## /OPTIONS

RED="\033[1;31m"
COL_RAZ="\e[0m"

# Check if yad is installed
if ! which yad >/dev/null; then no_yad;fi

# Check if UNITY
echo $XDG_CURRENT_DESKTOP | grep -q -i 'Unity' && export UNITY=1 || export UNITY=0

#### /SETTING #####################################

### USER CONFIGURATION ###############
# Set your paths here
# Natron install directory

# RELEASES could be 'releases' for stable version or 'snapshot' for snapshot version
[[ -z $RELEASES ]] && RELEASES="releases" # if -r doesn't give it
export RELEASES
VERSION=""

#NATRON_PATH="/Path/to/Natron_Directory"
if [[ $RELEASES == "releases" ]]
then
    NATRON_PATH="${HOME}/bin/Natron"
elif [[ $RELEASES == "snapshots" ]]
then
    NATRON_PATH="${HOME}/bin/Natron_snapshot"
else
    usage
    exit 1
fi

# blinking natron icons are installed in ${HOME}/.icons by default
#HOME_ICON_PATH="/Path/to/Natron/icon_Directory"
HOME_ICON_PATH="${HOME}/.icons"

# For Unity Desktop set the name of natron launcher in Unity Dash (without .desktop)
#[ -n $UNITY ] && export DASH_ICON_NAME="Name_Of_Unity_Natron_Dash_Launcher"
[ -n $UNITY ] && export DASH_ICON_NAME="Natron"

## Match your gnome theme
# It should work with most gnome-base system but...
ICON_SIZE=16
ICON_THEME="$(dconf read '/org/gnome/desktop/interface/icon-theme' | tr -d "'")"
if [ -d /usr/share/icons/${ICON_THEME}/actions/${ICON_SIZE}/ ];then
    ICON_PATH_ACTION="/usr/share/icons/${ICON_THEME}/actions/${ICON_SIZE}"
    ICON_PATH_STATUS="/usr/share/icons/${ICON_THEME}/status/${ICON_SIZE}"
elif [ -d /usr/share/icons/${ICON_THEME}/${ICON_SIZE}x${ICON_SIZE}/status/ ];then
    ICON_PATH_ACTION="/usr/share/icons/${ICON_THEME}/${ICON_SIZE}x${ICON_SIZE}/actions"
    ICON_PATH_STATUS="/usr/share/icons/${ICON_THEME}/${ICON_SIZE}x${ICON_SIZE}/status"
fi
# Set the avalaible icon type
[[ -e ${ICON_PATH_STATUS}/info.png ]] && EXT="png" || EXT="svg"
ICON_INFO="${ICON_PATH_STATUS}/info.${EXT}"
ICON_RELOAD="${ICON_PATH_ACTION}/reload.${EXT}"
ICON_QUIT="${ICON_PATH_ACTION}/exit.${EXT}"
## ...If it doesn't match you can uncomment and set your own icons here if it's failed !
#ICON_INFO=""
#ICON_RELOAD=""
#ICON_QUIT=""
### /USER CONFIGURATION ###############

# UNITY
if [ -n $UNITY ];then
    #create FIFO file, to use with send it count update
    export LAUNCHER=$(mktemp -u --tmpdir ${0##*/}_launcher.XXXXXXXX)
    mkfifo $LAUNCHER
    export -f update_launcher
    exec 4<> $LAUNCHER
    # create python scripts on the fly to update dash icon launcher
    export UPDATE_COUNT_SCRIPT="/tmp/count.py"
    create_python_scripts
    ${UPDATE_COUNT_SCRIPT} ${DASH_ICON_NAME} <&4 & export PID_UPDATE_COUNT_SCRIPT=$!
fi
# /UNITY
export NATRON_UPDATER="${NATRON_PATH}/NatronSetup --updater"
export NATRON_CHECK="${NATRON_PATH}/NatronSetup --checkupdates --verbose"
export ICON_NATRON="${HOME_ICON_PATH}/natron22.png"
export ICON_NATRON_BLINK="${HOME_ICON_PATH}/natron22-green.png"
export ICON_NATRON_MENU="${HOME_ICON_PATH}/natron16.png"
export INFO_TEXT=$(${NATRON_CHECK} | sed -e '/fetching metadata of/!d' -e 's/fr.inria.//g' -e 's/"//g' |  awk '{printf "<big><b>%s</b></big>  Version %s\n",$4,$7}')
export -f tray_clignote
export -f check_commit
export -f check
export -f read_xml
export -f info_update
export -f quit
export PID=$$
export LOG COMMIT COMMIT_INFO COMMIT_TEXT
# create FIFO file, tray-icon yad function need it to listening command input
export PIPE=$(mktemp -u --tmpdir ${0##*/}_pipe.XXXXXXXX)
mkfifo $PIPE
exec 3<> $PIPE # attach 'file descriptor' to $PIPE
# vars used to blink tray icon in tray_clignote()
export BLINK="$(mktemp  -u --tmpdir ${0##*/}_blink.XXXXXXXX)"
export BLINKING="$(mktemp  -u --tmpdir ${0##*/}_blinking.XXXXXXXX)"
echo 0 > $BLINKING # start without blinking !!
#### /SETTING #####################################

yad --notification \
    --listen \
    --image="${ICON_NATRON}" \
    --text="Natron updates ${COMMIT_TEXT}" \
    --item-separator ":" \
    --command="bash -c '${NATRON_UPDATER}; check ${BLINKING} ${BLINK}'"  <&3 & export PID_YAD="$!"
#Tray-icon contextual menu  
tray_menu="menu:"
tray_menu_1="Check updates now:bash -c 'check ${BLINKING} ${BLINK}':${ICON_RELOAD}"
tray_menu_2="Launch NatronSetup:bash -c '${NATRON_UPDATER}; check ${BLINKING} ${BLINK}':${ICON_NATRON_MENU}"
tray_menu_3="Updates Info:bash -c 'info_update':${ICON_INFO}"
tray_menu_quit="Quit:bash -c 'quit ${PID} ${PID_YAD} ${BLINK} ${PIPE} ${BLINKING} ${PID_UPDATE_COUNT_SCRIPT} ${LAUNCHER} ${UPDATE_COUNT_SCRIPT}':${ICON_QUIT}"
# Send 'menu' to yad
echo "${tray_menu}|${tray_menu_1}|${tray_menu_2}|${tray_menu_3}|${tray_menu_quit}" >&3

## CHECK based on timeout
## Check update every $TIMEOUT
#TIMEOUT="10h"
#while :
#do
    #check ${BLINKING} ${BLINK} && echo $(date +%H:%M): check done.
    #sleep ${TIMEOUT}
#done

## CHECK based on date(hour)) 
## check at start one time...
sleep 1m
check ${BLINKING} ${BLINK} && echo "1ere verif faite"
##  then... check each days at $DATE_VERIF
DATE_NOW=""
DATE_VERIF=2200
while :
do
    [[ $DATE_NOW == $DATE_VERIF ]] && check ${BLINKING} ${BLINK} && echo $DATE_NOW: check done
    sleep 30 # low than the 1 minute
    DATE_NOW=$(date +%H%M)
done
