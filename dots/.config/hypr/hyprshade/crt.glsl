#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

const float CURVATURE        = 3.5;
const float SCANLINE_STRENGTH = 0.25;
const float SCANLINE_COUNT   = 540.0;
const float ABERRATION       = 0.002;
const float VIGNETTE_RADIUS  = 1.20;   // pushed out so corners aren't clipped
const float VIGNETTE_SOFTNESS = 0.35;
const float GLOW             = 0.03;

vec2 curveUV(vec2 uv) {
    uv = uv * 2.0 - 1.0;
    vec2 offset = abs(uv.yx) / vec2(CURVATURE);
    uv = uv + uv * offset * offset;
    uv = uv * 0.5 + 0.5;
    return uv;
}

void main() {
    vec2 uv = curveUV(v_texcoord);

    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    vec2 centerDist = uv - 0.5;

    // FIX: normalize direction so aberration is uniform across all angles
    vec2 aberrDir = normalize(centerDist) * length(centerDist) * ABERRATION;

    float r = texture(tex, clamp(uv + aberrDir, 0.001, 0.999)).r;
    float g = texture(tex, clamp(uv,            0.001, 0.999)).g;
    float b = texture(tex, clamp(uv - aberrDir, 0.001, 0.999)).b;
    vec3 color = vec3(r, g, b);

    // Scanlines
    float scanlinePhase  = uv.y * SCANLINE_COUNT * 2.0;
    float scanline       = abs(fract(scanlinePhase) - 0.5) * 2.0;
    scanline             = smoothstep(0.0, 1.0, scanline);
    float scanlineFactor = 1.0 - (SCANLINE_STRENGTH * (1.0 - scanline));
    color *= scanlineFactor;

    // Phosphor glow
    color += GLOW * (1.0 - scanline);

    // FIX: vignette radius pushed past max possible dist (~1.414 at corners)
    // so the fade zone starts outside the screen area
    float dist    = length(centerDist) * 2.0;
    float vignette = 1.0 - smoothstep(VIGNETTE_RADIUS, VIGNETTE_RADIUS + VIGNETTE_SOFTNESS, dist);
    color *= vignette;

    // FIX: removed flat *1.1 boost; compensate within scanline math instead
    // Slight lift only where scanlines darken
    color *= mix(1.08, 1.0, scanline);

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}