#version 330

in vec2 fragCoord;
out vec4 fragColor;

// bar values. defaults to left channels first (low to high), then right (high to low).
uniform float bars[512];

uniform int bars_count;    // number of bars (left + right) (configurable)

uniform vec3 u_resolution; // window resolution, not used here

//colors, configurable in cava config file
uniform vec3 bg_color; // background color(r,g,b) (0.0 - 1.0), not used here
uniform vec3 fg_color; // foreground color, not used here

void main()
{
    // find which bar to use based on where we are on the x axis
    int bar = int(bars_count * fragCoord.x);

    float bar_y = 1.0 - abs((fragCoord.y - 0.5)) * 2.0;
    float y = (bars[bar]) * bar_y;

    float bar_x = (fragCoord.x - float(bar) / float(bars_count)) * bars_count;
    float bar_r = 1.0 - abs((bar_x - 0.5)) * 2;

    bar_r = bar_r * bar_r * 2;

    // set color
    fragColor.r = fg_color.x * y * bar_r;
    fragColor.g = fg_color.y * y * bar_r;
    fragColor.b = fg_color.z * y * bar_r;
}
