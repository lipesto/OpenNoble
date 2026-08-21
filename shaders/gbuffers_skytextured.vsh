#version 430 compatibility

out vertex {
    vec2 atlasCoordinates;
};

void main() {   
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    atlasCoordinates = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}