// paper.glsl — Hyprshade screen shader
// Simulates a paper-like display: warm tint, grain, reduced contrast, subtle vignette, fiber texture
// Place in ~/.config/hypr/shaders/paper.glsl
// Usage: hyprshade on paper

precision mediump float;

varying vec2 v_texcoord;
uniform sampler2D tex;
uniform float time;  // requires damage_tracking = 0 in hyprland.conf (only if animated)

// --- Helpers ---

// Hash for pseudo-random noise
float hash(vec2 p) {
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

// Smooth noise
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f); // smoothstep

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Layered noise for paper grain
float paperGrain(vec2 uv, float scale) {
    float n = 0.0;
    n += 0.500 * noise(uv * scale);
    n += 0.250 * noise(uv * scale * 2.1);
    n += 0.125 * noise(uv * scale * 4.3);
    n += 0.062 * noise(uv * scale * 8.7);
    return n;
}

// Simulate paper fiber streaks
float fiberNoise(vec2 uv) {
    float f = 0.0;
    // Horizontal-ish fibers
    f += 0.4 * noise(vec2(uv.x * 3.0, uv.y * 180.0));
    f += 0.3 * noise(vec2(uv.x * 2.5 + 0.3, uv.y * 220.0));
    // Slightly diagonal fibers
    f += 0.3 * noise(vec2((uv.x + uv.y * 0.15) * 2.8, uv.y * 160.0));
    return f;
}

void main() {
    vec2 uv = v_texcoord;

    // Sample original screen colour
    vec4 colour = texture2D(tex, uv);

    // --- 1. Reduce contrast (paper doesn't show pure black/white) ---
    // Remap [0,1] → [0.04, 0.93]
    colour.rgb = colour.rgb * 0.89 + 0.04;

    // --- 2. Warm paper tint ---
    // Blend toward a warm off-white paper colour
    vec3 paperColour = vec3(0.96, 0.93, 0.87); // slightly warm, creamy
    colour.rgb = mix(colour.rgb, paperColour, 0.055);

    // --- 3. Desaturate slightly (paper dulls colours) ---
    float luma = dot(colour.rgb, vec3(0.299, 0.587, 0.114));
    colour.rgb = mix(colour.rgb, vec3(luma), 0.12);

    // --- 4. Paper grain ---
    float grain = paperGrain(uv, 320.0);
    // Grain is additive/subtractive around 0
    float grainStrength = 0.045;
    colour.rgb += (grain - 0.5) * grainStrength;

    // --- 5. Paper fiber texture (very subtle) ---
    float fiber = fiberNoise(uv);
    colour.rgb += (fiber - 0.5) * 0.012;

    // --- 6. Soft vignette (paper tends to be brighter in the centre under a light) ---
    vec2 vigUV = uv * 2.0 - 1.0;
    float vignette = 1.0 - dot(vigUV * vec2(0.45, 0.55), vigUV * vec2(0.45, 0.55));
    vignette = clamp(vignette, 0.0, 1.0);
    vignette = pow(vignette, 0.35); // gentle falloff
    colour.rgb *= mix(0.88, 1.0, vignette);

    // --- 7. Very slight yellow-brown age tint toward edges ---
    vec3 ageTint = vec3(0.82, 0.76, 0.60);
    float edgeMix = 1.0 - vignette;
    edgeMix = edgeMix * edgeMix * 0.18;
    colour.rgb = mix(colour.rgb, ageTint, edgeMix);

    // Clamp
    colour.rgb = clamp(colour.rgb, 0.0, 1.0);

    gl_FragColor = vec4(colour.rgb, 1.0);
}
