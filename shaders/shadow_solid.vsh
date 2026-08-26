#version 430 compatibility

const ivec3 voxelizedVolumeSize = ivec3(256, 128, 256);

layout (rgba8) uniform image3D voxelcolorimg;
layout (r32ui) uniform uimage3D voxeloccupancyimg;
layout (r32ui) uniform uimage3D voxeluvimg;


uniform sampler2D gtexture;

uniform vec3 cameraPositionFract;
uniform ivec2 atlasSize;

in vec2 mc_Entity;
in vec2 mc_midTexCoord;
in vec4 at_midBlock;

void main() {

        vec3 centerPosition = gl_Vertex.xyz + cameraPositionFract + at_midBlock.xyz / 64.0;
        vec3 midColor = gl_Color.rgb;
        ivec3 voxel = ivec3(floor(centerPosition)) + voxelizedVolumeSize / 2;
        float emission = at_midBlock.w / 255.0;
        uvec2 p = uvec2(fract(mc_midTexCoord) * 16128);
        
        //I have no idea if it works properly
        vec2 cornerUV = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        vec2 tileSize = abs(mc_midTexCoord - cornerUV) * atlasSize;
        float avgsize = (tileSize.x + tileSize.y) * 0.5;
        uint size = uint(clamp(log2(avgsize) + 1.5, 0.0, 15.0));


        imageStore(voxelcolorimg, voxel, vec4(midColor, at_midBlock.w / 16.0));
        imageAtomicOr(voxeloccupancyimg, ivec3(voxel.x, voxel.y >> 5, voxel.z), 1u << (voxel.y & 31));
        imageStore(voxeluvimg, voxel, uvec4(p.x | p.y << 14 | size << 28));
        return;
}
