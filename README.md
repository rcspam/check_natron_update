#Tray icon bash script to check natron snapshot updates.

#### When snapshot updates are available:

![natron_blink](https://cloud.githubusercontent.com/assets/10021906/10069708/2f133234-62ae-11e5-9474-18d31b218ffa.gif) Tray icon blinks.

Tooltip tells you the commit available (or installed if icon is not blinking):

![screenshot1](https://cloud.githubusercontent.com/assets/10021906/10073794/b0b3b7e2-62cb-11e5-8303-b8609d28a2c8.png)

Unity Desktop: A count flag is add on the Natron launcher:

![selection_001](https://cloud.githubusercontent.com/assets/10021906/10069997/03ce4710-62b0-11e5-9162-f12d2cf422c4.png)

####Left Click: 
Launch 'NatronSetup --updater'

####Right Click Menu:
![screenshot3](https://cloud.githubusercontent.com/assets/10021906/10069704/2731ad20-62ae-11e5-9e56-03736b3c4725.png)

#Installation
- Simply copy **check_natron_update.sh** in your path (i.e. $HOME/bin)
- Copy the icons **natron22.png**, **natron22.png**, **natron16.png** in your home icon directory (i.e. $HOME/.icons)

- Open script in an editor to set directory paths at line ~176:

        # Natron install directory
        NATRON_SNAPSHOT_PATH="/Path/to/Natron_Directory"

        # blinking natron icons are installed in ${HOME}/.icons by default
        HOME_ICON_PATH="/Path/to/Natron/icon_Directory"

# Match your icon theme if needed
- If check_natron_update tray icon menu doesn't match your icon theme, you can set the icon at line ~204:

        ## ...If it doesn't match you can uncomment and set your own icons here if it's failed !
        #ICON_INFO=""
        #ICON_RELOAD=""
        #ICON_QUIT=""

# Unity Desktop Users
- Unity Desktop user can set name of natron launcher (line ~184):

        # For Unity Desktop set the name of natron launcher in Unity Dash (without .desktop)
        [ -n $UNITY ] && export DASH_ICON_NAME="Natron2"
        
#Requirements

Just install 'yad' dialogue on your system:

        $ sudo apt-get/yum install yad
