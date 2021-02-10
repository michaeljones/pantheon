#!/bin/bash -e

layers=$(xmlstarlet sel -t -m "//_:svg/_:g" -v "@id" -n all-slides.svg)

mkdir -p build
rm -f build/layers

for layer in $layers; do
  label=$(xmlstarlet sel -t -m "//_:svg/_:g[@id='$layer']" -v "@inkscape:label" -n all-slides.svg)
  label=$(echo $label | sed 's/ /-/g')
  echo $label >> build/layers
done

cat build/layers  | jq  --raw-input .  | jq --slurp . > src/names.json

for layer in $layers; do
  label=$(xmlstarlet sel -t -m "//_:svg/_:g[@id='$layer']" -v "@inkscape:label" -n all-slides.svg)
  label=$(echo $label | sed 's/ /-/g')
  params=$(inkscape --query-id $layer --query-x --query-y --query-width --query-height all-slides.svg)

  x=$(echo $params | cut -d ' ' -f 1)
  y=$(echo $params | cut -d ' ' -f 2)
  width=$(echo $params | cut -d ' ' -f 3)
  height=$(echo $params | cut -d ' ' -f 4)
  posX=$(python -c "print int($x + $width/2)")
  posY=$(python -c "print int($y + $height/2)")
  echo ", ( \"$label\", { x = $posX, y = $posY } )"
  inkscape --export-area-page --export-id="$layer" --export-id-only --export-filename="public/layers/$label.svg" --export-type=svg all-slides.svg
done

