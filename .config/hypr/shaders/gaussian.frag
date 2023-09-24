//---------------------------------------------------------------------------
// Fragment
//---------------------------------------------------------------------------
#version 420 core
//---------------------------------------------------------------------------
precision mediump float;
in vec2 pos;                    // screen position <-1,+1>
out vec4 gl_FragColor;          // fragment output color
uniform sampler2D txr;          // texture to blur
uniform float xs,ys;            // texture resolution
uniform float r = 6.0;          // blur radius

varying vec2 v_texcoord;
uniform sampler2D tex;
//---------------------------------------------------------------------------
void main()
    {
    float x,y,xx,yy,rr=r*r,dx,dy,w,w0;
    w0=0.3780/pow(r,1.975);
    vec2 p;
    vec4 pixColor = texture2D(tex, v_texcoord);
    for (dx=1.0/xs,x=-r,p.x=0.5+(pos.x*0.5)+(x*dx);x<=r;x++,p.x+=dx){ xx=x*x;
     for (dy=1.0/ys,y=-r,p.y=0.5+(pos.y*0.5)+(y*dy);y<=r;y++,p.y+=dy){ yy=y*y;
      if (xx+yy<=rr)
        {
        w=w0*exp((-xx-yy)/(2.0*rr));
        pixColor+=texture2D(txr,p)*w;
        }}}
    gl_FragColor = pixColor;
    }
//---------------------------------------------------------------------------
