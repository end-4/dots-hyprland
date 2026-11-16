#version 300 es
precision highp float;  // CRITICAL: Prevents many artifacts

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// --- CONFIGURATION ---
const float dot_spacing = 4.0;          // 3.0-6.0 recommended
const int   color_levels = 4;           // Posterization levels
const vec3  paper_color = vec3(0.95, 0.92, 0.85);
const float paper_texture_strength = 0.04;
const float dot_softness = 1.5;         // Higher = softer dot edges (anti-aliasing)
const float ink_darkness = 0.95;        // How dark the ink appears (0.0-1.0)
const bool  use_dithering = true;       // Reduces posterization banding
// ---------------------

// Improved hash function - less pattern artifacts than sin-based
float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// Smoother 2D noise for paper texture
float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    // Smooth interpolation
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    float a = hash12(i);
    float b = hash12(i + vec2(1.0, 0.0));
    float c = hash12(i + vec2(0.0, 1.0));
    float d = hash12(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float luminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

// Bayer 4x4 dithering matrix - reduces posterization banding
float bayerDither(vec2 pos) {
    ivec2 p = ivec2(mod(pos, 4.0));
    int index = p.x + p.y * 4;
    
    // Bayer matrix values
    float matrix[16] = float[16](
         0.0,  8.0,  2.0, 10.0,
        12.0,  4.0, 14.0,  6.0,
         3.0, 11.0,  1.0,  9.0,
        15.0,  7.0, 13.0,  5.0
    );
    
    return (matrix[index] / 16.0) - 0.5;
}

void main() {
    vec2 screen_res = vec2(textureSize(tex, 0));
    vec2 pixel_coords = v_texcoord * screen_res;
    
    // 1. Sample original with clamped coordinates (prevents edge artifacts)
    vec2 safe_uv = clamp(v_texcoord, 0.0, 1.0);
    vec3 original_color = texture(tex, safe_uv).rgb;
    
    // 2. Posterize with optional dithering to reduce banding
    float levels = float(color_levels);
    vec3 posterized_color;
    
    if (use_dithering) {
        // Add dither before quantization
        float dither = bayerDither(pixel_coords) / (levels * 2.0);
        posterized_color = floor((original_color + dither) * levels) / (levels - 1.0);
    } else {
        posterized_color = floor(original_color * levels) / (levels - 1.0);
    }
    posterized_color = clamp(posterized_color, 0.0, 1.0);
    
    // 3. Create layered paper texture (more natural looking)
    float paper_noise = 0.0;
    paper_noise += valueNoise(pixel_coords * 0.5) * 0.6;           // Large grain
    paper_noise += valueNoise(pixel_coords * 1.5) * 0.3;           // Medium grain  
    paper_noise += hash12(pixel_coords) * 0.1;                      // Fine grain
    paper_noise *= paper_texture_strength;
    
    vec3 textured_paper = max(paper_color - paper_noise, 0.0);     // Prevent negative
    
    // 4. Create halftone grid
    vec2 cell_coords = pixel_coords / dot_spacing;
    vec2 grid_uv = fract(cell_coords);
    
    // 5. Calculate halftone dot
    // Use sqrt for area-proportional dots (perceptually correct)
    float lum = luminance(posterized_color);
    float darkness = 1.0 - lum;
    float dot_radius = sqrt(darkness) * 0.5;  // Area proportional to darkness
    
    // Distance from cell center
    float dist = length(grid_uv - 0.5);
    
    // Anti-aliased dot edge using screen-space derivatives
    // This adapts to any resolution automatically
    float pixel_width = fwidth(dist) * dot_softness;
    float dot_mask = smoothstep(dot_radius - pixel_width, dot_radius + pixel_width, dist);
    
    // 6. Combine: ink color where dots are, paper elsewhere
    vec3 ink_color = posterized_color * ink_darkness;
    vec3 final_color = mix(ink_color, textured_paper, dot_mask);
    
    fragColor = vec4(final_color, 1.0);
}