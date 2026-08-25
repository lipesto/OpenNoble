#version 460

#include "lib/uniforms.glsl"
#include "lib/constants.glsl"
#include "lib/utils.glsl"
#include "lib/sphere.glsl"
#include "lib/stolen_code/atmosphere.glsl"

layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in;
const ivec3 workGroups = ivec3(8, 8, 1);

layout(rgba16f, binding = 0) writeonly uniform image2D luti_multiscattering;

void main() {
    ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
    vec2 size = vec2(imageSize(luti_multiscattering));

    if (coord.x >= size.x || coord.y >= size.y) return;

    vec2 uv = (vec2(coord) + 0.5) / size;

    float theta;
    float h;
    unmap_ms_lut(uv, theta, h);

    vec3 x_s = vec3(0.0, h, 0.0);
    vec3 lightDir = vec3(sqrt(max(0.0, 1.0 - sqr(theta))), theta, 0.0);

    const int STEPS = 256;

    vec3 L_2 = vec3(0.0);
    vec3 f_ms = vec3(0.0);
    for (int i = 0; i < STEPS; i++) {
        vec3 d = sphereDir(i, STEPS);
        L_2 += L_prime(x_s, d, lightDir);
        f_ms += L_f(x_s, d);
    }

    L_2 /= STEPS;
    f_ms /= STEPS;

    vec3 F_ms = 1.0 / (1.0 - f_ms);
    vec3 psi_ms = L_2 * F_ms;

    imageStore(luti_multiscattering, coord, vec4(psi_ms, 1.0));
}
