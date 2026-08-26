#version 430

layout (local_size_x = 16, local_size_y = 16) in;

#include "/lib/uniforms.glsl"
#include "/lib/constants.glsl"
#include "/lib/utils.glsl"

#include "/lib/gbuffer_data.glsl"



layout(rgba16f) uniform image2D colorimg15;

const ivec3 voxelizedVolumeSize = ivec3(256, 128, 256);

#include "/lib/ray_tracing.glsl"

#include "/lib/stolen_code/ray.glsl"
#include "/lib/stolen_code/noise.glsl"
#include "/lib/random.glsl"

#include "/lib/sphere.glsl"
#include "/lib/stolen_code/atmosphere.glsl"

void main() {
    return;
    ivec2 fragCoord = ivec2(gl_GlobalInvocationID);
    float depth = texelFetch(depthtex0, fragCoord, 0).r;

    vec4 posScreen = vec4((fragCoord + 0.5) * resolutionInv, depth, 1) * 2.0 - 1.0;
    vec4 posView = gbufferProjectionInverse * posScreen;
    posView.xyz /= posView.w;
    vec3 position = mat3(gbufferModelViewInverse) * posView.xyz;

    vec3 rayOrigin = cameraPositionFract + voxelizedVolumeSize/2 + gbufferModelViewInverse[3].xyz;
    vec3 rayDir = normalize(position);

    bool hit;
    ivec3 P = ray(rayOrigin, rayDir, hit);
    vec2 uv = intersectVoxel(rayOrigin, rayDir, P);

    uint p = texelFetch(voxeluvtex, P, 0).x;
    vec2 voxelMidCoord = vec2(p & 0x3FFF, (p>>14) & 0x3FFF) / float(16128);
    float size = exp2(p >> 28);

    vec4 color = textureLod(colortex10, voxelMidCoord + (uv - 0.5) / textureSize(colortex10, 0) * size, 0);

    vec4 voxelColor = texelFetch(voxelcolortex, ivec3(P), 0);

    vec3 incomingLight = hit ? color.rgb * voxelColor.rgb : L_lutWithCelestials(rayDir);

    imageStore(colorimg15, fragCoord, vec4(incomingLight * 0.01, 1));
}
