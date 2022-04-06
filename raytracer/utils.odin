package raytracer;

import "core:math";
import "core:math/rand";

Pi :: f64(math.PI);

Infinity         :: f64(0h7ff0_0000_0000_0000);
NegativeInfinity :: f64(0hfff0_0000_0000_0000);

Vec3  :: distinct [3]f64;
Point :: Vec3
Color :: Vec3

deg_to_rad :: #force_inline proc(deg : f64) -> f64 { return deg * (Pi / 180.0); }

vec3_unit        :: proc(v : Vec3) -> Vec3 { return v / vec3_length(v); }
vec3_length      :: proc(v : Vec3) -> f64  { return math.sqrt(vec3_length2(v)); }
vec3_length2     :: proc(v : Vec3) -> f64  { return v.x * v.x + v.y * v.y + v.z * v.z; }
vec_is_near_zero :: proc(v : Vec3) -> bool { return v.x < 1e-8 && v.y < 1e-8 && v.z < 1e-8; }

vec3_dot     :: proc(u, v : Vec3) -> f64  { return u.x * v.x + u.y * v.y + u.z * v.z; }
vec3_cross   :: proc(u, v : Vec3) -> Vec3 { return Vec3{ u.y * v.z - u.z * v.y, u.z * v.x - u.x * v.z, u.x * v.y - u.y * v.x }; }
vec3_reflect :: proc(v, n : Vec3) -> Vec3 { return v - 2 * vec3_dot(v, n) * n; }

vec3_refract :: proc { vec3_refract_ratio, vec3_refract_indices }
vec3_refract_indices :: proc(v, n : Vec3, refractive_index_1, refractive_index_2 : f64) -> Vec3 {
    return vec3_refract_ratio(v, n, refractive_index_1 / refractive_index_2);
}
vec3_refract_ratio :: proc(v, n : Vec3, refractive_ratio : f64) -> Vec3 {
    cos_theta := min(vec3_dot(-v, n), 1.0);
    r_out_perpendicular := refractive_ratio * (v + cos_theta * n);
    r_out_parallel := -math.sqrt(abs(1.0 - vec3_length2(r_out_perpendicular))) * n;
    return r_out_perpendicular + r_out_parallel;
}

random_vec3 :: proc(min : f64 = 0.0, max : f64 = 1.0) -> Vec3 {
    return Vec3{ rand.float64_range(min, max), rand.float64_range(min, max), rand.float64_range(min, max) };
}
random_unit_vec3 :: proc() -> Vec3 {
    return vec3_unit(random_vec3_in_unit_sphere());
}
random_vec3_in_unit_sphere :: proc() -> Vec3 {
    for {
        v := random_vec3(-1.0, 1.0);
        if vec3_length2(v) >= 1 { continue; }
        return v;
    }
}
random_vec3_in_hemisphere :: proc(normal : Vec3) -> Vec3 {
    u := random_vec3_in_unit_sphere();
    return u if vec3_dot(u, normal) > 0.0 else -u;
}
random_vec3_in_unit_disk :: proc() -> Vec3 {
    for {
        v := random_vec3(-1.0, 1.0);
        v.z = 0.0;
        if vec3_length2(v) >= 1 { continue; }
        return v;
    }
}
