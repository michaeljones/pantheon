
Path path = new Path();
PShape s;

void setup()
{
    size( 800, 600, P3D );

    path.add( new PVector( 0, 0, 0 ) );
    path.add( new PVector( 0, 50, 0 ) );
    path.add( new PVector( 20, 10, 0 ) );

    s = loadShape("/home/mike/projects/presentations/git/images/drawing_export_01.svg");
    smooth();
}

// 0, 0 is top left.
void draw()
{
    background(204);

    PVector eye = new PVector( width/2, height/2, 2000 );
    PVector centre = new PVector( width/2, height/2, 0 );
    PVector up = new PVector( 0, 1, 0 );
    
    float fov = PI/3.0;
    float cameraZ = (height/2.0) / tan(fov/2.0);
    perspective( fov, float(width)/float(height), cameraZ/10.0, cameraZ*10.0);

    PVector pos = path.position();

    translate( pos.x, pos.y, pos.z );
    ellipse( 400, 300, 5, 5 );
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
    boolean m_active;


    Path()
    {
        m_points = new ArrayList();
        m_index = 0;
        m_time = 0;
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
        }
    }

    PVector position()
    {
        if ( ! m_active ) 
        {
            return (PVector)m_points.get( m_index );
        }

        int m = millis() - m_time;

        if ( m > 3000 )
        {
            m_active = false;
            m_time = 0;
            m_index += 1;
            m_index = m_index % m_points.size();
            return (PVector)m_points.get( m_index );
        }

        int nextIndex = m_index + 1;
        nextIndex = nextIndex % m_points.size();

        float fraction = m / 3000.0; 

        PVector start = (PVector)m_points.get( m_index );
        PVector end = (PVector)m_points.get( nextIndex );

        PVector pos = new PVector( start.x, start.y, start.z );
        PVector dir = new PVector( end.x - start.x, end.y - start.y, end.z - start.z );
        dir.mult( fraction );
        pos.add( dir );

        return pos;
    }
}

