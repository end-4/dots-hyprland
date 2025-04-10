// -- Styling --
// min-height for diameter
// min-width for trough stroke
// padding for space between trough and progress
// margin for space between widget and parent
// background-color for trough color
// color for progress color
// -- Usage --
// font size for progress value (0-100px) (hacky i know, but i want animations)
import { timeout } from 'astal';
import { Gdk, Gtk } from 'astal/gtk3';
import { DrawingAreaProps, DrawingArea } from 'astal/gtk3/widget';
import giCairo from 'cairo';

interface AnimatedCircProgProps extends Omit<DrawingAreaProps, 'child'> {
    initFrom?: number;
    initTo?: number;
    initAnimTime?: number;
    initAnimPoints?: number;
    extraSetup?: (area: DrawingArea) => void;
}

export function AnimatedCircProg({
    initFrom = 0,
    initTo = 0,
    initAnimTime = 2900,
    initAnimPoints = 1,
    extraSetup = () => {},
    ...rest
}: AnimatedCircProgProps) {
    function setup(area: DrawingArea) {
        const styleContext = area.get_style_context();
        const width = styleContext.get_property('min-height', Gtk.StateFlags.NORMAL) as number;
        const height = styleContext.get_property('min-height', Gtk.StateFlags.NORMAL) as number;
        const padding = styleContext.get_padding(Gtk.StateFlags.NORMAL).left;
        const marginLeft = styleContext.get_margin(Gtk.StateFlags.NORMAL).left;
        const marginRight = styleContext.get_margin(Gtk.StateFlags.NORMAL).right;
        const marginTop = styleContext.get_margin(Gtk.StateFlags.NORMAL).top;
        const marginBottom = styleContext.get_margin(Gtk.StateFlags.NORMAL).bottom;
        area.set_size_request(width + marginLeft + marginRight, height + marginTop + marginBottom);

        // Init animation
        if (initFrom != initTo) {
            area.css = `font-size: ${initFrom}px; transition: ${initAnimTime}ms linear;`;
            timeout(20, () => {
                area.css = `font-size: ${initTo}px;`;
            });
            const transitionDistance = initTo - initFrom;
            const oneStep = initAnimTime / initAnimPoints;
            area.css = `
                    font-size: ${initFrom}px;
                    transition: ${oneStep}ms linear;
                `;
            for (let i = 0; i < initAnimPoints; i++) {
                timeout(Math.max(10, i * oneStep), () => {
                    if (!area) return;
                    area.css =
                        initFrom != initTo
                            ? `font-size: ${initFrom + (transitionDistance / initAnimPoints) * (i + 1)}px;`
                            : '';
                });
            }
        } else area.css = 'font-size: 0px;';
        extraSetup(area);
    }

    function onDraw(area: DrawingArea, cr?: giCairo.Context) {
        if (!cr) return;

        const styleContext = area.get_style_context();
        const width = styleContext.get_property('min-height', Gtk.StateFlags.NORMAL) as number;
        const height = styleContext.get_property('min-height', Gtk.StateFlags.NORMAL) as number;
        const padding = styleContext.get_padding(Gtk.StateFlags.NORMAL).left;
        const marginLeft = styleContext.get_margin(Gtk.StateFlags.NORMAL).left;
        const marginRight = styleContext.get_margin(Gtk.StateFlags.NORMAL).right;
        const marginTop = styleContext.get_margin(Gtk.StateFlags.NORMAL).top;
        const marginBottom = styleContext.get_margin(Gtk.StateFlags.NORMAL).bottom;
        area.set_size_request(width + marginLeft + marginRight, height + marginTop + marginBottom);

        const progressValue = (styleContext.get_property('font-size', Gtk.StateFlags.NORMAL) as number) / 100.0;

        const bg_stroke = styleContext.get_property('min-width', Gtk.StateFlags.NORMAL) as number;
        const fg_stroke = bg_stroke - padding;
        const radius = Math.min(width, height) / 2.0 - Math.max(bg_stroke, fg_stroke) / 2.0;
        const center_x = width / 2.0 + marginLeft;
        const center_y = height / 2.0 + marginTop;
        const start_angle = -Math.PI / 2.0;
        const end_angle = start_angle + 2 * Math.PI * progressValue;
        const start_x = center_x + Math.cos(start_angle) * radius;
        const start_y = center_y + Math.sin(start_angle) * radius;
        const end_x = center_x + Math.cos(end_angle) * radius;
        const end_y = center_y + Math.sin(end_angle) * radius;

        // Draw background
        const background_color = styleContext.get_property('background-color', Gtk.StateFlags.NORMAL) as Gdk.RGBA;
        cr.setSourceRGBA(background_color.red, background_color.green, background_color.blue, background_color.alpha);
        cr.arc(center_x, center_y, radius, 0, 2 * Math.PI);
        cr.setLineWidth(bg_stroke);
        cr.stroke();

        if (progressValue == 0) return;

        // Draw progress
        const color = styleContext.get_property('color', Gtk.StateFlags.NORMAL) as Gdk.RGBA;
        cr.setSourceRGBA(color.red, color.green, color.blue, color.alpha);
        cr.arc(center_x, center_y, radius, start_angle, end_angle);
        cr.setLineWidth(fg_stroke);
        cr.stroke();

        // Draw rounded ends for progress arcs
        cr.setLineWidth(0);
        cr.arc(start_x, start_y, fg_stroke / 2, 0, 0 - 0.01);
        cr.fill();
        cr.arc(end_x, end_y, fg_stroke / 2, 0, 0 - 0.01);
        cr.fill();
    }

    return (
        <drawingarea
            css={initFrom != initTo ? `font-size: ${initFrom}px; transition: ${initAnimTime}ms linear;` : ''}
            setup={setup}
            onDraw={onDraw}
            {...rest}
        />
    );
}
