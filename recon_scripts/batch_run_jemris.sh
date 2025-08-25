#!/bin/bash

# Set paths
TEMP_DIR=$(python3 -c 'import tempfile; print(tempfile.gettempdir())')
SIMU_XML="simu.xml"
JEMRIS_EXEC="./build/src/jemris"

# Check if simu.xml exists
if [[ ! -f "$SIMU_XML" ]]; then
    echo "simu.xml not found in current directory."
    exit 1
fi

# Ensure temp directory exists
if [[ ! -d "$TEMP_DIR" ]]; then
    echo "Temp directory not found: $TEMP_DIR"
    exit 1
fi

# Find all *_flip*.xml files in /tmp and sort them
XML_FILES=$(find "$TEMP_DIR" -maxdepth 1 -type f -name '*_flip*.xml' | sort -V)

if [[ -z "$XML_FILES" ]]; then
    echo "No *_flip*.xml files found in $TEMP_DIR"
    exit 1
fi

# Run simulations for each XML file
for XML_PATH in $XML_FILES; do
    XML_BASENAME=$(basename "$XML_PATH")
    ANGLE=$(echo "$XML_BASENAME" | grep -oP 'flip\K\d+')

    echo "Updating simu.xml for FlipAngle = $ANGLE ..."
    matlab -nosplash -nodesktop -r "update_simu_xml('$XML_PATH'); exit"

    echo "Running simulation for FlipAngle = $ANGLE ..."
    $JEMRIS_EXEC simu.xml

    OUTPUT_FILE="result_flip${ANGLE}.h5"
    if [[ -f signals_ismrmrd.h5 ]]; then
        mv signals_ismrmrd.h5 "$OUTPUT_FILE"
        echo "✅ Saved result to $OUTPUT_FILE"
    else
        echo "⚠️  Warning: signals_ismrmrd.h5 not found for FlipAngle = $ANGLE"
    fi
done

