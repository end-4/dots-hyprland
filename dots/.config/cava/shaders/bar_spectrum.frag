#version 330

in vec2 fragCoord;
out vec4 fragColor;

// bar values. defaults to left channels first (low to high), then right (high to low).
uniform float bars[512];

uniform int bars_count;  // number of bars (left + right) (configurable)
uniform int bar_width;   // bar width (configurable), not used here
uniform int bar_spacing; // space bewteen bars (configurable)

uniform vec3 u_resolution; // window resolution

// colors, configurable in cava config file (r,g,b) (0.0 - 1.0)
uniform vec3 bg_color; // background color
uniform vec3 fg_color; // foreground color

uniform int gradient_count;
uniform vec3 gradient_colors[8]; // gradient colors

uniform float shader_time; // shader execution time s (not used here)

uniform sampler2D inputTexture; // Texture from the last render pass (not used here)

vec3 normalize_C(float y, vec3 col_1, vec3 col_2, float y_min, float y_max) {
    // create color based on fraction of this color and next color
    float yr = (y - y_min) / (y_max - y_min);
    return col_1 * (1.0 - yr) + col_2 * yr;
}

void main() {
    // find which bar to use based on where we are on the x axis
    float x = u_resolution.x * fragCoord.x;
    int bar = int(bars_count * fragCoord.x);

    // calculate a bar size
    float bar_size = u_resolution.x / bars_count;

    // the y coordinate and bar values are the same
    float y = bars[bar];

    // make sure there is a thin line at bottom
    if (y * u_resolution.y < 1.0) {
        y = 1.0 / u_resolution.y;
    }

    // draw the bar up to current height
    if (y > fragCoord.y) {
        // make some space between bars basen on settings
        if (x > (bar + 1) * (bar_size)-bar_spacing) {
            fragColor = vec4(bg_color, 1.0);
        } else {
            if (gradient_count == 0) {
                fragColor = vec4(fg_color, 1.0);
            } else {
                // find which color in the configured gradient we are at
                int color = int((gradient_count - 1) * fragCoord.y);

                // find where on y this and next color is supposed to be
                float y_min = color / (gradient_count - 1.0);
                float y_max = (color + 1.0) / (gradient_count - 1.0);

                // make color
                fragColor = vec4(normalize_C(fragCoord.y, gradient_colors[color],
                                             gradient_colors[color + 1], y_min, y_max),
                                 1.0);
            }
        }
    } else {
        fragColor = vec4(bg_color, 1.0);
    }
}