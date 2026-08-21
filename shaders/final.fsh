#version 430

#include "/lib/uniforms.glsl"

/*  
const int colortex0Format =     RGBA8;
const int colortex1Format =     RGBA8;
const int colortex2Format =     R11F_G11F_B10F;
const int colortex3Format =     RG32UI;

const bool colortex0Clear =     false;
const bool colortex1Clear =     false;
const bool colortex2Clear =     false;
const bool colortex3Clear =     false;
*/

#include "/lib/stolen_code/octa_enc.glsl"

uniform sampler3D voxelcolortex;
uniform usampler3D voxeloccupancytex;

const ivec3 voxelizedVolumeSize = ivec3(256, 128, 256);

out vec3 color;
void main() {

    float depth = texelFetch(depthtex0, ivec2(gl_FragCoord), 0).r;
    vec4 posScreen = vec4(gl_FragCoord.xy * resolutionInv, depth, 1) * 2.0 - 1.0;
    vec4 posView = gbufferProjectionInverse * posScreen;
    posView.xyz /= posView.w;
    vec3 position = mat3(gbufferModelViewInverse) * posView.xyz + gbufferModelViewInverse[3].xyz;


    vec3 albedo = pow(texelFetch(colortex0, ivec2(gl_FragCoord), 0).rgb, vec3(2.2));
    vec3 material = texelFetch(colortex1, ivec2(gl_FragCoord), 0).rgb;
    vec3 emission = texelFetch(colortex2, ivec2(gl_FragCoord), 0).rgb;
    vec3 normal = octa_decode(unpackSnorm2x16(texelFetch(colortex3, ivec2(gl_FragCoord), 0).r));
    vec3 trueNormal = octa_decode(unpackUnorm4x8(texelFetch(colortex3, ivec2(gl_FragCoord), 0).g).xy * 2.0 - 1.0);
    float ao = texelFetch(colortex0, ivec2(gl_FragCoord), 0).a;
    vec2 lightmap = unpackUnorm4x8(texelFetch(colortex3, ivec2(gl_FragCoord), 0).g).zw;

    color = texelFetch(voxelcolortex, ivec3(position + cameraPositionFract + voxelizedVolumeSize/2 - trueNormal * 0.1), 0).rgb;
}