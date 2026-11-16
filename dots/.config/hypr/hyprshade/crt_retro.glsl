#version 300 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;

uniform sampler2D tex;

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

void main() {

    vec2 uv = curveUV(v_texcoord);

    // keep curved CRT edges visible
    if (uv.x < 0.0 || uv.x > 1.0 ||
        uv.y < 0.0 || uv.y > 1.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

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

    // ===== SHARP SCANLINES =====
    float scanPhase = uv.y * SCANLINE_COUNT;

    float scan = sin(scanPhase * 3.14159);

    float scanline = smoothstep(0.2, 1.0, abs(scan));

    color *= 1.0 - ((1.0 - scanline) * SCANLINE_STRENGTH);

    // ===== PHOSPHOR GLOW =====
    color += GLOW * (1.0 - scanline);

    // NO VIGNETTE.
    // GONE.
    // EXECUTED.

    // slight brightness compensation
    color *= mix(1.06, 1.0, scanline);

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}