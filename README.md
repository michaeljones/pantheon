# Pantheon

Pantheon is a presentation tool where the slides are laid out on a single "canvas" in an SVG file
and then the tool moves from slide to slide and allows for click & drag panning around the canvas.

The SVG is expected to be authored using Inkscape and a shell script is used to extract an SVG per
layer and find the bounding box which can then be manually fed into the presentation tool which is
an Elm app that runs in the browser.

## Dependencies

- Inkscape
- jq
- xmlstarlet

## Usage

1. Create your slides in inkscape with one slide per layer.
2. Run `./export-layers.sh` on the svg file to create one svg per layer/slide. The script also prints out
   bounding box centers for each layer/slide.
3. Copy the outputted bounding box centers into the `src/Main.elm` file into the list that is used
   to build the 'positions' dictionary.
4. Run `elm-app start --no-debug` to build & run the elm-app in your browser.
5. Use left & right arrows to navigate between slides and click & drag with the mouse to move
   around.
