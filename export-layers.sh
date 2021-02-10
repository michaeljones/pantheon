#!/bin/bash -e

inputSvgFile=$1

if [ -z "$inputSvgFile" ]; then
	echo "Usage: export-layers.sh <svg file>"
	exit 1
fi

layers=$(xmlstarlet sel -t -m "//_:svg/_:g" -v "@id" -n $inputSvgFile)

mkdir -p build
rm -f build/layers

for layer in $layers; do
  label=$(xmlstarlet sel -t -m "//_:svg/_:g[@id='$layer']" -v "@inkscape:label" -n $inputSvgFile)
  label=$(echo $label | sed 's/ /-/g')
  echo $label >> build/layers
done

cat build/layers | jq --raw-input . | jq --slurp . > src/names.json

focusPointsFile="build/slide-focus-points"
rm -f $focusPointsFile

mkdir -p public/layers

for layer in $layers; do
  label=$(xmlstarlet sel -t -m "//_:svg/_:g[@id='$layer']" -v "@inkscape:label" -n $inputSvgFile)
  label=$(echo $label | sed 's/ /-/g')
  params=$(inkscape --query-id $layer --query-x --query-y --query-width --query-height $inputSvgFile)

  x=$(echo $params | cut -d ' ' -f 1)
  y=$(echo $params | cut -d ' ' -f 2)
  width=$(echo $params | cut -d ' ' -f 3)
  height=$(echo $params | cut -d ' ' -f 4)
  posX=$(python -c "print int($x + $width/2)")
  posY=$(python -c "print int($y + $height/2)")
  # Write a json object per slide into the file
  echo "{ \"name\": \"$label\", \"position\": { \"x\": $posX, \"y\": $posY } }" >> $focusPointsFile
  inkscape --export-area-page --export-id="$layer" --export-id-only --export-filename="public/layers/$label.svg" --export-type=svg $inputSvgFile
done

# Read one-per-line json objects from file and output as json array
cat $focusPointsFile | jq . | jq --slurp . > src/focus-points.json
