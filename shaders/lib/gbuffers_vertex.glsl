in vec4 at_tangent;
uniform mat4 gbufferModelViewInverse;
mat3 getTBN() {
    mat3 TBN;
    TBN[2] = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));
    TBN[0] = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * at_tangent.xyz));
    TBN[1] = normalize(cross(TBN[0], TBN[2]) * at_tangent.w);
    return TBN;
}

vec2 getUV() {
    return (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}

vec2 getLightmap() {
    return (gl_MultiTexCoord1.xy - 8.0) / 232.0;
}