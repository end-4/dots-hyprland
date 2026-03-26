#version 330

// Emulate the "line style" spectrum analyzer from Winamp 2.
// Try this config for a demonstration:

/*
[general]
bar_width = 2
bar_spacing = 0
higher_cutoff_freq = 22000

[output]
method = sdl_glsl
channels = mono
fragment_shader = winamp_line_style_spectrum.frag

[color]
background = '#000000'
gradient = 1
gradient_color_1 = '#319C08'
gradient_color_2 = '#29CE10'
gradient_color_3 = '#BDDE29'
gradient_color_4 = '#DEA518'
gradient_color_5 = '#D66600'
gradient_color_6 = '#CE2910'

[smoothing]
noise_reduction = 10
*/

in vec2 fragCoord;
out vec4 fragColor;

// bar values. defaults to left channels first (low to high), then right (high to low).
uniform float bars[512];

uniform int bars_count;    // number of bars (left + right) (configurable)
uniform int bar_width;    // bar width (configurable), not used here
uniform int bar_spacing;    // space bewteen bars (configurable)

uniform vec3 u_resolution; // window resolution

//colors, configurable in cava config file (r,g,b) (0.0 - 1.0)
uniform vec3 bg_color; // background color
uniform vec3 fg_color; // foreground color

uniform int gradient_count;
uniform vec3 gradient_colors[8]; // gradient colors

vec3 normalize_C(float y,vec3 col_1, vec3 col_2, float y_min, float y_max)
{
    //create color based on fraction of this color and next color
    float yr = (y - y_min) / (y_max - y_min);
    return col_1 * (1.0 - yr) + col_2 * yr;
}

void main()
{
    // find which bar to use based on where we are on the x axis
    float x = u_resolution.x * fragCoord.x;
    int bar = int(bars_count * fragCoord.x);

    //calculate a bar size
    float bar_size = u_resolution.x / bars_count;

    //the y coordinate is stretched by 4X to resemble Winamp
    float y =  min(bars[bar] * 4.0, 1.0);

    // make sure there is a thin line at bottom
    if (y * u_resolution.y < 1.0)
    {
      y = 1.0 / u_resolution.y;
    }

    vec4 bar_color;

    if (gradient_count == 0)
    {
        bar_color = vec4(fg_color,1.0);
    }
    else
    {
        //find color in the configured gradient for the top of the bar
        int color = int((gradient_count - 1) * y);

        //find where on y this and next color is supposed to be
        float y_min = float(color) / (gradient_count - 1.0);
        float y_max = float(color + 1) / (gradient_count - 1.0);

        //make a solid color for the entire bar
        bar_color = vec4(normalize_C(y, gradient_colors[color], gradient_colors[color + 1], y_min, y_max), 1.0);
    }


    //draw the bar up to current height
    if (y > fragCoord.y)
    {
        //make some space between bars based on settings
        if (x > (bar + 1) * (bar_size) - bar_spacing)
        {
            fragColor = vec4(bg_color,1.0);
        }
        else
        {
            fragColor = bar_color;
        }
    }
    else
    {
        fragColor = vec4(bg_color,1.0);
    }
}