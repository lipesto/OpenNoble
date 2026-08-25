struct SphereHit {
    float entry;
    float exit;
};

SphereHit raySphere(vec3 origin, vec3 dir, float radius) {
    float b = dot(origin, dir);
    float c = dot(origin, origin) - radius * radius;

    float d = b * b - c;
    if (d < 0.0) return SphereHit(1e5, -1e5);
    d = sqrt(d);

    return SphereHit(-b - d, -b + d);
}

bool raySphereShadow(vec3 origin, vec3 dir, float radius) {
    return dot(origin, dir) < 0.0 && length(cross(origin, dir)) < radius;
}

const float GOLDEN_ANGLE = 2 * PI / sqr((1 + sqrt(5)) / 2);

vec3 sphereDir(int i, int N) {
    float z = 1.0 - 2.0 * (float(i) + 0.5) / N;
    float r = sqrt(max(0.0, 1.0 - sqr(z)));
    float phi = GOLDEN_ANGLE * float(i);
    return vec3(r * cos(phi), z, r * sin(phi));
}
