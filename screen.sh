#!/bin/bash

# Save terminal settings
# saved_settings=$(stty -g)

# Switch to alternate screen
echo -ne "\033[?1049h"

# Hide cursor
tput civis

# Get terminal size
cols=$(tput cols)
rows=$(tput lines)

# Draw dots
for ((row=0; row<rows; row++)); do
    for ((col=0; col<cols; col++)); do
        tput cup $row $col
        echo -n "."
    done
done

# Pause to view
sleep 1

# Restore terminal
echo -ne "\033[?1049l"   # Exit alternate screen
tput cnorm               # Show cursor
# stty "$saved_settings"
