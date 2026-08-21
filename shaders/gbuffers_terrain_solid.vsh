#version 430 compatibility

#include "/lib/gbuffers_vertex.glsl"

in vec2 mc_Entity;

out vertex {
    vec2 uv;
    vec2 lightmap;
    vec4 vertexColor;
    flat mat3 TBN;
    flat int ID;
};


void main(){
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    uv = getUV();
    lightmap = getLightmap();
    vertexColor = gl_Color;
    TBN = getTBN();
    ID = int(mc_Entity);
}