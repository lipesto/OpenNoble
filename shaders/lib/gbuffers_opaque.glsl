#include "/lib/stolen_code/octa_enc.glsl"

uniform sampler2D gtexture;
uniform sampler2D specular;
uniform sampler2D normals;

uniform float alphaTestRef;


/* RENDERTARGETS: 0,1,2,3 */
layout(location = 0) out vec4   albedoOut;      //rgba8
layout(location = 1) out vec4   materialOut;    //rgba8
layout(location = 2) out uvec2  metadataOut;    //rg32ui
layout(location = 3) out vec3   emissionOut;    //11_11_10f

void storeSurfaceData(vec3 albedo, vec3 normal, vec3 trueNormal, vec3 emission, vec3 material, vec2 lightmap, float ao) {
    albedoOut.rgb = albedo;
    albedoOut.a = ao;
    materialOut.rgb = material;
    emissionOut = emission;
    metadataOut.x = packSnorm2x16(octa_encode(normal));
    metadataOut.y = packUnorm4x8(vec4(octa_encode(trueNormal) * 0.5 + 0.5, lightmap));

    materialOut.a = 0;
}



vec3 getNormal(vec2 textureNormal, mat3 TBN) {
    vec3 normal;
    normal.xy = textureNormal.xy * 2.0 - 1.0;
    normal.z = sqrt(1.0 - clamp(dot(normal.xy, normal.xy), 0.0, 1.0));
    normal = normalize(TBN*normal);
    return normal;
}

vec3 getEmission(vec3 albedo, float labEmission) {
    return pow(albedo, vec3(2.2)) * fract(labEmission);
}