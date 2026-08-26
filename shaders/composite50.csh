#version 430

layout (local_size_x = 16, local_size_y = 16) in;

#include "/lib/uniforms.glsl"
#include "/lib/constants.glsl"
#include "/lib/utils.glsl"

#include "/lib/stolen_code/octa_enc.glsl"

uniform sampler3D voxelcolortex;
uniform usampler3D voxeloccupancytex;

layout(rgba16f) uniform image2D colorimg15;

const ivec3 voxelizedVolumeSize = ivec3(256, 128, 256);

#include "/lib/ray_tracing.glsl"

#include "/lib/stolen_code/ray.glsl"
#include "/lib/stolen_code/noise.glsl"

#include "/lib/sphere.glsl"
#include "/lib/stolen_code/atmosphere.glsl"

void main() {
    ivec2 fragCoord = ivec2(gl_GlobalInvocationID);
    float depth = texelFetch(depthtex0, fragCoord, 0).r;
    if (depth == 1.0) {
        vec3 dir = createRay((fragCoord + 0.5) * resolutionInv, gbufferProjectionInverse, gbufferModelViewInverse);
        vec3 color = L_lutWithCelestials(dir);
        imageStore(colorimg15, fragCoord, vec4(color, 0));
        return;
    }

    vec4 posScreen = vec4((fragCoord + 0.5) * resolutionInv, depth, 1) * 2.0 - 1.0;
    vec4 posView = gbufferProjectionInverse * posScreen;
    posView.xyz /= posView.w;
    vec3 position = mat3(gbufferModelViewInverse) * posView.xyz;


    vec3 albedo = pow(texelFetch(colortex0, fragCoord, 0).rgb, vec3(2.2));
    vec3 material = texelFetch(colortex1, fragCoord, 0).rgb;
    vec3 emission = texelFetch(colortex2, fragCoord, 0).rgb;
    vec3 normal = octa_decode(unpackSnorm2x16(texelFetch(colortex3, fragCoord, 0).r));
    vec3 trueNormal = octa_decode(unpackUnorm4x8(texelFetch(colortex3, fragCoord, 0).g).xy * 2.0 - 1.0);
    float ao = texelFetch(colortex0, fragCoord, 0).a;
    vec2 lightmap = unpackUnorm4x8(texelFetch(colortex3, fragCoord, 0).g).zw;

    float roughness = pow(1.0 - material.x, 2.0);

    vec3 O = position + cameraPositionFract + voxelizedVolumeSize/2 + trueNormal * 0.01 + gbufferModelViewInverse[3].xyz;


    vec3 accumulatedDiffuse = vec3(0);
    vec3 accumulatedSpecular = vec3(0);

    #define samples 16 // [1 16 64 128 256]
    for (int s = 0; s < samples; s++) {
        vec4 rand = texelFetch(noisetex, ivec2((fragCoord + 0.5) + vec2(s * 10, s * 228)) & 255, 0);
        {
        vec3 D = cosineDirection(normal, rand.xy);

        bool hit;
        ivec3 P = ray(O, D, hit);

        vec4 voxelColor = texelFetch(voxelcolortex, ivec3(P), 0);
        vec3 incomingLight = hit ? (pow(voxelColor.rgb, vec3(2.2)) * voxelColor.a) : L_lutWithCelestials(normalize(D));
        accumulatedDiffuse += incomingLight;
        }

        {
        vec3 offset = rand.xyz * 2.0 - 1.0;
        vec3 D = reflect(normalize(position), normal) + offset * abs(offset) / sqrt(2.0) * roughness;
        bool hit;
        ivec3 P = ray(O, D, hit);
        vec4 voxelColor = texelFetch(voxelcolortex, ivec3(P), 0);
        vec3 incomingLight = hit ? (pow(voxelColor.rgb, vec3(2.2)) * voxelColor.a) : L_lutWithCelestials(normalize(D));
        accumulatedSpecular += incomingLight;
        }
    }

    accumulatedDiffuse /= samples;
    accumulatedSpecular /= samples;

    float fresnel = fresnelSchlick(clamp(-dot(normal, normalize(position)), 0.0, 1.0), material.y);

    vec3 color = mix(albedo * accumulatedDiffuse, accumulatedSpecular, fresnel);
    if (material.y > 229.0 / 255.0) color = accumulatedSpecular * albedo;

    color += emission;

    imageStore(colorimg15, fragCoord, vec4(color, 0));
}
