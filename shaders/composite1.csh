#version 460

#include "lib/uniforms.glsl"
#include "lib/constants.glsl"
#include "lib/utils.glsl"
#include "lib/sphere.glsl"
#include "lib/stolen_code/atmosphere.glsl"

layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in;
const ivec3 workGroups = ivec3(32, 16, 1);

layout(rgba32f, binding = 0) writeonly uniform image2D luti_view;

void main() {
    ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
    vec2 size = vec2(imageSize(luti_view));

    if (coord.x >= size.x || coord.y >= size.y) return;

    vec2 uv = (vec2(coord) + 0.5) / size;

    vec3 dir;
    unmap_view_lut(uv, sunDir, normalize(ATMOS_CAM_POS), dir);

    vec3 color = L(dir);

    imageStore(luti_view, coord, vec4(color, 1.0));
}
