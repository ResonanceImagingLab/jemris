#!/bin/bash

# Set paths
TEMP_DIR=$(python3 -c 'import tempfile; print(tempfile.gettempdir())')
SIMU_XML="simu.xml"
JEMRIS_EXEC="./build/src/jemris"

# Get flip angle argument (e.g., 30 → gre_flip30.xml)
if [ $# -ne 1 ]; then
    echo "Usage: $0 <flip_angle>"
    exit 1
fi

ANGLE=$1
XML_FILE="gre_flip${ANGLE}.xml"
XML_PATH="$TEMP_DIR/$XML_FILE"

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

echo "Updating simu.xml for FlipAngle = $ANGLE ..."
matlab -nosplash -nodesktop -r "update_simu_xml('$XML_PATH'); exit"

echo "Running simulation for FlipAngle = $ANGLE ..."
$JEMRIS_EXEC simu.xml

OUTPUT_FILE="result_flip${ANGLE}.h5"
if [[ -f signals_ismrmrd.h5 ]]; then
    mv signals_ismrmrd.h5 "$OUTPUT_FILE"
    echo "✅ Saved result to $OUTPUT_FILE"
else
    echo "⚠️ Warning: signals_ismrmrd.h5 not found for FlipAngle = $ANGLE"
fi
