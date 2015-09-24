# check_natron_update
Tray icon bash script to check natron updates

#Installation
- Simply copy **check_natron_update.sh** in your path (i.e. $HOME/bin)
- Copy the icons **natron22.png** and **natron22.png** in your home icon directory (i.e. $HOME/.icons)

    Open script in an editor to set directory paths at line ~176:

        # Natron install directory
        NATRON_SNAPSHOT_PATH="/Path/to/Natron_Directory"

        # blinking natron icons are installed in ${HOME}/.icons by default
        HOME_ICON_PATH="/Path/to/Natron/icon_Directory"

- If check_natron_update tray icon menu doesn't match your icon theme, you can set the icon at line ~204:

        ## ...If it doesn't match you can uncomment and set your own icons here if it's failed !
        #ICON_INFO=""
        #ICON_RELOAD=""
        #ICON_QUIT=""
        
- Unity Desktop user can set name of natron launcher (line ~184):

        # For Unity Desktop set the name of natron launcher in Unity Dash (without .desktop)
        [ -n $UNITY ] && export DASH_ICON_NAME="Natron2"
        
#Requirements

Just install 'yad' dialog on your system:

        $ sudo apt-get/yum install yad