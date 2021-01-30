#!/bin/bash -e

layers=$(xmlstarlet sel -t -m "//_:svg/_:g" -v "@id" -n all-slides.svg)

for layer in $layers; do
  label=$(xmlstarlet sel -t -m "//_:svg/_:g[@id='$layer']" -v "@inkscape:label" -n all-slides.svg)
  label=$(echo $label | sed 's/ /-/g')
  echo Exporting $layer $label
  inkscape --export-area-page --export-id="$layer" --export-id-only --export-filename="public/layers/$label.svg" --export-type=svg all-slides.svg
done

