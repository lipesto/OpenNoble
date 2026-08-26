
uniform sampler3D voxelcolortex;
uniform usampler3D voxeloccupancytex;
uniform usampler3D voxeluvtex;


float fresnelSchlick(float cosTheta, float F0) {
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

vec3 cosineDirection(vec3 normal, vec2 rnd) {
    float z = 1.0 - 2.0 * rnd.x;
    float phi = 2.0 * 3.1416 * rnd.y;
    float r = sqrt(1.0 - z * z);
    vec3 D = vec3(r * cos(phi), r * sin(phi), z);

    return normalize(normal + D);
}

ivec3 ray(vec3 O, vec3 D, out bool hit) {
    ivec3 stepSign = ivec3(sign(D));
    ivec3 P = ivec3(floor(O));
    vec3 stepMax = (P - O + max(stepSign, vec3(0))) / D;
    vec3 stepDelta = 1.0/abs(D);

    hit = false;
    for (int i = 0; i<48; i++){

        if ((stepMax.x< stepMax.y)&&(stepMax.x<stepMax.z)) {
            P.x += stepSign.x;
            stepMax.x += stepDelta.x;
        } else 
        if ((stepMax.x>=stepMax.y)&&(stepMax.y<stepMax.z)) {
            P.y += stepSign.y;
            stepMax.y += stepDelta.y;
        } else {
            P.z += stepSign.z;
            stepMax.z += stepDelta.z;
        }
        
        uint o = texelFetch(voxeloccupancytex, ivec3(P), 0).r;
        if (o == 1) {
            hit = true;
            break;
        }
        
    }
    return P;
}

vec2 intersectVoxel(vec3 rayOrigin, vec3 rayDir, vec3 voxel) {
    voxel -= rayOrigin;
    vec3 invDir = 1.0 / rayDir;
    vec3 tMin = voxel * invDir;
    vec3 tMax = voxel * invDir + invDir;
    vec3 t1 = min(tMin, tMax);

    float t = max(max(t1.x, t1.y), t1.z);
    int axis;
    if (t1.x == t)      axis = 0;
    else if (t1.y == t) axis = 1;
    else                axis = 2;
    vec3 hit = rayOrigin + rayDir * t;
    vec2 uv;
    if (axis==0) uv = hit.yz;
    if (axis==1) uv = hit.xz;
    if (axis==2) uv = hit.xy;
    uv = fract(uv);
    return uv;
};

vec3 hitColor(vec3 rayOrigin, vec3 rayDir, ivec3 voxel) {

    vec2 uv = intersectVoxel(rayOrigin, rayDir, voxel);

    uint p = texelFetch(voxeluvtex, voxel, 0).x;
    vec2 voxelMidCoord = vec2(p & 0x3FFF, (p>>14) & 0x3FFF) / float(16128);
    float size = exp2(p >> 28);

    vec2 coord = voxelMidCoord + (uv - 0.5) / textureSize(colortex10, 0) * size;

    vec4 voxelColor = texelFetch(voxelcolortex, voxel, 0);
    vec4 albedo = textureLod(colortex10, coord, 0) * voxelColor;
    vec4 material = textureLod(colortex11, coord, 0);
    vec3 emission = pow(albedo.rgb, vec3(2.2)) * fract(material.a);

    return emission;
}