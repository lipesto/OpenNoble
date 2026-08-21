
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