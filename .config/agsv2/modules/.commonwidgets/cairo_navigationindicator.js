const { Gtk } = imports.gi;
const Lang = imports.lang;
import Widget from 'resource:///com/github/Aylur/ags/widget.js';

// min-height/min-width for height/width
// background-color/color for background/indicator color
// padding for pad of indicator
// font-size for selected index (0-based)
export const NavigationIndicator = ({count, vertical, ...props}) => Widget.DrawingArea({
    ...props,
    setup: (area) => {
        const styleContext = area.get_style_context();
        const width = Math.max(styleContext.get_property('min-width', Gtk.StateFlags.NORMAL), area.get_allocated_width());
        const height = Math.max(styleContext.get_property('min-height', Gtk.StateFlags.NORMAL), area.get_allocated_height());
        area.set_size_request(width, height);

        area.connect('draw', Lang.bind(area, (area, cr) => {
            const styleContext = area.get_style_context();
            const width = Math.max(styleContext.get_property('min-width', Gtk.StateFlags.NORMAL), area.get_allocated_width());
            const height = Math.max(styleContext.get_property('min-height', Gtk.StateFlags.NORMAL), area.get_allocated_height());
            // console.log('allocated width/height:', area.get_allocated_width(), '/', area.get_allocated_height())
            area.set_size_request(width, height);
            const paddingLeft = styleContext.get_padding(Gtk.StateFlags.NORMAL).left;
            const paddingRight = styleContext.get_padding(Gtk.StateFlags.NORMAL).right;
            const paddingTop = styleContext.get_padding(Gtk.StateFlags.NORMAL).top;
            const paddingBottom = styleContext.get_padding(Gtk.StateFlags.NORMAL).bottom;

            const selectedCell = styleContext.get_property('font-size', Gtk.StateFlags.NORMAL);

            let cellWidth = width;
            let cellHeight = height;
            if (vertical) cellHeight /= count;
            else cellWidth /= count;
            const indicatorWidth = cellWidth - paddingLeft - paddingRight;
            const indicatorHeight = cellHeight - paddingTop - paddingBottom;

            const background_color = styleContext.get_property('background-color', Gtk.StateFlags.NORMAL);
            const color = styleContext.get_property('color', Gtk.StateFlags.NORMAL);
            cr.setLineWidth(2);
            // Background
            cr.setSourceRGBA(background_color.red, background_color.green, background_color.blue, background_color.alpha);
            cr.rectangle(0, 0, width, height);
            cr.fill();

            // The indicator line
            cr.setSourceRGBA(color.red, color.green, color.blue, color.alpha);
            if (vertical) {
                cr.rectangle(paddingLeft, paddingTop + cellHeight * selectedCell + indicatorWidth / 2, indicatorWidth, indicatorHeight - indicatorWidth);
                cr.stroke();
                cr.rectangle(paddingLeft, paddingTop + cellHeight * selectedCell + indicatorWidth / 2, indicatorWidth, indicatorHeight - indicatorWidth);
                cr.fill();
                cr.arc(paddingLeft + indicatorWidth / 2, paddingTop + cellHeight * selectedCell + indicatorWidth / 2, indicatorWidth / 2, Math.PI, 2 * Math.PI);
                cr.fill();
                cr.arc(paddingLeft + indicatorWidth / 2, paddingTop + cellHeight * selectedCell + indicatorHeight - indicatorWidth / 2, indicatorWidth / 2, 0, Math.PI);
                cr.fill();
            }
            else {
                cr.rectangle(paddingLeft + cellWidth * selectedCell + indicatorHeight / 2, paddingTop, indicatorWidth - indicatorHeight, indicatorHeight);
                cr.stroke();
                cr.rectangle(paddingLeft + cellWidth * selectedCell + indicatorHeight / 2, paddingTop, indicatorWidth - indicatorHeight, indicatorHeight);
                cr.fill();
                cr.arc(paddingLeft + cellWidth * selectedCell + indicatorHeight / 2, paddingTop + indicatorHeight / 2, indicatorHeight / 2, 0.5 * Math.PI, 1.5 * Math.PI);
                cr.fill();
                cr.arc(paddingLeft + cellWidth * selectedCell + indicatorWidth - indicatorHeight / 2, paddingTop + indicatorHeight / 2, indicatorHeight / 2, -0.5 * Math.PI, 0.5 * Math.PI);
                cr.fill();
            }
        }))
    },
})


