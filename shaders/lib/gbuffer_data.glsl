#include "/lib/stolen_code/octa_enc.glsl"

const float labPBRMetalThreshold = 229.0 / 255.0;

struct gbufferData {
    vec3 albedo;
    float ao;
    float roughness;
    float f0;
    float SSS;
    vec3 normal;
    vec4 t;
    vec3 trueNormal;
    vec2 lightmap;
};

gbufferData unpackGbufferData(vec4 texData0, vec4 texData1, uvec2 texData2) {
    gbufferData data;
    data.albedo = pow(texData0.rgb, vec3(2.2));
    data.ao = texData0.a;
    data.roughness = pow(1.0 - texData1.r, 2.0);
    data.f0 = texData1.g;
    data.SSS = texData1.b;
    data.normal = octa_decode(unpackSnorm2x16(texData2.r));
    vec4 t = unpackUnorm4x8(texData2.g);
    data.trueNormal = octa_decode(t.xy * 2.0 - 1.0);
    data.lightmap = t.zw;
    return data;
}

gbufferData readGbufferData(sampler2D texture0, sampler2D texture1, usampler2D texture2, ivec2 fragCoord) {
    vec4 texData0 = texelFetch(texture0, fragCoord, 0);
    vec4 texData1 = texelFetch(texture1, fragCoord, 0);
    uvec2 texData2 = texelFetch(texture2, fragCoord, 0).rg;
    return unpackGbufferData(texData0, texData1, texData2);
}