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

const float voxelDistance = 48.0;
*/

#include "/lib/stolen_code/octa_enc.glsl"

uniform sampler3D voxelcolortex;
uniform usampler3D voxeloccupancytex;

const ivec3 voxelizedVolumeSize = ivec3(256, 128, 256);

vec3 cosineDirection(vec3 normal, vec2 rnd) {
    float z = 1.0 - 2.0 * rnd.x;
    float phi = 2.0 * 3.1416 * rnd.y;

    float r = sqrt(1.0 - z * z);

    vec3 D = vec3(r * cos(phi), r * sin(phi), z);

    return normalize(normal + D);
}


out vec3 color;
void main() {

    float depth = texelFetch(depthtex0, ivec2(gl_FragCoord), 0).r;
    vec4 posScreen = vec4(gl_FragCoord.xy * resolutionInv, depth, 1) * 2.0 - 1.0;
    vec4 posView = gbufferProjectionInverse * posScreen;
    posView.xyz /= posView.w;
    vec3 position = mat3(gbufferModelViewInverse) * posView.xyz;


    vec3 albedo = pow(texelFetch(colortex0, ivec2(gl_FragCoord), 0).rgb, vec3(2.2));
    vec3 material = texelFetch(colortex1, ivec2(gl_FragCoord), 0).rgb;
    vec3 emission = texelFetch(colortex2, ivec2(gl_FragCoord), 0).rgb;
    vec3 normal = octa_decode(unpackSnorm2x16(texelFetch(colortex3, ivec2(gl_FragCoord), 0).r));
    vec3 trueNormal = octa_decode(unpackUnorm4x8(texelFetch(colortex3, ivec2(gl_FragCoord), 0).g).xy * 2.0 - 1.0);
    float ao = texelFetch(colortex0, ivec2(gl_FragCoord), 0).a;
    vec2 lightmap = unpackUnorm4x8(texelFetch(colortex3, ivec2(gl_FragCoord), 0).g).zw;

    vec3 O = position + cameraPositionFract + voxelizedVolumeSize/2 + trueNormal * 0.01 + gbufferModelViewInverse[3].xyz;

    //vec3 D = reflect(normalize(position), normal); //mirror reflection

    vec3 accumulatedDiffuse = vec3(0);

    const int samples = 16;
    for (int s = 0; s < samples; s++) {
        vec4 rand = texelFetch(noisetex, ivec2(gl_FragCoord.xy + vec2(s * 10, s * 228)) & 255, 0);
        vec3 D = cosineDirection(normal, rand.xy);

        ivec3 stepSign = ivec3(sign(D));
        ivec3 P = ivec3(floor(O));
        vec3 stepMax = (P - O + max(stepSign, vec3(0))) / D;
        vec3 stepDelta = 1.0/abs(D);

        bool hit = false;
        for (int i = 0; i<48; i++){

            if ((stepMax.x< stepMax.y)&&(stepMax.x<stepMax.z)) {
                P.x += stepSign.x;
                stepMax.x += stepDelta.x;
            } else 
            if ((stepMax.x>=stepMax.y)&&(stepMax.y<stepMax.z)) {
                P.y += stepSign.y;
                stepMax.y += stepDelta.y;
            } else {
                P.z += stepSign.z;
                stepMax.z += stepDelta.z;
            }
            
            uint o = texelFetch(voxeloccupancytex, ivec3(P), 0).r;
            if (o == 1) {
                hit = true;
                break;
            }
            
        }
        vec4 voxelColor = hit ? texelFetch(voxelcolortex, ivec3(P), 0) * 1 : vec4(0.8, 0.9, 1.0, 0.1);
        vec3 incomingLight = pow(voxelColor.rgb, vec3(2.2)) * voxelColor.a;
        accumulatedDiffuse += incomingLight;
    }
    accumulatedDiffuse /= samples;

    color = albedo * accumulatedDiffuse + emission;

    color *= exp2(6);
    color /= color + 1.0;
    color = pow(color, vec3(1.0 / 2.0));
}