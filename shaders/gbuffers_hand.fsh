#version 430

#include "/lib/gbuffers_surface.glsl"

in vertex {
    vec2 uv;
    vec2 lightmap;
    vec4 vertexColor;
    flat mat3 TBN;
};

void main() {
    vec4 textureAlbedo = texture(gtexture, uv);
    vec4 textureSpecular = texture(specular, uv);
    vec4 textureNormals = texture(normals,  uv);

    if (textureAlbedo.a < alphaTestRef) discard;

    vec3 albedo = textureAlbedo.rgb * vertexColor.rgb;
    vec3 normal = getNormal(textureNormals.xy, TBN);
    vec3 emission = getEmission(albedo, textureSpecular.a);

    storeSurfaceData(albedo, normal, TBN[2], emission, textureSpecular.rgb, lightmap, 1.0);
}
