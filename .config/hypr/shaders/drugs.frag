
precision highp float;
varying vec2 v_texcoord;
uniform sampler2D tex;
uniform float time;

void warpco(inout vec2 tc) {
    tc -= 0.5;
    tc *= length(tc) * 2.0;
    tc += 0.5;
}

float rand1d(float seed) {
   return sin(seed*1454.0); 
}

float rand2d(vec2 co)
{
  return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453);
}

vec3 rgb(in vec2 tc, float freq, float amp, inout vec4 centre) {
    vec2 off = vec2(1.0/800.0, 0.0) * sin(tc.t * freq + time) * amp;
    vec2 off2 = vec2(1.0/800.0, 0.0) * sin(tc.t * freq - time * 1.5) * amp;
    centre = texture2D(tex, tc);
    return vec3(texture2D(tex, tc-off).r, centre.g, texture2D(tex, tc+off2).b);
}

void main() {
    // vec2 px = 1.0 / textureSize(tex, 0).st;
    vec2 tc = v_texcoord;
    warpco(tc);
    tc = mix(v_texcoord, tc, sin(time * 2.0)*0.07);
    tc.x += rand2d(floor(tc * 20.0 + floor(time * 2.5))) * 0.01;
    tc.x += rand1d(floor(tc.x * 40.0)) * 0.005 * rand1d(time * 0.001);
    tc.y += sin(tc.x + time) * 0.02;
    vec4 centre;
    vec3 bent = rgb(tc, 100.0, 5.0, centre);
    vec3 col = mix(centre.rgb, bent, sin(time));
    gl_FragColor = vec4(col, centre.a);
    // gl_FragColor = vec4(texture2D(tex, v_texcoord));
}