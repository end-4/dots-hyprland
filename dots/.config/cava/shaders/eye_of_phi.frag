#version 330

// this shader was stolen from shadertoy user ChunderFPV

#define SCALE 8.0
#define PI radians(180.0)
#define TAU (PI * 2.0)
#define CS(a) vec2(cos(a), sin(a))
#define PT(u, r) smoothstep(0.0, r, r - length(u))

in vec2 fragCoord;
out vec4 fragColor;

uniform float bars[512];

uniform int bars_count;    // number of bars (left + right) (configurable)
uniform float shader_time; // shader execution time s
uniform int bar_width;     // bar width (configurable), not used here
uniform int bar_spacing;   // space bewteen bars (configurable)

uniform vec3 u_resolution; // window resolution

// colors, configurable in cava config file (r,g,b) (0.0 - 1.0)
uniform vec3 bg_color; // background color
uniform vec3 fg_color; // foreground color

uniform int gradient_count;
uniform vec3 gradient_colors[8]; // gradient colors

// gradient map ( color, equation, time, width, shadow, reciprocal )
vec3 gm(vec3 c, float n, float t, float w, float d, bool i) {
  float g = min(abs(n), 1.0 / abs(n));
  float s = abs(sin(n * PI - t));
  if (i)
    s = min(s, abs(sin(PI / n + t)));
  return (1.0 - pow(abs(s), w)) * c * pow(g, d) * 6.0;
}

// denominator spiral, use 1/n for numerator
// ( screen xy, spiral exponent, decimal, line width, hardness, rotation )
float ds(vec2 u, float e, float n, float w, float h, float ro) {
  float ur = length(u);          // unit radius
  float sr = pow(ur, e);         // spiral radius
  float a = round(sr) * n * TAU; // arc
  vec2 xy = CS(a + ro) * ur;     // xy coords
  float l = PT(u - xy, w);       // line
  float s = mod(sr + 0.5, 1.0);  // gradient smooth
  s = min(s, 1.0 - s);           // darken filter
  return l * s * h;
}

void main() {
  float t = shader_time / PI * 2.0;
  vec4 m = vec4(0, 0, 0, 0);                 // iMouse;
  m.xy = m.xy * 2.0 / u_resolution.xy - 1.0; // ±1x, ±1y
  if (m.z > 0.0)
    t += m.y * SCALE; // move time with mouse y
  float z = (m.z > 0.0) ? pow(1.0 - abs(m.y), sign(m.y)) : 1.0; // zoom (+)
  float e = (m.z > 0.0) ? pow(1.0 - abs(m.x), -sign(m.x))
                        : 1.0;                   // screen exponent (+)
  float se = (m.z > 0.0) ? e * -sign(m.y) : 1.0; // spiral exponent
  vec3 bg = vec3(0);                             // black background

  float aa = 3.0; // anti-aliasing

  for (float j = 0.0; j < aa; j++)
    for (float k = 0.0; k < aa; k++) {
      vec3 c = vec3(0);
      vec2 o = vec2(j, k) / aa;
      vec2 uv = (fragCoord * u_resolution.xy - 0.5 * u_resolution.xy + o) /
                u_resolution.y * SCALE * z; // apply cartesian, scale and zoom
      if (m.z > 0.0)
        uv =
            exp(log(abs(uv)) * e) * sign(uv); // warp screen space with exponent

      float px = length(fwidth(uv)); // pixel width
      float x = uv.x;                // every pixel on x
      float y = uv.y;                // every pixel on y
      float l = length(uv);          // hypot of xy: sqrt(x*x+y*y)

      float mc = (x * x + y * y - 1.0) / y;  // metallic circle at xy
      float g = min(abs(mc), 1.0 / abs(mc)); // gradient
      vec3 gold = vec3(1.0, 0.6, 0.0) * g * l;
      vec3 blue = vec3(0.3, 0.5, 0.9) * (1.0 - g);
      vec3 rgb = max(gold, blue);

      float w = 0.1;                                      // line width
      float d = 0.4;                                      // shadow depth
      c = max(c, gm(rgb, mc, -t, w * bars[0], d, false)); // metallic
      c = max(c, gm(rgb, abs(y / x) * sign(y), -t, w * bars[1], d,
                    false)); // tangent
      c = max(c, gm(rgb, (x * x) / (y * y) * sign(y), -t, w * bars[2], d,
                    false)); // sqrt cotangent
      c = max(c, gm(rgb, (x * x) + (y * y), t, w * bars[3], d,
                    true)); // sqrt circles

      c += rgb * ds(uv, se, t / TAU, px * 2.0 * bars[4], 2.0, 0.0); // spiral 1a
      c += rgb * ds(uv, se, t / TAU, px * 2.0 * bars[5], 2.0, PI);  // spiral 1b
      c +=
          rgb * ds(uv, -se, t / TAU, px * 2.0 * bars[6], 2.0, 0.0); // spiral 2a
      c += rgb * ds(uv, -se, t / TAU, px * 2.0 * bars[7], 2.0, PI); // spiral 2b
      c = max(c, 0.0); // clear negative color

      c += pow(max(1.0 - l, 0.0), 3.0 / z); // center glow

      if (m.z > 0.0) // display grid on click
      {
        vec2 xyg = abs(fract(uv + 0.5) - 0.5) / px; // xy grid
        c.gb += 0.2 * (1.0 - min(min(xyg.x, xyg.y), 1.0));
      }
      bg += c;
    }
  bg /= aa * aa;
  bg *= sqrt(bg) * 1.5;

  fragColor = vec4(bg, 1.0);
}