#version 300 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;

uniform sampler2D tex;
uniform float u_time;

// ===== SETTINGS =====
const float CURVATURE          = 3.5;
const float SCANLINE_STRENGTH  = 0.22;
const float SCANLINE_COUNT     = 900.0;
const float ABERRATION         = 0.002;
const float GLOW               = 0.025;

// ===== CRT CURVE =====
vec2 curveUV(vec2 uv) {
    uv = uv * 2.0 - 1.0;

    vec2 offset = abs(uv.yx) / vec2(CURVATURE);
    uv += uv * offset * offset;

    uv = uv * 0.5 + 0.5;

    return uv;
}

// ===== RANDOM =====
float rand(vec2 co) {
    return fract(
        sin(dot(co.xy, vec2(12.9898, 78.233))) *
        43758.5453
    );
}

void main() {

    vec2 uv = curveUV(v_texcoord);

    // outside CRT
    if (uv.x < 0.0 || uv.x > 1.0 ||
        uv.y < 0.0 || uv.y > 1.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    // ===== CRT HORIZONTAL STUTTER =====
    // subtle horizontal wobble bands
    float wobble =
        sin(uv.y * 18.0 + u_time * 8.0) *
        0.0015;

    // occasional stronger glitch sweep
    float glitch =
        step(0.96, sin(u_time * 0.7)) *
        sin(uv.y * 120.0 + u_time * 40.0) *
        0.004;

    uv.x += wobble + glitch;

    // ===== CHROMATIC ABERRATION =====
    vec2 centerDist = uv - 0.5;

    vec2 aberrDir =
        normalize(centerDist + 0.0001) *
        length(centerDist) *
        ABERRATION;

    float r = texture(tex, clamp(uv + aberrDir, 0.001, 0.999)).r;
    float g = texture(tex, clamp(uv,            0.001, 0.999)).g;
    float b = texture(tex, clamp(uv - aberrDir, 0.001, 0.999)).b;

    vec3 color = vec3(r, g, b);

    // ===== SCANLINES =====
    float scanPhase = uv.y * SCANLINE_COUNT;

    float scan = sin(scanPhase * 3.14159);

    float scanline = smoothstep(0.2, 1.0, abs(scan));

    color *= 1.0 - ((1.0 - scanline) * SCANLINE_STRENGTH);

    // ===== PHOSPHOR GLOW =====
    color += GLOW * (1.0 - scanline);

    // ===== ANALOG CRT FLICKER =====
    // whole-screen brightness fluctuation
    float flicker =
        0.985 +
        sin(u_time * 16.0) * 0.01 +
        sin(u_time * 37.0) * 0.008;

    color *= flicker;

    // ===== STATIC NOISE =====
    float noise =
        rand(vec2(
            floor(uv.x * 320.0),
            floor(uv.y * 240.0) + floor(u_time * 60.0)
        ));

    color += (noise - 0.5) * 0.03;

    // slight brightness compensation
    color *= mix(1.06, 1.0, scanline);

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}