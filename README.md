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
- Simply copy **check_natron_update.sh** in your $PATH (i.e. $HOME/bin)

- Set its executable flag:

        $ chmod +x $HOME/bin/check_natron_update.sh

- Copy the icons **natron22.png**, **natron22.png**, **natron16.png** in your home icon directory (i.e. $HOME/.icons)

- Open script in an editor to set directory paths for your release install and the snapshot release at line ~256:

        # Natron install directory
        NATRON_PATH="/Path/to/Natron_Directory"   
 and your natron icon path if it's necessary at line ~269
 
        # blinking natron icons are installed in ${HOME}/.icons by default
        HOME_ICON_PATH="/Path/to/Natron/icon_Directory"

- Copy **check_natron_update.desktop** or **check_natron_update_snapshot.desktop** in your ~/.config/autostart or/and if you are a kde user to ~/.kde/autostart. You can change the

# Usage
  to check stable release:
  
        $ check_natron_update.sh -r releases
  or to check snapshot release:
  
        $ check_natron_update.sh -r snapshots
        

# Match your icon theme if needed
- If check_natron_update tray icon menu doesn't match your icon theme, you can set the icon at line ~293:

        ## ...If it doesn't match you can uncomment and set your own icons here if it's failed !
        #ICON_INFO=""
        #ICON_RELOAD=""
        #ICON_QUIT=""

# Unity Desktop Users
- You must install a standard tray icon manager (i.e. [indicator-systemtray-unity](https://github.com/GGleb/indicator-systemtray-unity))
- Unity Desktop user can set name of natron launcher (line ~273):

        # For Unity Desktop set the name of natron launcher in Unity Dash (without .desktop)
        [ -n $UNITY ] && export DASH_ICON_NAME="Natron"
        
#Requirements

Just install 'yad' dialogue on your system:

        $ sudo apt-get/yum install yad
