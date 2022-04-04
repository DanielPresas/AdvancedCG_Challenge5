package main;

import "core:math"

Hit_Record :: struct {
    hit_point  : Point,
    normal     : Vec3,
    t          : f64,
    front_face : bool,
}

Sphere :: struct {
    center : Point,
    radius : f64,
}

Hittable :: union {
    Sphere,
}

collision :: proc { collision_single, collision_multi }

collision_multi :: proc(hittable_list : []Hittable, ray : Ray, t_min, t_max : f64) -> (hit_any : bool, record : Hit_Record) {
    hit_any, record = false, {};
    closest_t := t_max;

    for hittable in hittable_list {
        if hit, temp_record := collision_single(hittable, ray, t_min, closest_t); hit {
            hit_any = true;
            closest_t = temp_record.t;
            record = temp_record;
        }
    }

    return;
}

collision_single :: proc(hittable : Hittable, ray : Ray, t_min, t_max : f64) -> (hit : bool, record : Hit_Record) {
    hit, record = false, {};
    switch h in hittable {
        case Sphere: {
            hit, record = sphere_collision(h, ray, t_min, t_max);
            return;
        }
        case: {
            return;
        }
    }
}

set_record_face_normal :: #force_inline proc(using record : ^Hit_Record, ray : Ray, outward_normal : Vec3) {
    front_face = vec3_dot(ray.direction, outward_normal) < 0;
    normal = outward_normal if front_face else -outward_normal;
}

sphere_collision :: proc(sphere : Sphere, ray : Ray, t_min, t_max : f64) -> (hit : bool, record : Hit_Record) {
    hit, record = false, {};

    oc := ray.origin - sphere.center;
    a := vec3_length2(ray.direction);
    c := vec3_length2(oc) - sphere.radius * sphere.radius;
    half_b := vec3_dot(oc, ray.direction);

    discriminant := half_b * half_b - a * c;
    if discriminant < 0 { return; }
    sqrtd := math.sqrt(discriminant);

    root := (-half_b - sqrtd) / a;
    if root < t_min || root > t_max {
        root = (-half_b + sqrtd) / a;
        if root < t_min || root > t_max { return; }
    }

    record.t = root;
    record.hit_point = ray_at(ray, root);
    outward_normal := (record.hit_point - sphere.center) / sphere.radius;
    set_record_face_normal(&record, ray, outward_normal);

    hit = true;
    return;
}
