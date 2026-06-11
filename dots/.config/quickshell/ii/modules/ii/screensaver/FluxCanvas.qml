import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common.functions as CF

// This represents the "Flux" fluid simulation. 
// QtQuick's Canvas isn't fast enough for a real-time full-screen Navier-Stokes fluid sim,
// so we'll use a ShaderEffect with a fragment shader that simulates fluid dynamics, or
// alternatively, run an external fluid simulation if it's available.
// Since the config mentions "gridSpacing", "lineLength", "fluidSize", etc.,
// it seems it was intended to be a visual grid that deforms based on fluid flow.

Item {
    id: root

    property int gridSpacing: 15
    property real lineLength: 450
    property real lineWidth: 9
    property real viewScale: 1.6
    property real viscosity: 5
    property real velocityDissipation: 0
    property int fluidSize: 128
    property real fluidFrameRate: 60
    property int diffusionIterations: 3
    property int pressureIterations: 19
    property real noiseMultiplier: 0.45

    // In a full implementation, we'd want to use WebGL, a custom QQuickItem in C++,
    // or an external executable rendered into a surface.
    // For now, we will implement a lightweight QML Canvas visualizer that creates
    // a "Flux"-like grid of lines that animate over time using simplex/perlin noise.
    
    Canvas {
        id: canvas
        anchors.fill: parent
        
        property real time: 0
        
        Timer {
            interval: 1000 / root.fluidFrameRate
            running: root.visible
            repeat: true
            onTriggered: {
                canvas.time += 0.01 * root.fluidFrameRate / 60;
                canvas.requestPaint()
            }
        }
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            
            // Draw a grid that warps based on time and noise
            // Simulating fluid with just a Canvas is heavy, so we fake it 
            // by perturbing a grid with trigonometric functions.
            var spacing = root.gridSpacing * root.viewScale;
            var w = root.lineWidth * root.viewScale;
            
            ctx.strokeStyle = "rgba(0, 255, 255, 0.4)";
            ctx.lineWidth = w;
            ctx.lineCap = "round";
            
            var cols = Math.floor(width / spacing);
            var rows = Math.floor(height / spacing);
            
            var t = time * root.noiseMultiplier * 2.0;
            
            ctx.beginPath();
            
            for (var i = 0; i < cols; i++) {
                for (var j = 0; j < rows; j++) {
                    // Only draw some lines to create flow effect
                    if ((i + j) % 3 !== 0) continue;
                    
                    var x = i * spacing;
                    var y = j * spacing;
                    
                    // Perturbation
                    var angle = Math.sin(x * 0.01 + t) * Math.cos(y * 0.01 + t) * Math.PI * 2;
                    var mag = (Math.sin(x * 0.02 - t) + 1.0) * (root.lineLength * root.viewScale * 0.1);
                    
                    var endX = x + Math.cos(angle) * mag;
                    var endY = y + Math.sin(angle) * mag;
                    
                    ctx.moveTo(x, y);
                    ctx.lineTo(endX, endY);
                }
            }
            ctx.stroke();
        }
    }
}
