// https://sibaku.github.io/computer-graphics/2017/01/10/Camera-Ray-Generation.html
vec3 createRay(vec2 px, mat4 invProj, mat4 invView) {
    vec2 pxNDS = px * 2.0 - 1.0;

    vec3 pointNDS = vec3(pxNDS, -1.0);
    vec4 pointNDSH = vec4(pointNDS, 1.0);

    vec4 dirEye = invProj * pointNDSH;
    dirEye.w = 0.0;

    vec3 dirWorld = (invView * dirEye).xyz;
    return normalize(dirWorld);
}
