

// https://vectrx.substack.com/p/lcg-xs-fast-gpu-rng
float rnd(inout uint seed) {
  seed = seed * 747796405u + 2891336453u;
  const float MaxInt = 16777216.0;
  return float(seed >> 8) / MaxInt;
}

uint hash67(vec3 p) {
    p = p * 0.6767 + dot(p, p + 67.67);
    return floatBitsToUint(p.x * p.y + p.z);
}