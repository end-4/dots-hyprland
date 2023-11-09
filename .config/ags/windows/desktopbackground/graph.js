const { Gdk, Gtk } = imports.gi;
const Lang = imports.lang;
import { App, Service, Utils, Widget } from '../../imports.js';
const { execAsync, exec } = Utils;
const { Box, Label } = Widget;

const NUM_OF_VERTICES = 30;
const NUM_OF_EDGES = 29;
// Vertices
var vertices = [];
for (var i = 0; i < NUM_OF_VERTICES; i++) {
    vertices.push([
        Math.floor(Math.random() * SCREEN_WIDTH),
        Math.floor(Math.random() * SCREEN_HEIGHT)
    ]);
}
// Edges
function generateRandomEdges(numVertices, numEdges) { // TODO: make sure whole graph is connected
    var edges = new Set();
    var vertices = [];

    // Generate vertices
    for (var i = 0; i < numVertices; i++) {
        vertices.push(i);
    }

    // Generate random distinct edges
    while (edges.size < numEdges) {
        var randomVertex1 = vertices[Math.floor(Math.random() * numVertices)];
        var randomVertex2 = vertices[Math.floor(Math.random() * numVertices)];

        // Ensure the two vertices are distinct and the edge doesn't already exist
        if (randomVertex1 !== randomVertex2) {
            var edge = [randomVertex1, randomVertex2].sort();
            edges.add(edge.join(','));
        }
    }

    return Array.from(edges).map(edge => edge.split(',').map(Number));
}

var edges = generateRandomEdges(NUM_OF_VERTICES, NUM_OF_EDGES);

export default () => Box({
    hpack: 'fill',
    vpack: 'fill',
    homogeneous: true,
    children: [
        Widget.DrawingArea({
            className: 'bg-graph',
            setup: (area) => {
                area.connect('draw', Lang.bind(area, (area, cr) => {
                    // area.set_size_request(SCREEN_WIDTH, SCREEN_HEIGHT);
                    // console.log('allocated width/height:', area.get_allocated_width(), '/', area.get_allocated_height())
                    const styleContext = area.get_style_context();
                    const color = styleContext.get_property('color', Gtk.StateFlags.NORMAL);
                    const backgroundColor = styleContext.get_property('background-color', Gtk.StateFlags.NORMAL);
                    const radius = area.get_style_context().get_property('border-radius', Gtk.StateFlags.NORMAL);
                    const borderWidth = area.get_style_context().get_border(Gtk.StateFlags.NORMAL).left; // ur going to write border-width: something anyway

                    cr.setSourceRGBA(backgroundColor.red, backgroundColor.green, backgroundColor.blue, backgroundColor.alpha);
                    cr.rectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
                    cr.fill();
                    cr.setSourceRGBA(color.red, color.green, color.blue, color.alpha);
                    // Draw edges
                    cr.setLineWidth(borderWidth);
                    console.log("line width:", borderWidth);
                    for (var i = 0; i < NUM_OF_EDGES; i++) {
                        console.log(vertices[edges[i][0]][0], vertices[edges[i][0]][1], '->', vertices[edges[i][1]][0], vertices[edges[i][1]][1])
                        cr.moveTo(vertices[edges[i][0]][0], vertices[edges[i][0]][1]);
                        cr.lineTo(vertices[edges[i][1]][0], vertices[edges[i][1]][1]);
                        cr.stroke();
                    }
                    // Draw vertices
                    for (var i = 0; i < NUM_OF_VERTICES; i++) {
                        cr.arc(vertices[i][0], vertices[i][1], radius, 0, 2 * Math.PI)
                        cr.fill()
                    }
                }))
            }
        })
    ]
})
