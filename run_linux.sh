#!/bin/bash

# Modern Linux version of Strzalki Physics Simulation
# Uses Free Pascal with PTC graphics backend

echo "Strzalki Physics Simulation - Modern Linux Version"
echo "Compiling..."

# Compile the program
fpc Strzalki.pas
if [ $? -ne 0 ]; then
    echo "Compilation failed!"
    exit 1
fi

echo "Running Strzalki..."
echo ""
echo "Controls:"
echo "  a/z - Set launch angle (±10°)"
echo "  s/d - Set initial velocity (±10 m/s)"
echo "  Mouse Movement - Set launch position"
echo "  Left Mouse Click - Launch projectile"
echo "  ESC - Exit program"
echo ""
echo "Features:"
echo "  - Real-time animated projectile"
echo "  - Physics-based trajectory simulation"
echo "  - Interactive mouse controls"
echo "  - 16-color VGA graphics"
echo ""
echo "Click on the graphics window to interact!"
echo "Press Ctrl+C to exit"
echo ""

# Run the program
./Strzalki
