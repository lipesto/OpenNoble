#version 430

/*
const int colortex0Format =     RGBA8;
const int colortex1Format =     RGBA8;
const int colortex2Format =     R11F_G11F_B10F;
const int colortex3Format =     RG32UI;
const int colortex15Format =    RGBA16F;

const bool colortex0Clear =     false;
const bool colortex1Clear =     false;
const bool colortex2Clear =     false;
const bool colortex3Clear =     false;

const float voxelDistance = 48.0;
const float sunPathRotation = -30.0;
*/

#include "/lib/uniforms.glsl"
#include "/lib/constants.glsl"
#include "/lib/utils.glsl"
#include "/lib/stolen_code/noise.glsl"


out vec3 color;
void main() {
    color = texelFetch(colortex15, ivec2(gl_FragCoord), 0).rgb;
    color *= exp2(6);
    color /= color + 1.0;
    color = pow(color, vec3(1.0 / 2.2));
    color += (1.0 / 255.0) * interleavedGradientNoise(gl_FragCoord.xy) - (0.5 / 255.0);
}
