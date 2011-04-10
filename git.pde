
//
//   SmoothStepper
//
class SmoothStepper
{
    SmoothStepper() {}

    float step( float fraction )
    {
        if ( fraction < 0 ) return 0;
        if ( fraction > 1 ) return 1;
    
        if ( fraction < 0.5 ) 
            return ( fraction * 2 ) * ( fraction * 2 ) * 0.5;
    
        return 1 - ( fraction - 1 ) * ( fraction * 2 - 2 );
    }
};

//
//  Pivot
//
class Pivot
{
    float m_scale;
    PVector m_pos;

    Pivot( PVector pos, float scale )
    {
        m_pos = pos;
        m_scale = scale;
    }

    void setPos( PVector pos ) 
    {
        m_pos = pos;
    }

    PVector getPos()
    {
        return m_pos;
    }

}


//
//  Path
//
class Path
{
    Path( ArrayList points, SmoothStepper stepper )
    {
        m_points = points;
        m_stepper = stepper;

        m_index = 0;
        m_nextIndex = m_index + 1;
        m_progress = m_index;
        m_time = 0;
        m_interval = 1000;
        m_speed = 0.1; // units per millisecond
        m_active = false;
    }
    
    void trigger()
    {
        if ( ! m_active )
        {
            m_active = true;
            m_time = millis();
            
            m_nextIndex = m_index + 1;
            m_nextIndex = m_nextIndex % m_points.size();

            PVector start = (PVector)m_points.get( m_index );
            PVector end = (PVector)m_points.get( m_nextIndex );

            float distance = start.dist( end );

            m_interval = round( distance / m_speed );
        }
    }

    void goback()
    {
        if ( ! m_active )
        {
            m_active = true;
            m_time = millis();
            
            m_nextIndex = m_index - 1;
            while ( m_nextIndex < 0 )
            {
                m_nextIndex = m_points.size() + m_nextIndex;
            }

            m_nextIndex = m_nextIndex % m_points.size();

            PVector start = (PVector)m_points.get( m_index );
            PVector end = (PVector)m_points.get( m_nextIndex );

            float distance = start.dist( end );

            m_interval = round( distance / m_speed );
        }
    }

    PVector position()
    {
        if ( ! m_active ) 
        {
            return (PVector)m_points.get( m_index );
        }

        int m = millis() - m_time;

        if ( m > m_interval )
        {
            m_active = false;
            m_time = 0;
            m_index = m_nextIndex;
            m_progress = m_index;
            return (PVector)m_points.get( m_index );
        }

        float fraction = m / float( m_interval ); 
        fraction = m_stepper.step( fraction );

        PVector start = (PVector)m_points.get( m_index );
        PVector end = (PVector)m_points.get( m_nextIndex );

        int sign = m_index < m_nextIndex ? 1 : -1;

        PVector pos = new PVector( start.x, start.y, start.z );
        PVector dir = new PVector( end.x - start.x, end.y - start.y, end.z - start.z );
        dir.mult( fraction );
        pos.add( dir );

        m_progress = m_index + sign * fraction;

        return pos;
    }

    float progress()
    {
        return m_progress;
    }


    private SmoothStepper m_stepper;
    private ArrayList m_points;
    private int m_index;
    private int m_nextIndex;
    private int m_time;
    private int m_interval;
    private float m_speed;
    private float m_progress;
    private boolean m_active;

}

//
//  Motion
//
class Motion
{
    Motion( Path path, SmoothStepper stepper, Pivot pivot )
    {
        m_path = path;
        m_stepper = stepper;
        m_pivot = pivot;

        m_pos = new PVector( 0, 0, 1 );
        m_mode = "path";
        m_speed = 0.5; // units per millisecond
        m_interval = 0;
    }

    void trigger()
    {
        if ( m_mode == "path" )
        {
            m_path.trigger();
            return;
        }
        
        m_mode = "restore";
        m_time = millis();

        PVector start = m_pos;
        PVector end = m_path.position();

        float distance = start.dist( end );
        m_interval = round( distance / m_speed );
    }

    void goback()
    {
        if ( m_mode == "path" )
        {
            m_path.goback();
            return;
        }
        
        m_mode = "restore";
        m_time = millis();

        PVector start = m_pos;
        PVector end = m_path.position();

        float distance = start.dist( end );
        m_interval = round( distance / m_speed );
    }

    void free()
    {
        if ( m_mode != "free" )
        {
            m_mode = "free";
            PVector position = m_path.position();
            m_pos = new PVector( position.x, position.y, position.z );
        }
    }
    
    void path()
    {
        if ( m_mode == "free" )
        {
            trigger();
        }
    }

    void adjust( PVector diff )
    {
        diff.div( position().z );
        m_pos.add( diff );
    }

    void setPosition( PVector pos )
    {
        m_pos = pos;
    }
    
    void scale_( float diff )
    {
        m_pos.z += diff;
        if ( m_pos.z < 0.1 ) 
        {
            m_pos.z = 0.1;
        }
    }

    PVector position()
    {
        if ( m_mode == "path" )
        {
            return m_path.position();
        }
        else if ( m_mode == "restore" )
        {
            int m = millis() - m_time;

            if ( m > m_interval )
            {
                m_time = 0;
                m_mode = "path";
                return m_path.position();
            }

            float fraction = m / float( m_interval ); 
            fraction = m_stepper.step( fraction );

            PVector start = m_pos;
            PVector end = m_path.position();

            PVector pos = new PVector( start.x, start.y, start.z );
            PVector dir = new PVector( end.x - start.x, end.y - start.y, end.z - start.z );
            dir.mult( fraction );
            pos.add( dir );

            return pos;
        }
        else if ( m_mode == "free" )
        {
            return m_pos;
        }

        return new PVector();
    }

    float progress()
    {
        return m_path.progress();
    }

    void setPivot( float x, float y )
    {
        PVector pos = position();
        m_pivot = new Pivot( new PVector( x, y ), pos.z );
    }

    void transform()
    {
        PVector pos = position();

        // Translate the desired point to the centre of the screen
        // 
        translate( width * 0.5 - pos.x, height * 0.5 - pos.y );

        // Scale it appropriately
        //
        // translate( m_pivot.m_pos.x, m_pivot.m_pos.y );
        translate( pos.x, pos.y );
        scale( pos.z, pos.z );
        translate( - pos.x, - pos.y );
    }


    private Path m_path;
    private SmoothStepper m_stepper;
    private Pivot m_pivot;

    private PVector m_pos; 
    private int m_time;
    private String m_mode;
    private float m_speed;
    private int m_interval;
}

class Renderer
{
    Renderer() {}

    void render( PVector pos, float progress, float opacity )
    {
        // Base class
    }
};

class ShapeRenderer extends Renderer
{
    ShapeRenderer( String name, PShape shape, PVector min, PVector max )
    {
        m_name = name;
        m_shape = shape;
        m_min = min;
        m_max = max;
    }

    void render( PVector pos, float progress, float opacity )
    {
        /*
        if ( pos.z < m_min )
        {
            return;
        }

        */

        shape( m_shape, 0, 0, 1300, 700 );

        if ( opacity < 1.0 )
        {
            pushStyle();
            noStroke();
            // noFill();
            fill( 204, ( 1 - opacity ) * 255 );
            rect( m_min.x, m_min.y, m_max.x-m_min.x, m_max.y-m_min.y );
            popStyle();
        }
    }

    private String m_name;
    private PShape m_shape;
    private PVector m_min;
    private PVector m_max;
};


//
//  PathRenderer
//
class PathRenderer extends Renderer
{
    PathRenderer( ArrayList points )
    {
        m_points = points;
    }

    void render( PVector pos, float progress, float opacity )
    {
        int length = m_points.size();

        for ( int i=0; i<length; ++i )
        {
            PVector start = (PVector)m_points.get( i );

            int ni = ( i + 1 ) % m_points.size();
            PVector end = (PVector)m_points.get( ni );

            line( start.x, start.y, end.x, end.y );
            ellipse( start.x, start.y, 10, 10 );
            text( i, start.x + 10, start.y + 5 );
        }
    }

    private ArrayList m_points;
};


class BoxRenderer extends Renderer
{
    BoxRenderer()
    {
    }

    void render( PVector pos, float progress, float opacity )
    {
        pushStyle();
        noFill();
        // From prior knowledge of the image size
        //
        rect( 0, 0, 1300, 700 );
        popStyle();
    }

    private PVector m_min;
    private PVector m_max;

};

class ProgressRenderer extends Renderer
{
    ProgressRenderer( Renderer renderer, float start, float end )
    {
        m_renderer = renderer;
        m_start = start;
        m_end = end;

    }

    void render( PVector pos, float progress, float opacity )
    {
        if ( progress > m_start - 1 && progress < m_end + 1 )
        {
            if ( progress < m_start )
            {
                opacity *= 1 - ( m_start - progress );
            }
            else if ( progress > m_end )
            {
                opacity *= 1 - ( progress - m_end );
            }

            // Rendering with very small values eg. 1.2E-7 seems to ignore the
            // opacity (ie. use 1.0 instead) which is possibly due to how svg
            // expects small numbers to be expressed. So we skip small numbers,
            // seems to look smooth enough
            //
            if ( opacity > 0.01 )
            {
                m_renderer.render( pos, progress, opacity );
            }
        }
    }

    private Renderer m_renderer;
    private float m_start;
    private float m_end;

}

class RendererFactory
{
    RendererFactory( PApplet applet )
    {
        m_applet = applet;
    }

    Renderer create( String name, String dir, float start, float end )
    {
        XMLElement rootElement = new XMLElement( m_applet, dir + name + ".svg" );

        XMLElement group = rootElement.getChild( "g" );

        PVector min = new PVector( group.getFloatAttribute( "pantheon:bbox_minx" ), group.getFloatAttribute( "pantheon:bbox_miny" ) );
        PVector max = new PVector( group.getFloatAttribute( "pantheon:bbox_maxx" ), group.getFloatAttribute( "pantheon:bbox_maxy" ) );

        return new ProgressRenderer(
                new ShapeRenderer(
                    name,
                    loadShape( dir + name + ".svg" ),
                    min,
                    max
                    ),
                start,
                end
                );
    }

    private PApplet m_applet;

}


//
//  RendererGroup
//
class RendererGroup
{
    RendererGroup( ArrayList renderers )
    {
        m_renderers = renderers;
    }

    void render( PVector pos, float progress, float opacity )
    {
        int length = m_renderers.size();

        for ( int i=0; i<length; ++i )
        {
            Renderer renderer = (Renderer)m_renderers.get( i );
            renderer.render( pos, progress, opacity );
        }
    }

    private ArrayList m_renderers;
};



Motion motion;
RendererGroup rendererGroup;

void setup()
{
    size( screen.width, screen.height );

    //  Set up points
    //
    ArrayList points = new ArrayList();
    points.add( new PVector( 623.5175, 224.72202, 4.329994 ) );
    points.add( new PVector( 685.61896, 425.41565, 1.680002 ) );
    points.add( new PVector( 696.79114, 378.42313, 8.520003 ) );
    points.add( new PVector( 668.59937, 420.08487, 13.430008 ) );
    points.add( new PVector( 664.57837, 464.83505, 14.37003 ) );
    points.add( new PVector( 647.5173, 509.6207, 22.659988 ) );
    points.add( new PVector( 646.85535, 533.8915, 22.659988 ) );
    points.add( new PVector( 643.79565, 557.2828, 28.770012 ) );
    points.add( new PVector( 961.0682, 493.00897, 4.809995 ) );
    points.add( new PVector( 1026.3641, 452.95395, 3.1999934 ) );
    points.add( new PVector( 1007.879, 352.9385, 3.159989 ) );
    points.add( new PVector( 858.6685, 359.65283, 10.0399885 ) );
    points.add( new PVector( 923.0111, 303.87592, 10.0399885 ) );
    points.add( new PVector( 1069.6257, 303.47742, 10.0399885 ) );
    points.add( new PVector( 1149.7898, 366.66336, 8.369962 ) );
    points.add( new PVector( 1165.8252, 509.99844, 7.1899567 ) );
    points.add( new PVector( 955.94965, 553.948, 7.1899567 ) );
    points.add( new PVector( 399.71906, 450.54413, 4.9899526 ) );
    points.add( new PVector( 313.02524, 446.65668, 3.5799475 ) );
    points.add( new PVector( 262.937, 324.4504, 9.639954 ) );
    points.add( new PVector( 229.63808, 300.07257, 9.639954 ) );
    points.add( new PVector( 227.35577, 255.2591, 9.639954 ) );

    // Node Building
    /* 22 */ points.add( new PVector( 471.15045, 178.68713, 5.099945 ) );
    /* 23 */ points.add( new PVector( 471.15045, 178.68713, 5.099945 ) );
    /* 24 */ points.add( new PVector( 471.15045, 178.68713, 5.099945 ) );
    /* 25 */ points.add( new PVector( 471.15045, 178.68713, 5.099945 ) );
    /* 26 */ points.add( new PVector( 471.15045, 178.68713, 5.099945 ) );
    /* 27 */ points.add( new PVector( 471.15045, 178.68713, 5.099945 ) );
    /* 28 */ points.add( new PVector( 471.15045, 178.68713, 5.099945 ) );
    /* 29 */ points.add( new PVector( 471.15045, 178.68713, 5.099945 ) );
    /* 30 */ points.add( new PVector( 664.4871, 133.19649, 5.099945 ) );
    /* 31 */ points.add( new PVector( 730.56696, 133.00035, 5.099945 ) );
    /* 32 */ points.add( new PVector( 834.0974, 131.43175, 5.099945 ) );
    /* 33 */ points.add( new PVector( 1022.5326, 132.80426, 5.099945 ) );
    /* 34 */ points.add( new PVector( 1022.5326, 132.80426, 5.099945 ) );
    /* 35 */ points.add( new PVector( 1022.5326, 132.80426, 5.099945 ) );

    points.add( new PVector( 214.43503, 444.9296, 7.5941863 ) );
    points.add( new PVector( 149.58963, 402.8285, 16.554186 ) );
    points.add( new PVector( 69.428474, 435.20712, 16.554186 ) );
    points.add( new PVector( 92.20217, 502.5614, 16.554186 ) );
    points.add( new PVector( 206.81107, 443.43393, 6.9241886 ) );
    points.add( new PVector( 391.09256, 523.58765, 6.9241886 ) );
    points.add( new PVector( 201.76584, 522.6061, 15.3441925 ) );
    points.add( new PVector( 229.87027, 592.23364, 13.414194 ) );
    points.add( new PVector( 279.07193, 633.8318, 15.0142 ) );
    points.add( new PVector( 378.71066, 646.6857, 15.0142 ) );
    points.add( new PVector( 455.09586, 616.63806, 16.084202 ) );
    points.add( new PVector( 673.52435, 319.73032, 1.0542002 ) );

    // Setup motion class
    SmoothStepper stepper = new SmoothStepper();
    Path path = new Path( points, stepper );

    PVector first = path.position();
    Pivot pivot = new Pivot( new PVector( 0, 0 ), first.z );

    motion = new Motion( path, stepper, pivot );

    String root = "/home/mike/projects/presentations/git/layers/";

    ArrayList renderers = new ArrayList();
    RendererFactory rendererFactory = new RendererFactory( this );
    renderers.add( rendererFactory.create( "History", root, 2, 8 ) );
    renderers.add( rendererFactory.create( "UI", root, 10, 15 ) );
    renderers.add( rendererFactory.create( "Weaknesses", root, 9, 17 ) );
    renderers.add( rendererFactory.create( "InternalStructure", root, 19, 1000 ) );
    renderers.add( rendererFactory.create( "EditHistory", root, 19, 1000 ) );
    renderers.add( rendererFactory.create( "UsefulCommands", root, 19, 1000 ) );
    renderers.add( rendererFactory.create( "Strengths", root, 18, 1000 ) );
    renderers.add( rendererFactory.create( "MainTitles", root, 1, 1000 ) );
    renderers.add( rendererFactory.create( "Git", root, 0, 0 ) );

    renderers.add( rendererFactory.create( "NodeBuildingBlob1", root, 23, 100 ) );
    renderers.add( rendererFactory.create( "NBTextBlob1", root, 23, 23 ) );

    renderers.add( rendererFactory.create( "NodeBuildingBlob2", root, 24, 100 ) );
    renderers.add( rendererFactory.create( "NBTextBlob2", root, 24, 24 ) );

    renderers.add( rendererFactory.create( "NodeBuildingTree1", root, 25, 100 ) );
    renderers.add( rendererFactory.create( "NBTextTree1", root, 25, 25 ) );

    renderers.add( rendererFactory.create( "NodeBuildingBlob3", root, 26, 100 ) );
    renderers.add( rendererFactory.create( "NBTextBlob3", root, 26, 26 ) );

    renderers.add( rendererFactory.create( "NodeBuildingTree2", root, 27, 100 ) );
    renderers.add( rendererFactory.create( "NBTextTree2", root, 27, 27 ) );

    renderers.add( rendererFactory.create( "NodeBuildingCommit1", root, 28, 100 ) );
    renderers.add( rendererFactory.create( "NBTextCommit1", root, 28, 28 ) );

    renderers.add( rendererFactory.create( "NodeBuildingCommit2", root, 29, 100 ) );
    renderers.add( rendererFactory.create( "GraphBuilding1", root, 30, 100 ) );
    renderers.add( rendererFactory.create( "GraphBuilding2", root, 31, 100 ) );
    renderers.add( rendererFactory.create( "GraphBuilding3", root, 32, 100 ) );
    renderers.add( rendererFactory.create( "Branches1", root, 33, 100 ) );
    renderers.add( rendererFactory.create( "Branches2", root, 34, 100 ) );
    renderers.add( rendererFactory.create( "Tags", root, 35, 100 ) );

    // renderers.add( new ProgressRenderer( new BoxRenderer(), 0, 1000 ) );
    // renderers.add( new ProgressRenderer( new PathRenderer( points ), 0, 1000 ) );
    rendererGroup = new RendererGroup( renderers );

    // Rendering settings
    //
    smooth();
    // shapeMode(CENTER);
}

// 0, 0 is top left.
void draw()
{
    background(204);

    // ellipse( 0, 0, 50, 50 );

    motion.transform();

    float progress = motion.progress();

    // ellipse( 0, 0, 50, 50 );

    rendererGroup.render( motion.position(), progress, 1.0 );
}

void mousePressed()
{
    if ( mouseButton == LEFT || mouseButton == RIGHT )
    {
        cursor( HAND );
        motion.setPivot( mouseX, mouseY );
    }
}

void mouseDragged()
{
    if ( mouseButton == LEFT )
    {
        PVector diff = new PVector( pmouseX - mouseX, pmouseY - mouseY, 0 );
        motion.adjust( diff );
    }
    else if ( mouseButton == RIGHT )
    {
        float diff = mouseX - pmouseX;
        motion.scale_( diff / 100.0 );
    }
}

void mouseReleased()
{
    cursor( ARROW );
}

void keyPressed()
{
    if ( key == CODED )
    {

    }
    else
    {
        if ( key == 'q' )
        {
            exit();
        }
        else if ( key == ' ' )
        {
            // Reset motion position and scale to remove pivot 
            //
            // motion.reset();
            motion.trigger();
        }
        else if ( key == 'b' )
        {
            motion.goback();
        }
        else if ( key == 'f' )
        {
            motion.free();
        }
        else if ( key == 'p' )
        {
            motion.path();
        }
        else if ( key == 's' )
        {
            PVector lastDrawn = motion.position();
            println( "points.add( new PVector( " + lastDrawn.x + ", " + lastDrawn.y + ", " + lastDrawn.z + " ) );" );
        }
        else if ( key == 'z' )
        {
            PVector pos = motion.position();
            println( "Zoom point: " + pos.z );
        }
    }
}


