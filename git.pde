
Path path = new Path();

void setup()
{
    size( 800, 600, P3D );

    path.add( new PVector( 0, 0, 0 ) );
    path.add( new PVector( 0, 50, 0 ) );
    path.add( new PVector( 20, 10, 0 ) );
}

// 0, 0 is top left.
void draw()
{
    PVector eye = new PVector( width/2, height/2, 2000 );
    PVector centre = new PVector( width/2, height/2, 0 );
    PVector up = new PVector( 0, 1, 0 );
    
    float fov = PI/3.0;
    float cameraZ = (height/2.0) / tan(fov/2.0);
    perspective( fov, float(width)/float(height), cameraZ/10.0, cameraZ*10.0);

  /*
  camera(
      eye.x, eye.y, eye.z,
      centre.x, centre.y, centre.z,
      up.x, up.y, up.z
      );
    */

    PVector pos = path.position();

    // println( pos );

    translate( pos.x, pos.y, pos.z );
    ellipse( 400, 300, 5, 5 );
}

void keyPressed()
{
    if ( key == 'q' )
    {
        exit();
    }
}


class Path
{
    ArrayList m_points;
    int m_index;

    Path()
    {
        m_points = new ArrayList();
        m_index = 0;
    }
    
    void add( PVector point )
    {
        m_points.add( point );
    }

    PVector position()
    {
        int m = millis();

        int index = m / 3000;
        index = index % m_points.size();

        int nextIndex = index + 1;
        nextIndex = nextIndex % m_points.size();

        float fraction = ( m % 3000 ) / 3000.0; 


        PVector start = (PVector)m_points.get( index );
        PVector end = (PVector)m_points.get( nextIndex );

        PVector pos = new PVector( start.x, start.y, start.z );
        PVector dir = new PVector( end.x - start.x, end.y - start.y, end.z - start.z );
        dir.mult( fraction );
        pos.add( dir );

        println( fraction + " " + index + " " + nextIndex + " " + pos );
        return pos;
    }
}

