#version 430 compatibility

uniform sampler2D lightmap;

out vertex {
    vec2 atlasCoordinates;
    vec4 vertexColor;
};

void main(){
    vec2 lightmapCoordinates = gl_MultiTexCoord1.xy / 256.0;
    vec3 lightmapColor = textureLod(lightmap, lightmapCoordinates, 0).rgb;
    
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    atlasCoordinates = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vertexColor = gl_Color;
    vertexColor.rgb *= lightmapColor;
}