
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
    Path( ArrayList points, SmoothStepper stepper, int startIndex )
    {
        m_points = points;
        m_stepper = stepper;

        m_index = startIndex;
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
float progress;

void setup()
{
    size( screen.width, screen.height );

    //  Set up points
    //
    ArrayList points = new ArrayList();

    // Git 0 
    points.add( new PVector( 623.5175, 224.72202, 4.329994 ) );
    points.add( new PVector( 693.69226, 428.95862, 1.5999943 ) );

    // History 2
    points.add( new PVector( 700.58875, 380.68277, 7.829997 ) );
    points.add( new PVector( 670.9445, 416.68527, 13.379998 ) );
    points.add( new PVector( 670.09064, 461.60898, 13.980008 ) );
    points.add( new PVector( 649.7766, 509.32263, 23.160019 ) );
    points.add( new PVector( 646.45276, 540.4964, 23.160019 ) );
    points.add( new PVector( 644.5981, 574.9941, 23.160019 ) );

    // All 8 
    points.add( new PVector( 697.2315, 435.7925, 1.7100239 ) );

    // Weakness 9
    points.add( new PVector( 1061.3906, 463.08224, 3.2000227 ) );
    points.add( new PVector( 847.0228, 332.4834, 11.40001 ) );
    points.add( new PVector( 910.5204, 255.41368, 9.95001 ) );
    points.add( new PVector( 1115.3451, 261.14224, 9.95001 ) );
    points.add( new PVector( 1192.3401, 358.20825, 7.3699975 ) );
    points.add( new PVector( 1195.3258, 518.3166, 7.3699975 ) );
    points.add( new PVector( 946.0718, 556.3085, 7.3699975 ) );

    // All 16
    points.add( new PVector( 697.2315, 435.7925, 1.7100239 ) );

    // Strengths 17
    points.add( new PVector( 335.9829, 444.58264, 3.359994 ) );

    // Distributed 18
    points.add( new PVector( 485.9002, 371.31708, 10.300017 ) );
    points.add( new PVector( 519.94635, 310.7871, 17.410007 ) );

    // Internal Stucture 20
    points.add( new PVector( 258.05603, 364.0658, 8.770002 ) );
    points.add( new PVector( 161.88809, 293.78592, 9.179997 ) );
    points.add( new PVector( 148.37703, 213.91788, 13.250006 ) );
    points.add( new PVector( 227.07912, 140.75266, 11.900001 ) );
    points.add( new PVector( 449.41953, 187.99435, 5.2300034 ) );
    points.add( new PVector( 449.41953, 187.99435, 5.2300034 ) );
    points.add( new PVector( 449.41953, 187.99435, 5.2300034 ) );
    points.add( new PVector( 449.41953, 187.99435, 5.2300034 ) );
    points.add( new PVector( 449.41953, 187.99435, 5.2300034 ) );
    points.add( new PVector( 449.41953, 187.99435, 5.2300034 ) );
    points.add( new PVector( 449.41953, 187.99435, 5.2300034 ) );
    points.add( new PVector( 449.41953, 187.99435, 5.2300034 ) );

    // Graph 32
    points.add( new PVector( 645.07623, 128.98013, 5.9600134 ) );
    points.add( new PVector( 735.34485, 127.30228, 5.9600134 ) );
    points.add( new PVector( 844.4055, 127.80563, 5.9600134 ) );
    points.add( new PVector( 1052.9537, 126.93085, 4.869995 ) );
    points.add( new PVector( 1052.9537, 126.93085, 4.869995 ) );
    points.add( new PVector( 1052.9537, 126.93085, 4.869995 ) );
    points.add( new PVector( 1052.9537, 126.93085, 4.869995 ) );
    points.add( new PVector( 1052.9537, 126.93085, 4.869995 ) );
    points.add( new PVector( 1052.9537, 126.93085, 4.869995 ) );

    // Back to tree 41
    points.add( new PVector( 449.41953, 187.99435, 5.2300034 ) );

    // Strengths 42
    points.add( new PVector( 353.12164, 444.95206, 3.430493 ) );

    // Edit History 43
    points.add( new PVector( 209.4329, 499.5155, 8.820501 ) );

    // Commit --amend 44
    points.add( new PVector( 107.93087, 442.11414, 14.050512 ) );
    points.add( new PVector( 107.93087, 442.11414, 14.050512 ) );

    // Rebase 46
    points.add( new PVector( 39.10782, 518.8512, 14.030513 ) );
    points.add( new PVector( 39.10782, 518.8512, 14.030513 ) );

    // Rebase -i 48
    points.add( new PVector( 110.460976, 591.8779, 12.70049 ) ); 
    points.add( new PVector( 110.460976, 591.8779, 12.70049 ) ); 
    points.add( new PVector( 110.460976, 591.8779, 12.70049 ) ); 
    points.add( new PVector( 110.460976, 591.8779, 12.70049 ) ); 
    points.add( new PVector( 110.460976, 591.8779, 12.70049 ) ); 

    // Strengths 53
    points.add( new PVector( 334.5667, 447.57346, 3.4005084 ) );

    // Userful Command 54
    points.add( new PVector( 435.62344, 539.23126, 7.5605044 ) );

    // Init 55
    points.add( new PVector( 283.70743, 572.94055, 12.980504 ) );
    points.add( new PVector( 283.70743, 572.94055, 12.980504 ) );

    // Add -P 57
    points.add( new PVector( 324.0758, 632.64514, 12.980504 ) );
    points.add( new PVector( 286.08682, 645.0898, 9.560483 ) );
    
    // Gitk 59
    points.add( new PVector( 404.04178, 665.6942, 13.930511 ) );

    // CherryPick 60
    points.add( new PVector( 500.95087, 654.63837, 13.930511 ) );
    points.add( new PVector( 500.95087, 654.63837, 13.930511 ) );

    // Bisect 62
    points.add( new PVector( 547.25183, 595.1302, 13.930511 ) );

    // All 63
    points.add( new PVector( 697.2315, 435.7925, 1.7100239 ) );
    
    // Git 64
    points.add( new PVector( 623.5175, 224.72202, 4.329994 ) );


    /*
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
    */

    // Node Building
    // /* 22 */ points.add( new PVector( 471.15045, 178.68713, 5.099945 ) );
    // /* 23 */ points.add( new PVector( 471.15045, 178.68713, 5.099945 ) );
    // /* 24 */ points.add( new PVector( 471.15045, 178.68713, 5.099945 ) );
    // /* 25 */ points.add( new PVector( 471.15045, 178.68713, 5.099945 ) );
    // /* 26 */ points.add( new PVector( 471.15045, 178.68713, 5.099945 ) );
    // /* 27 */ points.add( new PVector( 471.15045, 178.68713, 5.099945 ) );
    // /* 28 */ points.add( new PVector( 471.15045, 178.68713, 5.099945 ) );
    // /* 29 */ points.add( new PVector( 471.15045, 178.68713, 5.099945 ) );
    // /* 30 */ points.add( new PVector( 664.4871, 133.19649, 5.099945 ) );
    // /* 31 */ points.add( new PVector( 730.56696, 133.00035, 5.099945 ) );
    // /* 32 */ points.add( new PVector( 834.0974, 131.43175, 5.099945 ) );
    // /* 33 */ points.add( new PVector( 1022.5326, 132.80426, 5.099945 ) );
    // /* 34 */ points.add( new PVector( 1022.5326, 132.80426, 5.099945 ) );
    // /* 35 */ points.add( new PVector( 1022.5326, 132.80426, 5.099945 ) );

    /*
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
    */

    // Setup motion class
    SmoothStepper stepper = new SmoothStepper();
    Path path = new Path( points, stepper, 50 );

    PVector first = path.position();
    Pivot pivot = new Pivot( new PVector( 0, 0 ), first.z );

    motion = new Motion( path, stepper, pivot );

    String root = "/home/mike/projects/presentations/git/layers/";

    ArrayList renderers = new ArrayList();
    RendererFactory rendererFactory = new RendererFactory( this );

    renderers.add( rendererFactory.create( "Init", root, 56, 56 ) );
    renderers.add( rendererFactory.create( "AddP", root, 58, 58 ) );
    renderers.add( rendererFactory.create( "CherryPick", root, 61, 61 ) );

    renderers.add( rendererFactory.create( "CommitAmend", root, 45, 45 ) );
    renderers.add( rendererFactory.create( "Rebase1", root, 47, 47 ) );
    renderers.add( rendererFactory.create( "RebaseI4", root, 52, 52 ) );
    renderers.add( rendererFactory.create( "RebaseI3", root, 51, 52 ) );
    renderers.add( rendererFactory.create( "RebaseI2", root, 50, 50 ) );
    renderers.add( rendererFactory.create( "RebaseI1", root, 49, 52 ) );

    renderers.add( rendererFactory.create( "History", root, 3, 7 ) );
    renderers.add( rendererFactory.create( "UI", root, 10, 14 ) );
    renderers.add( rendererFactory.create( "Weaknesses", root, 9, 16 ) );
    renderers.add( rendererFactory.create( "InternalStructure", root, 21, 30 ) );
    renderers.add( rendererFactory.create( "EditHistory", root, 19, 52 ) );
    renderers.add( rendererFactory.create( "UsefulCommands", root, 19, 62 ) );
    renderers.add( rendererFactory.create( "Strengths", root, 17, 62 ) );
    renderers.add( rendererFactory.create( "MainTitles", root, 1, 63 ) );
    renderers.add( rendererFactory.create( "Git", root, 0, 0 ) );
    renderers.add( rendererFactory.create( "Git", root, 64, 64 ) );

    renderers.add( rendererFactory.create( "Distributed", root, 19, 19 ) );

    renderers.add( rendererFactory.create( "NodeBuildingBlob1", root, 25, 45 ) );
    renderers.add( rendererFactory.create( "NBTextBlob1", root, 25, 25 ) );

    renderers.add( rendererFactory.create( "NodeBuildingBlob2", root, 26, 45 ) );
    renderers.add( rendererFactory.create( "NBTextBlob2", root, 26, 26 ) );

    renderers.add( rendererFactory.create( "NodeBuildingTree1", root, 27, 45 ) );
    renderers.add( rendererFactory.create( "NBTextTree1", root, 27, 27 ) );

    renderers.add( rendererFactory.create( "NodeBuildingBlob3", root, 28, 45 ) );
    renderers.add( rendererFactory.create( "NBTextBlob3", root, 28, 28 ) );

    renderers.add( rendererFactory.create( "NodeBuildingTree2", root, 29, 45 ) );
    renderers.add( rendererFactory.create( "NBTextTree2", root, 29, 29 ) );

    renderers.add( rendererFactory.create( "NodeBuildingCommit1", root, 30, 45 ) );
    renderers.add( rendererFactory.create( "NBTextCommit1", root, 30, 30 ) );

    renderers.add( rendererFactory.create( "NodeBuildingCommit2", root, 31, 45 ) );
    renderers.add( rendererFactory.create( "Tags2", root, 40, 41 ) );
    renderers.add( rendererFactory.create( "Tags", root, 39, 41 ) );
    renderers.add( rendererFactory.create( "Branches4", root, 38, 38 ) );
    renderers.add( rendererFactory.create( "Branches3", root, 37, 37 ) );
    renderers.add( rendererFactory.create( "Branches2", root, 36, 41 ) );
    renderers.add( rendererFactory.create( "Branches1", root, 35, 41 ) );
    renderers.add( rendererFactory.create( "GraphBuilding3", root, 34, 45 ) );
    renderers.add( rendererFactory.create( "GraphBuilding2", root, 33, 45 ) );
    renderers.add( rendererFactory.create( "GraphBuilding1", root, 32, 45 ) );

    // renderers.add( new ProgressRenderer( new BoxRenderer(), 0, 1000 ) );
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

    float progress_ = motion.progress();

    if ( motion.m_mode == "free" )
    {
        progress_ = progress;
    }

    // ellipse( 0, 0, 50, 50 );

    rendererGroup.render( motion.position(), progress_, 1.0 );
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
    else if ( mouseButton == CENTER )
    {
        float diff = mouseX - pmouseX;
        progress += diff / 50.0;
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
            progress = motion.progress();
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


