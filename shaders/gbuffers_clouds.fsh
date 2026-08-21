#version 430

in vertex {
    vec4 vertexColor;
};


/* DRAWBUFFERS:0 */
out vec4 color;

void main() {   
    color = vertexColor;
}
