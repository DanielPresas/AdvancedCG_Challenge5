package main;

Ray :: struct {
    origin    : Point,
    direction : Vec3,
}

ray_at :: proc(ray : Ray, t : f64) -> Point { return ray.origin + ray.direction * t; }

ray_to_color :: proc { ray_to_color_single, ray_to_color_multi }
ray_to_color_multi :: proc(ray : Ray, world : ..Hittable) -> Color {
    if hit_any, record := collision(world, ray, 0.0, Infinity); hit_any {
        return 0.5 * (record.normal + Color{ 1, 1, 1 });
    }

    unit_dir := vec3_unit(ray.direction);
    t := 0.5 * (unit_dir.y + 1.0);
    return (1.0 - t) * Color{ 1.0, 1.0, 1.0 } + t * Color { 0.5, 0.7, 1.0 }
}
ray_to_color_single :: proc(ray : Ray, h : Hittable) -> Color {
    if hit, record := collision(h, ray, 0.0, Infinity); hit {
        return 0.5 * (record.normal + Color{ 1, 1, 1 });
    }

    unit_dir := vec3_unit(ray.direction);
    t := 0.5 * (unit_dir.y + 1.0);
    return (1.0 - t) * Color{ 1.0, 1.0, 1.0 } + t * Color { 0.5, 0.7, 1.0 }
}
