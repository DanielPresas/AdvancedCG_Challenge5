package main;

import "core:fmt";
import "core:math";

Pi :: f64(math.PI);

Infinity         :: f64(0h7ff0_0000_0000_0000);
NegativeInfinity :: f64(0hfff0_0000_0000_0000);

Vec3  :: distinct [3]f64;
Point :: Vec3
Color :: Vec3

deg_to_rad :: #force_inline proc(deg : f64) -> f64 { return deg * math.RAD_PER_DEG; }

vec3_unit    :: proc(v : Vec3)    -> Vec3 { return v / vec3_length(v); }
vec3_length  :: proc(v : Vec3)    -> f64  { return math.sqrt(vec3_length2(v)); }
vec3_length2 :: proc(v : Vec3)    -> f64  { return v.x * v.x + v.y * v.y + v.z * v.z; }
vec3_dot     :: proc(u, v : Vec3) -> f64  { return u.x * v.x + u.y * v.y + u.z * v.z; }
vec3_cross   :: proc(u, v : Vec3) -> Vec3 { return Vec3{ u.y * v.z - u.z * v.y, u.z * v.x - u.x * v.z, u.x * v.y - u.y * v.x }; }

write_color :: proc(c : Color, samples_per_pixel : int) {
    scale := 1.0 / f64(samples_per_pixel);
    r, g, b := c.r * scale, c.g * scale, c.b * scale;
    ir, ig, ib := cast(int)(256 * clamp(r, 0.0, 0.999)), cast(int)(256 * clamp(g, 0.0, 0.999)), cast(int)(256 * clamp(b, 0.0, 0.999));
    fmt.printf("{} {} {}\n", ir, ig, ib);
}
