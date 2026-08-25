// By Koteinik based on:
// "A Scalable and Production Ready Sky and Atmosphere Rendering Technique" by Hillaire (2020) (https://github.com/sebh/UnrealEngineSkyAtmosphere)
// "Precomputed Atmospheric Scattering" by Bruneton (2008) (https://github.com/ebruneton/precomputed_atmospheric_scattering)

const float R_PLANET = 6360.0;
const float R_ATMOS = 6460.0;
const vec3 ATMOS_CAM_POS = vec3(0.0, R_PLANET + 0.1, 0.0);

const vec3 GROUND_ALBEDO = vec3(0.3);

const vec3 SCATTER_RAY = vec3(5.802e-3, 13.558e-3, 33.1e-3);
const vec3 SCATTER_MIE = vec3(3.996e-3);
const vec3 SCATTER_OZONE = vec3(0.0);

const vec3 ABSORP_RAY = vec3(0.0);
const vec3 ABSORP_MIE = vec3(4.40e-3);
const vec3 ABSORP_OZONE = vec3(0.650e-3, 1.881e-3, 0.085e-3);

const float HEIGHT_RAY = 8;
const float HEIGHT_MIE = 1.2;
const float HEIGHT_MID_OZONE = 25;
const float WIDTH_OZONE = 15;

const float SUN_LUMINANCE = 3000; // make 1.6e9 if you are not afraid
const float SUN_ANGULAR_RADIUS = 0.00465;
const float SUN_ILLUMINANCE = SUN_LUMINANCE * PI * sqr(SUN_ANGULAR_RADIUS);

const float MOON_LUMINANCE = 50.0; // make 4e3 if you are not afraid
const float MOON_ANGULAR_RADIUS = 0.00495;
const float MOON_ILLUMINANCE = MOON_LUMINANCE * PI * sqr(MOON_ANGULAR_RADIUS);

const float MAX_HORIZ_DISTANCE = sqrt(sqr(R_ATMOS) - sqr(R_PLANET));

vec2 map_trans_lut(float r, float mu) {
    float rho = sqrt(max(sqr(r) - sqr(R_PLANET), 0.0));
    float d = max(-r * mu + sqrt(max(sqr(r) * (sqr(mu) - 1.0) + sqr(R_ATMOS), 0.0)), 0.0);
    float d_min = R_ATMOS - r;
    float d_max = rho + MAX_HORIZ_DISTANCE;

    float u_r = rho / MAX_HORIZ_DISTANCE;
    float u_mu = (d - d_min) / (d_max - d_min);

    return vec2(u_r, u_mu);
}

void unmap_trans_lut(vec2 uv, out float r, out float mu) {
    float rho = uv.x * MAX_HORIZ_DISTANCE;
    r = sqrt(sqr(rho) + sqr(R_PLANET));

    float d_min = R_ATMOS - r;
    float d_max = rho + MAX_HORIZ_DISTANCE;
    float d = d_min + uv.y * (d_max - d_min);
    mu = (d == 0.0) ? 1.0 : (sqr(MAX_HORIZ_DISTANCE) - sqr(rho) - sqr(d)) / (2.0 * r * d);
    mu = clamp(mu, -1.0, 1.0);
}

vec2 map_ms_lut(float theta, float h) {
    float u = 0.5 + 0.5 * theta;
    float v = max(0.0, min((h - R_PLANET) / (R_ATMOS - R_PLANET), 1.0));

    return vec2(u, v);
}

void unmap_ms_lut(vec2 uv, out float theta, out float h) {
    theta = 2.0 * uv.x - 1.0;
    h = uv.y * (R_ATMOS - R_PLANET) + R_PLANET;
}

vec2 map_view_lut(vec3 l_ref, vec3 up, vec3 d) {
    vec3 forward = normalize(l_ref - up * dot(l_ref, up));
    vec3 right = cross(up, forward);

    vec3 d_h = d - up * dot(d, up);

    float phi = atan(dot(d_h, right), dot(d_h, forward));
    float u = phi / (2.0 * PI) + 0.5;

    float l = asin(clamp(dot(d, up), -1.0, 1.0));
    float v = 0.5 + 0.5 * sign(l) * sqrt(abs(l) / (PI / 2.0));

    return vec2(u, v);
}

void unmap_view_lut(vec2 uv, vec3 l_ref, vec3 up, out vec3 d) {
    vec3 forward = normalize(l_ref - up * dot(l_ref, up));
    vec3 right = cross(up, forward);

    float phi = (uv.x - 0.5) * 2.0 * PI;

    float l = 2.0 * uv.y - 1.0;
    l = l * abs(l) * PI * 0.5;

    float cosL = cos(l);
    d = cosL * cos(phi) * forward
        + cosL * sin(phi) * right
        + sin(l) * up;
}

struct March {
    float min;
    float max;
    float step;
    bool hitGround;
};

March setupMarch(vec3 x, vec3 v, int steps) {
    SphereHit atmos = raySphere(x, v, R_ATMOS);
    atmos.entry = max(atmos.entry, 0.0);

    SphereHit ground = raySphere(x, v, R_PLANET);
    bool hitGround = ground.entry > 0.0 && ground.exit > ground.entry;
    if (hitGround) atmos.exit = ground.entry;

    float step = (atmos.exit - atmos.entry) / steps;

    return March(atmos.entry, atmos.exit, step, hitGround);
}

float height(float r) {
    return max(r - R_PLANET, 0.0);
}

float height(vec3 x) {
    return height(length(x));
}

float d_r(float h) {
    return exp(-h / HEIGHT_RAY);
}

float d_m(float h) {
    return exp(-h / HEIGHT_MIE);
}

float d_o(float h) {
    return max(0.0, 1.0 - abs(h - HEIGHT_MID_OZONE) / WIDTH_OZONE);
}

vec3 sigma_t(float h) {
    return (SCATTER_RAY + ABSORP_RAY) * d_r(h)
        + (SCATTER_MIE + ABSORP_MIE) * d_m(h)
        + (SCATTER_OZONE + ABSORP_OZONE) * d_o(h);
}

vec3 T_lut(vec3 x, vec3 v) {
    float r = length(x);
    vec2 uv = map_trans_lut(r, dot(v, x / r));

    return texture(luts_transmittance, uv).rgb;
}

vec3 T_lut_segment(vec3 a, vec3 b, vec3 v) {
    return T_lut(a, v) / T_lut(b, v);
}

vec3 ms_lut(sampler2D sampler, float theta, float h) {
    return texture(sampler, map_ms_lut(theta, h)).rgb;
}

vec3 ms_lut(sampler2D sampler, vec3 x, vec3 v, vec3 l) {
    float r = length(x);
    vec3 up = x / r;

    return ms_lut(sampler, dot(up, l), r).rgb;
}

vec3 ms_lut(vec3 x, vec3 v, vec3 l) {
    return ms_lut(luts_multiscattering, x, v, l).rgb;
}

vec3 T(vec3 x_a, vec3 x_b) {
    const int STEPS = 64;
    vec3 step = (x_b - x_a) / STEPS;

    vec3 sum = vec3(0.0);
    for (int i = 0; i < STEPS; i++) {
        vec3 x = x_a + step * (float(i) + 0.5);
        float h = height(x);

        sum += sigma_t(h);
    }

    float ds = length(step);
    return exp(-sum * ds);
}

vec3 S(vec3 x, vec3 l) {
    bool inShadow = raySphereShadow(x, l, R_PLANET);
    if (inShadow) {
        return vec3(0.0);
    }

    return T_lut(x, l);
}

float p_r(float mu) {
    return 3.0 * (1.0 + sqr(mu)) / (16.0 * PI);
}

float p_m(float mu, float g) {
    return (3.0 / (8.0 * PI)) *
        (1.0 - sqr(g)) * (1.0 + sqr(mu)) /
        ((2.0 + sqr(g)) * pow(1.0 + sqr(g) - 2.0 * g * mu, 3.0 / 2.0));
}

vec3 L_scat(vec3 c, vec3 x, vec3 v, vec3 l_sun, vec3 l_moon) {
    float h = height(x);

    vec3 s_r = SCATTER_RAY * d_r(h);
    vec3 s_m = SCATTER_MIE * d_m(h);
    vec3 s = s_r + s_m;

    vec3 T_view = T_lut_segment(c, x, v);

    vec3 S_sun = S(x, l_sun);
    float mu_sun = dot(v, l_sun);
    float p_r_sun = p_r(mu_sun);
    float p_m_sun = p_m(mu_sun, 0.8);
    vec3 L_sun = (S_sun * (s_r * p_r_sun + s_m * p_m_sun) + s * ms_lut(x, v, l_sun)) * SUN_ILLUMINANCE;

    vec3 S_moon = S(x, l_moon);
    float mu_moon = dot(v, l_moon);
    float p_r_moon = p_r(mu_moon);
    float p_m_moon = p_m(mu_moon, 0.8);
    vec3 L_moon = (S_moon * (s_r * p_r_moon + s_m * p_m_moon) + s * ms_lut(x, v, l_moon)) * MOON_ILLUMINANCE;

    return T_view * (L_sun + L_moon);
}

vec3 L_prime(vec3 x, vec3 v, vec3 l) {
    SphereHit hit = raySphere(x, v, R_ATMOS);
    hit.entry = max(hit.entry, 0.0);

    float tMax = hit.exit;
    SphereHit ground = raySphere(x, v, R_PLANET);
    bool hitGround = ground.entry > 0.0 && ground.exit > ground.entry;
    if (hitGround) tMax = ground.entry;

    vec3 p = x + tMax * v;
    vec3 T_path = T(x, p);

    vec3 L_o = vec3(0.0);
    if (hitGround) {
        vec3 up = normalize(p);
        L_o = GROUND_ALBEDO / PI * S(p, l) * max(0.0, dot(up, l));
    }

    const int STEPS = 16;
    float step = (tMax - hit.entry) / STEPS;

    vec3 sum = vec3(0.0);
    for (int i = 0; i < STEPS; i++) {
        float t = hit.entry + step * (float(i) + 0.5);

        vec3 x_s = x + t * v;

        float h = height(x_s);
        vec3 s_r = SCATTER_RAY * d_r(h);
        vec3 s_m = SCATTER_MIE * d_m(h);

        vec3 T_t = T(x, x_s);

        float p_u = 1 / (4 * PI);
        vec3 s = (s_r + s_m) * p_u;

        vec3 L_l = S(x_s, l) * s;

        sum += T_t * L_l;
    }

    return T_path * L_o + sum * step;
}

vec3 L_f(vec3 x, vec3 v) {
    SphereHit hit = raySphere(x, v, R_ATMOS);
    hit.entry = max(hit.entry, 0.0);

    float tMax = hit.exit;
    SphereHit ground = raySphere(x, v, R_PLANET);
    if (ground.entry > 0.0 && ground.exit > ground.entry) tMax = ground.entry;

    const int STEPS = 16;
    float step = (tMax - hit.entry) / STEPS;

    vec3 sum = vec3(0.0);
    for (int i = 0; i < STEPS; i++) {
        float t = hit.entry + step * (float(i) + 0.5);

        vec3 x_s = x + t * v;

        float h = height(x_s);
        vec3 s_r = SCATTER_RAY * d_r(h);
        vec3 s_m = SCATTER_MIE * d_m(h);

        sum += T(x, x_s) * (s_r + s_m);
    }

    return sum * step;
}


vec3 L(vec3 v) {
    vec3 c = ATMOS_CAM_POS;
    vec3 l_sun = sunDir;
    vec3 l_moon = -sunDir;

    v.y = abs(v.y);

    const int STEPS = 128;
    March m = setupMarch(c, v, STEPS);

    vec3 sum = vec3(0.0);
    for (int i = 0; i < STEPS; i++) {
        float t = m.min + m.step * (float(i) + 0.5);
        sum += L_scat(c, c + t * v, v, l_sun, l_moon);
    }

    return sum * m.step;
}

vec3 L_lut(vec3 c, vec3 v, vec3 l_ref) {
    vec3 up = normalize(c);

    vec2 uv = map_view_lut(l_ref, up, v);
    vec3 color = texture(luts_view, uv).rgb;

    return color;
}

const vec3 sunLimbAlpha = vec3(0.430, 0.502, 0.573);
vec3 drawSun(vec3 dir, vec3 sunDir, float illuminance, float radius) {
    float gamma = acos(clamp(dot(dir, sunDir), -1.0, 1.0));
    float r = gamma / radius;
    if (r > 1.0) return vec3(0.0);

    float mu = sqrt(max(1.0 - sqr(r), 0.0));
    return illuminance * (sunLimbAlpha + 2.0) * 0.5 * pow(vec3(mu), sunLimbAlpha);
}

vec3 L_lutWithCelestials(vec3 v) {
    vec3 c = ATMOS_CAM_POS;
    vec3 l_sun = sunDir;
    vec3 l_moon = -sunDir;

    vec3 up = normalize(c);

    vec2 uv = map_view_lut(l_sun, up, v);
    vec3 color = texture(luts_view, uv).rgb;

    vec3 T_view = T_lut(c, v);

    vec3 L_o = vec3(0.0);
    if (!raySphereShadow(c, v, R_PLANET)) {
        L_o = drawSun(v, l_sun, SUN_ILLUMINANCE, SUN_ANGULAR_RADIUS) +
            drawSun(v, l_moon, MOON_ILLUMINANCE, MOON_ANGULAR_RADIUS);
    }

    return T_view * L_o + color;
}
