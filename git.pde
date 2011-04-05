
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


class Motion
{
    Motion( Path path, SmoothStepper stepper )
    {
        m_path = path;
        m_stepper = stepper;

        m_pos = new PVector( 0, 0, 1 );
        m_pivot = new PVector( 0, 0, 1 );
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

    void freeMotion()
    {
        if ( m_mode != "free" )
        {
            m_mode = "free";
            PVector position = m_path.position();
            m_pos = new PVector( position.x, position.y, position.z );
        }
    }
    
    void pathMotion()
    {
        if ( m_mode == "free" )
        {
            trigger();
        }
    }

    void adjust( PVector diff )
    {
        m_pos.add( diff );
    }

    void setPosition( PVector pos )
    {
        m_pos = pos;
    }
    
    void scale( float diff )
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

    private Path m_path;
    private SmoothStepper m_stepper;
    private PVector m_pos; 
    private PVector m_pivot;
    private int m_time;
    private String m_mode;
    private float m_speed;
    private int m_interval;
}

class Path
{
    Path( SmoothStepper stepper )
    {
        m_stepper = stepper;

        m_points = new ArrayList();
        m_index = 0;
        m_time = 0;
        m_interval = 1000;
        m_speed = 0.5; // units per millisecond
        m_active = false;
    }
    
    void add( PVector point )
    {
        m_points.add( point );
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


Pivot pivot;
Motion motion;
PShape s;
PVector mouse;

void setup()
{
    size( screen.width, screen.height );

    SmoothStepper stepper = new SmoothStepper();
    Path path = new Path( stepper );
    motion = new Motion( path, stepper );

    path.add( new PVector( 1307.8401, 1536.8, 1.6400002 ) );
    path.add( new PVector( 833.7591, 340.87112, 1.0000008 ) );
    path.add( new PVector( 645.54443, 735.9685, 3.7099988 ) );
    path.add( new PVector( 1861.031, 200.65875, 2.57 ) );
    path.add( new PVector( 115.01532, 39.956543, 2.42 ) );
    path.add( new PVector( 774.5053, -829.63696, 2.7999997 ) );
    path.add( new PVector( 840.2251, 567.4372, 0.54 ) );

    PVector first = path.position();
    pivot = new Pivot( new PVector( 0, 0 ), first.z );

    s = loadShape("/home/mike/projects/presentations/git/images/drawing_export_01.svg");
    smooth();
    shapeMode(CENTER);
}

// 0, 0 is top left.
void draw()
{
    background(204);

    PVector pos = motion.position();

    if ( motion.m_mode != "free" )
    {
        pivot.m_pivot = new PVector( 0, 0 );
        pivot.m_scale = pos.z;
    }

    PVector pivot_ = pivot.m_pivot;
    float scale_ = pivot.m_scale;

    translate( pivot_.x, pivot_.y );

    scale( pos.z, pos.z );

    translate( ( pos.x - pivot_.x ) / scale_, ( pos.y - pivot_.y ) / scale_ );

    // PVector shift = new PVector( pivot_.x - pos.x, pivot_.y - pos.y );
    // translate( shift.x, shift.y );
    // translate( -shift.x, -shift.y );

    shape( s, 0, 0, width, width );
}

void mousePressed()
{
    if ( mouseButton == LEFT )
    {
        cursor( HAND );
    }
    //else if ( mouseButton == RIGHT )
    {
        PVector pos = motion.position();

        PVector oldPivot = pivot.m_pivot;
        float scale_ = pivot.m_scale;
        PVector lastDrawn = new PVector(
                oldPivot.x + ( ( ( pos.x - oldPivot.x ) / scale_ ) * pos.z ),
                oldPivot.y + ( ( ( pos.y - oldPivot.y ) / scale_ ) * pos.z )
                );
        PVector diff = new PVector( lastDrawn.x - pos.x, lastDrawn.y - pos.y );
        motion.adjust( diff );

        pivot = new Pivot( new PVector( mouseX, mouseY ), pos.z );
    }
}

void mouseDragged()
{
    if ( mouseButton == LEFT )
    {
        PVector diff = new PVector( mouseX - pmouseX, mouseY - pmouseY, 0 );
        motion.adjust( diff );
    }
    else if ( mouseButton == RIGHT )
    {
        float diff = mouseX - pmouseX;
        motion.scale( diff / 100.0 );
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
        if ( motion.m_mode == "free" )
        {
            PVector pos = motion.position();
            PVector oldPivot = pivot.m_pivot;
            float scale_ = pivot.m_scale;
            PVector lastDrawn = new PVector(
                    oldPivot.x + ( ( ( pos.x - oldPivot.x ) / scale_ ) * pos.z ),
                    oldPivot.y + ( ( ( pos.y - oldPivot.y ) / scale_ ) * pos.z )
                    );
            
            lastDrawn.z = pos.z;

            motion.setPosition( lastDrawn );
            pivot.m_pivot = new PVector( 0, 0, 0 );
            pivot.m_scale = pos.z;
        }

        motion.trigger();
    }
    else if ( key == 'f' )
    {
        motion.freeMotion();
    }
    else if ( key == 'p' )
    {
        motion.pathMotion();
    }
    else if ( key == 's' )
    {
        PVector pos = motion.position();
        PVector oldPivot = pivot.m_pivot;
        float scale_ = pivot.m_scale;
        PVector lastDrawn = new PVector(
                oldPivot.x + ( ( ( pos.x - oldPivot.x ) / scale_ ) * pos.z ),
                oldPivot.y + ( ( ( pos.y - oldPivot.y ) / scale_ ) * pos.z )
                );

        lastDrawn.z = pos.z;

        println( "Path point: " + lastDrawn );
    }
}


