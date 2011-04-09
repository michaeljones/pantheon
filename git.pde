
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
        m_nextIndex = 1;
        m_progress = m_index;
        m_time = 0;
        m_interval = 1000;
        m_speed = 0.5; // units per millisecond
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

        PVector pos = new PVector( start.x, start.y, start.z );
        PVector dir = new PVector( end.x - start.x, end.y - start.y, end.z - start.z );
        dir.mult( fraction );
        pos.add( dir );

        m_progress = m_index + fraction;

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





// //
// //  Context
// //
// class Context
// {
//     Context( Motion motion, Pivot pivot )
//     {
//         m_motion = motion;
//         m_pivot = pivot;
//     }
// 
//     PVector position()
//     {
//         return m_motion.position();
//         /*
//         PVector pos = m_motion.position();
//         PVector oldPivot = m_pivot.m_pivot;
//         float scale_ = m_pivot.m_scale;
//         PVector lastDrawn = new PVector(
//                 oldPivot.x + ( ( ( pos.x - oldPivot.x ) / scale_ ) * pos.z ),
//                 oldPivot.y + ( ( ( pos.y - oldPivot.y ) / scale_ ) * pos.z )
//                 );
// 
//         lastDrawn.z = pos.z;
// 
//         return lastDrawn;
//         */
//     }
// 
//     void reset()
//     {
//         if ( m_motion.m_mode == "free" )
//         {
//             PVector pos = position();
//             m_motion.setPosition( pos );
// 
//             m_pivot.m_pivot = new PVector( 0, 0, 0 );
//             m_pivot.m_scale = pos.z;
//         }
//     }
// 
//     void trigger()
//     {
//         m_motion.trigger();
//     }
// 
//     void freeMotion()
//     {
//         m_motion.freeMotion();
//     }
// 
//     void pathMotion()
//     {
//         m_motion.pathMotion();
//     }
// 
//     void setPivot( float x, float y )
//     {
//         reset();
// 
//         PVector pos = position();
// 
//         m_pivot = new Pivot( new PVector( x, y ), pos.z );
//     }
// 
//     void resetPivot()
//     {
//         if ( m_motion.m_mode != "free" )
//         {
//             m_pivot.m_pivot = new PVector( 0, 0 );
//             PVector pos = position();
//             m_pivot.m_scale = pos.z;
//         }
//     }
// 
//     float scale_()
//     {
//         return m_motion.position().z;
//     }
// 
//     void scale_( float scale )
//     {
//         m_motion.scale( scale );
//     }
// 
//     void adjust( PVector diff )
//     {
//         diff.div( m_motion.position().z );
//         m_motion.adjust( diff );
//     }
// 
//     private Motion m_motion;
//     private Pivot m_pivot;
// 
// };

class Renderer
{
    Renderer() {}

    void render( PVector pos, float progress )
    {
        // Base class
    }
};

class ShapeRenderer extends Renderer
{
    ShapeRenderer( PShape shape, float minZoom, float maxZoom )
    {
        m_shape = shape;
        m_min = minZoom;
        m_max = maxZoom;
    }

    void render( PVector pos, float progress )
    {
        if ( pos.z < m_min )
            return;

        shape( m_shape, 0, 0, 1300, 700 );

        if ( pos.z < m_max )
        {
            SmoothStepper stepper = new SmoothStepper();
            float p = ( pos.z - m_min ) / ( m_max - m_min );
            p = stepper.step( p );
            int alpha = (int)( p * 255 );

            /*
            pushStyle();

            fill( 204, alpha );
            rect( 0, 0, 1000, 1000 );

            popStyle();
            */
        }
    }

    private PShape m_shape;
    private float m_min;
    private float m_max;
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

    void render( PVector pos, float progress )
    {
        int length = m_points.size();

        for ( int i=0; i<length; ++i )
        {
            PVector start = (PVector)m_points.get( i );

            int ni = ( i + 1 ) % m_points.size();
            PVector end = (PVector)m_points.get( ni );


            line( start.x, start.y, end.x, end.y );

            // PVector scaledStart = new PVector( ((width*0.5) - start.x ) / start.z, ((height*0.5) - start.y) / start.z );

            /*
            println( "size: " + width + " " + height );
            println( "start: " + start );
            println( "scaledStart: " + scaledStart );
            */

            /*
            println( "1: " + scaledStart );

            scaledStart.div( pos.z );
            // scaledStart.add( new PVector( - pos.x, - pos.y ) );

            println( "2: " + scaledStart );

            scaledStart.add( new PVector( ( width * 0.5 ) / pos.z, ( height * 0.5 )/ pos.z )  );

            println( "3: " + scaledStart );
            // scaledStart.add( new PVector( 500, 500 ) );
            // scaledStart.div( start.z );
            */

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

    void render( PVector pos, float progress )
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

    void render( PVector pos, float progress )
    {
        if ( progress >= m_start && progress < m_end )
        {
            m_renderer.render( pos, progress );
        }
    }

    private Renderer m_renderer;
    private float m_start;
    private float m_end;

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

    void render( PVector pos, float progress )
    {
        int length = m_renderers.size();

        for ( int i=0; i<length; ++i )
        {
            Renderer renderer = (Renderer)m_renderers.get( i );
            renderer.render( pos, progress );
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
    points.add( new PVector( 250.59225, 203.70271, 9.639954 ) );
    points.add( new PVector( 394.3395, 248.79552, 8.649942 ) );
    points.add( new PVector( 287.92484, 140.04407, 11.389942 ) );
    points.add( new PVector( 393.59293, 234.21753, 8.759929 ) );
    points.add( new PVector( 332.0628, 90.49504, 8.759929 ) );
    points.add( new PVector( 411.5864, 209.46683, 6.309916 ) );
    points.add( new PVector( 493.7483, 59.024517, 6.4999185 ) );
    points.add( new PVector( 417.771, 193.51091, 5.45991 ) );

    // Setup motion class
    SmoothStepper stepper = new SmoothStepper();
    Path path = new Path( points, stepper );

    PVector first = path.position();
    Pivot pivot = new Pivot( new PVector( 0, 0 ), first.z );

    motion = new Motion( path, stepper, pivot );

    String root = "/home/mike/projects/presentations/git/layers/";

    ArrayList renderers = new ArrayList();
    renderers.add( new ProgressRenderer( new ShapeRenderer( loadShape( root + "Git.svg" ), 0, 0 ), 0, 1 ) );
    renderers.add( new ProgressRenderer( new ShapeRenderer( loadShape( root + "MainTitles.svg" ), 0, 0 ), 1, 1000 ) );
    renderers.add( new ProgressRenderer( new ShapeRenderer( loadShape( root + "History.svg" ), 0, 0 ), 2, 8 ) );
    renderers.add( new ProgressRenderer( new ShapeRenderer( loadShape( root + "Weaknesses.svg" ), 0, 0), 9, 17 ) );
    renderers.add( new ProgressRenderer( new ShapeRenderer( loadShape( root + "UI.svg" ), 0, 0 ), 10, 15 ) );
    renderers.add( new ProgressRenderer( new ShapeRenderer( loadShape( root + "Strengths.svg" ), 0, 0 ), 18, 1000 ) );
    renderers.add( new ProgressRenderer( new ShapeRenderer( loadShape( root + "InternalStructure.svg" ), 0, 0 ), 19, 1000 ) );
    renderers.add( new ProgressRenderer( new ShapeRenderer( loadShape( root + "EditHistory.svg" ), 0, 0 ), 19, 1000 ) );
    renderers.add( new ProgressRenderer( new ShapeRenderer( loadShape( root + "UsefulCommands.svg" ), 0, 0 ), 19, 1000 ) );
    renderers.add( new ProgressRenderer( new BoxRenderer(), 0, 1000 ) );
    renderers.add( new ProgressRenderer( new PathRenderer( points ), 0, 1000 ) );
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

    rendererGroup.render( motion.position(), progress );
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


