#!/bin/bash

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
get_controls

# Source Device Info
source $controlfolder/device_info.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"

# Set variables
GAMEDIR="/$directory/ports/soniccd"
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

cd $GAMEDIR

# Exports
export LD_LIBRARY_PATH="$GAMEDIR/libs":$LD_LIBRARY_PATH
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

# Permissions
$ESUDO chmod 666 /dev/tty0
$ESUDO chmod 666 /dev/tty1
$ESUDO chmod 777 $GAMEDIR/soniccd

# Modify ScreenWidth
LOW=214 # 3:2
MED=320 # 4:3
HIGH=426 # 16:9

# Set WIDTH based on DISPLAY_WIDTH
case $DISPLAY_WIDTH in
  [0-3][0-9][0-9])  # 0 to 399 range
    WIDTH=$LOW
    ;;
  [4-9][0-9][0-9])  # 400 to 999 range
    WIDTH=$MED
    ;;
  [1-9][0-9][0-9][0-9])  # 1000 and above range
    WIDTH=$HIGH
    ;;
  *)
    echo "Unknown screen width: $DISPLAY_WIDTH"
    WIDTH=$MED  # Default value or handle as needed
    ;;
esac

if grep -q "^ScreenWidth=[0-9]\+" "$GAMEDIR/settings.ini"; then
    sed -i "s/^ScreenWidth=[0-9]\+/ScreenWidth=$WIDTH/" "$GAMEDIR/settings.ini"
else
    echo "Possible invalid or missing settings.ini!" > $CUR_TTY
fi

# Run the game
echo "Loading, please wait!" > $CUR_TTY
$GPTOKEYB "soniccd" -c "sonic.gptk" &
./soniccd

$ESUDO kill -9 $(pidof gptokeyb)
$ESUDO systemctl restart oga_events &
printf "\033c" > /dev/tty1