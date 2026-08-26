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
    ivec2 fragCoord = ivec2(gl_GlobalInvocationID);
    float depth = texelFetch(depthtex0, fragCoord, 0).r;

    vec4 posScreen = vec4((fragCoord + 0.5) * resolutionInv, depth, 1) * 2.0 - 1.0;
    vec4 posView = gbufferProjectionInverse * posScreen;
    posView.xyz /= posView.w;
    vec3 position = mat3(gbufferModelViewInverse) * posView.xyz;

    if (depth == 1.0) {
        vec3 dir = normalize(position);
        vec3 color = L_lutWithCelestials(dir);
        imageStore(colorimg15, fragCoord, vec4(color, 0));
        return;
    }

    
    gbufferData gdata = readGbufferData(colortex0, colortex1, colortex2, fragCoord);
    vec3 emission = texelFetch(colortex3, fragCoord, 0).rgb;
    bool isMetal = gdata.f0 > labPBRMetalThreshold;

    vec3 rayOrigin = position + cameraPositionFract + voxelizedVolumeSize/2 + gdata.trueNormal * 0.01 + gbufferModelViewInverse[3].xyz;
    vec3 viewDir = normalize(position);

    vec3 accumulatedDiffuse = vec3(0);
    vec3 accumulatedSpecular = vec3(0);

    uint seed = hash67(vec3(fragCoord, frameCounter * 0));

    #define samples 16 // [1 16 64 128 256]
    for (int s = 0; s < samples; s++) {
        if (!isMetal) {
        vec3 rayDir = cosineDirection(gdata.normal, vec2(rnd(seed), rnd(seed)));

        bool hit;
        ivec3 P = ray(rayOrigin, rayDir, hit);
        

        vec3 incomingLight = hit ? hitColor(rayOrigin, rayDir, P) : L_lutWithCelestials(rayDir) * gdata.lightmap.y;
        accumulatedDiffuse += incomingLight;
        }

        {
        vec3 offset = vec3(rnd(seed), rnd(seed), rnd(seed)) * 2.0 - 1.0;
        vec3 rayDir = normalize(reflect(viewDir, gdata.normal) + offset * abs(offset) / sqrt(2.0) * gdata.roughness);
        bool hit;
        ivec3 P = ray(rayOrigin, rayDir, hit);

        vec3 incomingLight = hit ? hitColor(rayOrigin, rayDir, P) : L_lutWithCelestials(rayDir) * gdata.lightmap.y;
        accumulatedSpecular += incomingLight;
        }
    }

    accumulatedDiffuse /= samples;
    accumulatedSpecular /= samples;

    float fresnel = fresnelSchlick(clamp(-dot(gdata.normal, normalize(position)), 0.0, 1.0), gdata.f0);

    vec3 color = mix(gdata.albedo * accumulatedDiffuse, accumulatedSpecular, fresnel);
    if (isMetal) color = accumulatedSpecular * gdata.albedo;

    color += emission;

    imageStore(colorimg15, fragCoord, vec4(color, 0));
}
