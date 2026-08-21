#version 430

uniform sampler2D gtexture;

in vertex {
    vec2 atlasCoordinates;
};


/* DRAWBUFFERS:0 */
out vec4 color;

void main() {   
    color = texture(gtexture, atlasCoordinates);
    if (color.a == 0.0) discard;
}
