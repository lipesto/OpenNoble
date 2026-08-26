#version 430 compatibility

const ivec3 voxelizedVolumeSize = ivec3(256, 128, 256);

layout (rgba8) uniform image3D voxelcolorimg;
layout (r32ui) uniform uimage3D voxeloccupancyimg;

uniform sampler2D gtexture;

uniform vec3 cameraPositionFract;

in vec2 mc_Entity;
in vec2 mc_midTexCoord;
in vec4 at_midBlock;

void main() {
        return;
        vec3 centerPosition = gl_Vertex.xyz + cameraPositionFract + at_midBlock.xyz / 64.0;
        vec3 midColor = textureLod(gtexture, mc_midTexCoord, 4).rgb * gl_Color.rgb;
        ivec3 voxel = ivec3(floor(centerPosition)) + voxelizedVolumeSize / 2;
        float emission = at_midBlock.w / 255.0;

        imageStore(voxelcolorimg, voxel, vec4(midColor, at_midBlock.w / 16.0));
        imageAtomicOr(voxeloccupancyimg, ivec3(voxel.x, voxel.y >> 5, voxel.z), 1u << (voxel.y & 31));
        return;
}
