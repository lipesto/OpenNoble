#version 430 compatibility

uniform sampler2D lightmap;

out vertex {
    vec2 atlasCoordinates;
    vec3 lightmapColor;
    vec4 vertexColor;
};

void main() {
    vec2 lightmapCoordinates = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    atlasCoordinates = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lightmapColor = textureLod(lightmap, lightmapCoordinates, 0).rgb;
    vertexColor = gl_Color;
    
}