
from xml.dom.minidom import parse

import sys


def main( args ):

    file_ = args[1]
    print "Parsing ", file_
    dom = parse( args[1] )
    
    root = dom.childNodes[1]

    groups = []

    for node in root.childNodes:

        print node

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

        output_file = open( "layers/%s.svg" % group, "w" )
        dom.writexml( output_file )
        output_file.close()


if __name__ == "__main__":

    main( sys.argv )

