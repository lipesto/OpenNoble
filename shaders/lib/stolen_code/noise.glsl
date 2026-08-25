// https://blog.frost.kiwi/GLSL-noise-and-radial-gradient/
float interleavedGradientNoise(vec2 uv) {
    const vec2 magic = vec2(0.06711056, 0.00583715);
    return fract(52.9829189 * fract(dot(uv, magic)));
}
