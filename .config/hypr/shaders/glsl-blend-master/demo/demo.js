

var glslify = require('glslify');
var createShader = require( 'gl-shader' );
var modes = require( '../modes' );

var createBlendShader = function( gl ){
    var shader = createShader( gl,
        glslify( './blend.vert' ),
        glslify( './blend.frag' )
    );

    shader.bind();
    shader.uniforms.blendMode = 1;
    shader.uniforms.blendOpacity = 0.5;

    return shader;
};

//create our WebGL test example
var blendDemo = require('gl-blend-demo')({
    shader: createBlendShader
});

//add to DOM
require('domready')(function() {

    var modeSelect = document.createElement( 'select' );
    var modeOpacity = document.createElement( 'input' );
    modeOpacity.setAttribute( 'type','range' );
    blendDemo.canvas.style.display = 'block';

    modeSelect.innerHTML = '';
    for( var mode in modes ){
        modeSelect.innerHTML += '<option style="margin:6px;" value="' + modes[mode] + '">' + mode + '</option>';
    }

    modeSelect.addEventListener( 'change', function(event){
        blendDemo.shader.uniforms.blendMode = event.target.value;
        blendDemo.render();
    });

    modeOpacity.addEventListener( 'input', function(event){
        var opacity = event.target.value / 100;
        if( !isNaN(opacity) ){
            blendDemo.shader.uniforms.blendOpacity = opacity;
            blendDemo.render();
        }          
    });

    document.body.style.margin = '0px';
    document.body.appendChild( modeSelect );

    document.body.appendChild( modeOpacity );
    document.body.appendChild(blendDemo.canvas);
});