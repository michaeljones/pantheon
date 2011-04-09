
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
    PVector m_pivot;

    Pivot( PVector pivot, float scale )
    {
        m_pivot = pivot;
        m_scale = scale;
    }

    void setPivot( PVector pivot ) 
    {
        m_pivot = pivot;
    }

    PVector getPivot()
    {
        return m_pivot;
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
            
            int nextIndex = m_index + 1;
            nextIndex = nextIndex % m_points.size();

            PVector start = (PVector)m_points.get( m_index );
            PVector end = (PVector)m_points.get( nextIndex );

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
            m_index += 1;
            m_index = m_index % m_points.size();
            return (PVector)m_points.get( m_index );
        }

        int nextIndex = m_index + 1;
        nextIndex = nextIndex % m_points.size();

        float fraction = m / float( m_interval ); 
        fraction = m_stepper.step( fraction );

        PVector start = (PVector)m_points.get( m_index );
        PVector end = (PVector)m_points.get( nextIndex );

        PVector pos = new PVector( start.x, start.y, start.z );
        PVector dir = new PVector( end.x - start.x, end.y - start.y, end.z - start.z );
        dir.mult( fraction );
        pos.add( dir );

        return pos;
    }


    private SmoothStepper m_stepper;
    private ArrayList m_points;
    private int m_index;
    private int m_time;
    private int m_interval;
    private float m_speed;
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

    void setPivot( float x, float y )
    {
        PVector pos = position();
        m_pivot = new Pivot( new PVector( x, y ), pos.z );
    }

    void transform()
    {
        PVector pos = position();

        translate( width * 0.5 - pos.x, height * 0.5 - pos.y );
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

    void render( PVector pos )
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

    void render( PVector pos )
    {
        if ( pos.z < m_min )
            return;

        shape( m_shape, 0, 0, 1000, 1000 );

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

    void render( PVector pos )
    {
        int length = m_points.size();

        for ( int i=0; i<length; ++i )
        {
            PVector start = (PVector)m_points.get( i );

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

            ellipse( start.x, start.y, 100, 100 );
        }
    }

    private ArrayList m_points;
};


class BoxRenderer extends Renderer
{
    BoxRenderer()
    {
    }

    void render( PVector pos )
    {
        pushStyle();
        noFill();
        // From prior knowledge of the image size
        //
        rect( 0, 0, 1000, 1000 );
        popStyle();
    }

    private PVector m_min;
    private PVector m_max;

};


//
//  RendererGroup
//
class RendererGroup
{
    RendererGroup( ArrayList renderers )
    {
        m_renderers = renderers;
    }

    void render( PVector pos )
    {
        int length = m_renderers.size();

        for ( int i=0; i<length; ++i )
        {
            Renderer renderer = (Renderer)m_renderers.get( i );
            renderer.render( pos );
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
    points.add( new PVector( 500, 700, 2 ) );
    points.add( new PVector( 750, 250, 1 ) );

    // points.add( new PVector( 1307.8401, 1536.8, 1.6400002 ) );
    // points.add( new PVector( 833.7591, 340.87112, 1.0000008 ) );
    // points.add( new PVector( 645.54443, 735.9685, 3.7099988 ) );
    // points.add( new PVector( 1861.031, 200.65875, 2.57 ) );
    // points.add( new PVector( 115.01532, 39.956543, 2.42 ) );
    // points.add( new PVector( 774.5053, -829.63696, 2.7999997 ) );
    // points.add( new PVector( 840.2251, 567.4372, 0.54 ) );

    // Setup motion class
    SmoothStepper stepper = new SmoothStepper();
    Path path = new Path( points, stepper );

    PVector first = path.position();
    Pivot pivot = new Pivot( new PVector( 0, 0 ), first.z );

    motion = new Motion( path, stepper, pivot );

    ArrayList renderers = new ArrayList();
    renderers.add(
            new ShapeRenderer(
                loadShape( "/home/mike/projects/presentations/git/layers/MainTitles.svg" ),
                0, 
                0
                )
            );
    renderers.add(
            new ShapeRenderer(
                loadShape( "/home/mike/projects/presentations/git/layers/History.svg" ),
                2, 
                3
                )
            );
    renderers.add( new BoxRenderer() );
    renderers.add(
            new PathRenderer( points )
            );
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

    // ellipse( 0, 0, 50, 50 );

    rendererGroup.render( motion.position() );
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
        println( "Path point: " + lastDrawn );
    }
    else if ( key == 'z' )
    {
        PVector pos = motion.position();
        println( "Zoom point: " + pos.z );
    }
}


