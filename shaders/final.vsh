#version 430
void main() {gl_Position = vec4(mat4x2(-1,-1,1,-1,1,1,-1,1)[gl_VertexID], 0.0, 1.0);}