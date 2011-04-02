
Path path = new Path();
PShape s;

void setup()
{
    size( screen.width, screen.height );

    path.add( new PVector( -200, 100, 2 ) );
    path.add( new PVector( 0, -450, 1 ) );
    path.add( new PVector( 20, 10, 1 ) );

    s = loadShape("/home/mike/projects/presentations/git/images/drawing_export_01.svg");
    smooth();
}

// 0, 0 is top left.
void draw()
{
    background(204);

    PVector pos = path.position();

    translate( pos.x, pos.y );
    scale( pos.z, pos.z );

    shape( s, 0, 0, width, width );
}

void keyPressed()
{
    if ( key == 'q' )
    {
        exit();
    }
    else if ( key == ' ' )
    {
        path.trigger();
    }
}


class Path
{
    ArrayList m_points;
    int m_index;
    int m_time;
    int m_interval;
    float m_speed;
    boolean m_active;


    Path()
    {
        m_points = new ArrayList();
        m_index = 0;
        m_time = 0;
        m_interval = 1000;
        m_speed = 0.1; // units per millisecond
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
            println( m_interval + " " + distance +  " " + m_speed );
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

        PVector start = (PVector)m_points.get( m_index );
        PVector end = (PVector)m_points.get( nextIndex );

        PVector pos = new PVector( start.x, start.y, start.z );
        PVector dir = new PVector( end.x - start.x, end.y - start.y, end.z - start.z );
        dir.mult( fraction );
        pos.add( dir );

        return pos;
    }
}

