
from xml.dom.minidom import parse

import sys

class BoundingBox( object ):

    def __init__( self ):

        self.min_ = [ None, None ]
        self.max_ = [ None, None ]

        self.initialised = False

    def expand( self, x, y ):

        if not self.initialised:

            self.min_ = [ x, y ]
            self.max_ = [ x, y ]

            self.initialised = True

        else:

            self.min_[0] = x if x < self.min_[0] else self.min_[0]
            self.min_[1] = y if y < self.min_[1] else self.min_[1]

            self.max_[0] = x if x > self.max_[0] else self.max_[0]
            self.max_[1] = y if y > self.max_[1] else self.max_[1]

def calculate_bounding_box( node, bbox ):

    if node.nodeName == "path":

        d = node.getAttribute( "d" )
        tokens = d.split()

        mode = "abs"
        current_x = 0
        current_y = 0
        last_key = ""
        force_absolute = 1
        skip = 0
        skip_every = 0

        for i, token in enumerate( tokens ):

            if len( token ) == 1:
                last_key = token

                if token in ("C", "c"):
                    skip = 3
                    skip_every = 3
                else:
                    skip_every = 0
                    skip = 0

            if last_key == "m":
                mode = "rel"
            elif last_key == "C":
                mode = "abs"
            elif last_key == "c":
                mode = "rel"
            elif last_key == "l":
                mode = "rel"
            elif last_key == "z":
                pass
            else:
                print "Unknown token: ", last_key

            if len( token ) > 1:

                if skip:
                    print "Skipping", token, skip
                    skip -= 1
                    if skip == 1:
                        skip = skip_every
                    else:
                        continue


                x, y = [float(v) for v in token.split(",")]

                if mode == "abs" or i == force_absolute:

                    current_x = x
                    current_y = y

                    bbox.expand( current_x, current_y )

                elif mode == "rel":

                    current_x += x
                    current_y += y

                    bbox.expand( current_x, current_y )


    for child in node.childNodes:

        calculate_bounding_box( child, bbox )


def remove_fill_opacity( node ):

    if hasattr( node, "hasAttribute" ):
        if node.hasAttribute( "style" ):


            style = node.getAttribute( "style" )
            style = style.replace( "fill-opacity:1;", "" )

            node.setAttribute( "style", style )

    for child in node.childNodes:

        remove_fill_opacity( child )

def main( args ):

    file_ = args[1]
    print "Parsing ", file_
    dom = parse( args[1] )
    
    root = dom.childNodes[1]

    groups = []

    for node in root.childNodes:

        if node.nodeName == "g":

            print "Found group ", node.getAttribute( "inkscape:label" )

            groups.append( node.getAttribute( "inkscape:label" ) )

    for group in groups:

        dom = parse( args[1] )
        root = dom.childNodes[1]

        remove_groups = []

        for node in root.childNodes:

            if node.nodeName == "g":

                label = node.getAttribute( "inkscape:label" )

                if label != group:

                    old_child = root.removeChild( node )
                    old_child.unlink()

                else:

                    node.setAttribute( "id", label )

                    remove_fill_opacity( node )

                    bbox = BoundingBox()
                    calculate_bounding_box( node, bbox )

                    node.setAttribute( "pantheon:bbox_minx", "%s" % bbox.min_[0] )
                    node.setAttribute( "pantheon:bbox_miny", "%s" % bbox.min_[1] )
                    node.setAttribute( "pantheon:bbox_maxx", "%s" % bbox.max_[0] )
                    node.setAttribute( "pantheon:bbox_maxy", "%s" % bbox.max_[1] )
                    

        output_file = open( "layers/%s.svg" % group, "w" )
        dom.writexml( output_file )
        output_file.close()


if __name__ == "__main__":

    main( sys.argv )

