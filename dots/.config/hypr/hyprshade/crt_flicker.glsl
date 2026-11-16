#version 300 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;

uniform sampler2D tex;
uniform float time;

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
float rand(vec2 p) {
    return fract(
        sin(dot(p, vec2(127.1, 311.7))) *
        43758.5453123
    );
}

void main() {

    vec2 uv = curveUV(v_texcoord);

    // outside CRT
    if (
        uv.x < 0.0 || uv.x > 1.0 ||
        uv.y < 0.0 || uv.y > 1.0
    ) {
        fragColor = vec4(0.0,0.0,0.0,1.0);
        return;
    }

    // =====================================================
    // BIG MOVING CRT INTERFERENCE BAR
    // =====================================================

    // visible moving vertical position (moves across screen smoothly, repeats every 5 seconds)
    float cycle = mod(time, 5.0);
    float roll = cycle * 1.2 - 0.5;

    // strong wide moving band
    float band =
        1.0 -
        smoothstep(
            0.0,
            0.12,
            abs(uv.y - roll)
        );

    // horizontal tearing
    uv.x +=
        sin(uv.y * 90.0 + time * 40.0)
        * 0.03
        * band;

    // unstable jitter
    uv.x +=
        (rand(vec2(time, uv.y)) - 0.5)
        * 0.01
        * band;

    // =====================================================
    // CHROMATIC ABERRATION
    // =====================================================

    vec2 centerDist = uv - 0.5;

    vec2 aberrDir =
        normalize(centerDist + 0.0001)
        * length(centerDist)
        * ABERRATION;

    float r = texture(tex, clamp(uv + aberrDir, 0.001, 0.999)).r;
    float g = texture(tex, clamp(uv,            0.001, 0.999)).g;
    float b = texture(tex, clamp(uv - aberrDir, 0.001, 0.999)).b;

    vec3 color = vec3(r, g, b);

    // =====================================================
    // SCANLINES
    // =====================================================

    float scan =
        sin(uv.y * SCANLINE_COUNT * 3.14159);

    float scanline =
        smoothstep(0.15, 1.0, abs(scan));

    color *=
        1.0 -
        ((1.0 - scanline) * SCANLINE_STRENGTH);

    // phosphor glow
    color += GLOW * (1.0 - scanline);

    // =====================================================
    // BRIGHT MOVING CRT BAR
    // =====================================================

    // The brightness shift from the moving bar was removed.
    // color += band * 0.18;

    // =====================================================
    // ANALOG FLICKER
    // =====================================================

    // Removed the analog flicker (brightness adjustments) to keep it perfectly stable
    float flicker = 1.0;

    color *= flicker;

    // =====================================================
    // STATIC NOISE
    // =====================================================

    float noise =
        rand(
            floor(uv * vec2(400.0, 300.0)) +
            floor(time * 60.0)
        );

    color += (noise - 0.5) * 0.04;

    // brightness compensation
    color *= mix(1.06, 1.0, scanline);

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}