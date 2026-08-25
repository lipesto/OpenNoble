#version 460

#include "lib/uniforms.glsl"
#include "lib/constants.glsl"
#include "lib/utils.glsl"
#include "lib/sphere.glsl"
#include "lib/stolen_code/atmosphere.glsl"

layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in;
const ivec3 workGroups = ivec3(8, 32, 1);

layout(rgba16f, binding = 0) writeonly uniform image2D luti_transmittance;

void main() {
    ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
    vec2 size = vec2(imageSize(luti_transmittance));

    if (coord.x >= size.x || coord.y >= size.y) return;

    vec2 uv = (vec2(coord) + 0.5) / size;

    float r;
    float mu;
    unmap_trans_lut(uv, r, mu);

    r = clamp(r, R_PLANET, R_ATMOS);

    vec3 x = vec3(0.0, r, 0.0);
    vec3 v = vec3(sqrt(max(0.0, 1.0 - sqr(mu))), mu, 0.0);

    SphereHit hit = raySphere(x, v, R_ATMOS);

    vec3 p = x + hit.exit * v;
    vec3 transmittance = T(x, p);

    imageStore(luti_transmittance, coord, vec4(transmittance, 1.0));
}
