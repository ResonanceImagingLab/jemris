#!/bin/bash
# A script to run a JEMRIS simulation for a single flip angle

# Set paths
TEMP_DIR=$(python3 -c 'import tempfile; print(tempfile.gettempdir())') # Get the system temporary directory
SIMU_XML="simu.xml" # Path to the main simulation configuration file
JEMRIS_EXEC="./build/src/jemris" # Path to the JEMRIS executable

# Get flip angle argument (expect exactly one argument)
if [ $# -ne 1 ]; then
    echo "Usage: $0 <flip_angle>"
    exit 1
fi

ANGLE=$1 # Save the flip angle argument
XML_FILE="gre_flip${ANGLE}.xml" # Construct the expected XML filename based on the flip angle
XML_PATH="$TEMP_DIR/$XML_FILE" # Full path to the flip-specific XML in the temp directory

# Check if the specified XML exists
if [[ ! -f "$XML_PATH" ]]; then
    echo "Error: File $XML_PATH not found."
    exit 1
fi

# Check if simu.xml exists
if [[ ! -f "$SIMU_XML" ]]; then
    echo "simu.xml not found in current directory."
    exit 1
fi


# === Update simu.xml ===
# Use MATLAB helper function to update simu.xml so it points to the flip-specific XML
echo "Updating simu.xml for FlipAngle = $ANGLE ..."
matlab -nosplash -nodesktop -r "update_simu_xml('$XML_PATH'); exit"

# === Run JEMRIS simulation ===
echo "Running simulation for FlipAngle = $ANGLE ..."
$JEMRIS_EXEC simu.xml

# === Save output ===
# Rename the result file with the flip angle embedded in the filename
OUTPUT_FILE="result_flip${ANGLE}.h5"
if [[ -f signals_ismrmrd.h5 ]]; then
    mv signals_ismrmrd.h5 "$OUTPUT_FILE"
    echo "✅ Saved result to $OUTPUT_FILE"
else
    echo "⚠️ Warning: signals_ismrmrd.h5 not found for FlipAngle = $ANGLE"
fi
