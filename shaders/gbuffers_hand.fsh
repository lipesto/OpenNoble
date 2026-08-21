#version 430

uniform sampler2D gtexture;

uniform vec4 entityColor;
uniform float alphaTestRef;

in vertex {
    vec2 atlasCoordinates;
    vec4 vertexColor;
};


/* DRAWBUFFERS:0 */
out vec4 color;

void main() {   
    color = texture(gtexture, atlasCoordinates);
    
    if (color.a < alphaTestRef) discard;
    
    color *= vertexColor;
}
