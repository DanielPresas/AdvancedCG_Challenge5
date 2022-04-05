package main;

Ray :: struct {
    origin    : Point,
    direction : Vec3,
}

ray_at :: proc(ray : Ray, t : f64) -> Point { return ray.origin + ray.direction * t; }

ray_to_color :: proc { ray_to_color_single, ray_to_color_multi }
ray_to_color_single :: proc(ray : Ray, h : Hittable, depth : int) -> Color {
    return ray_to_color_multi(ray, []Hittable{ h }, depth);
}
ray_to_color_multi :: proc(ray : Ray, world : []Hittable, depth : int) -> Color {
    if depth <= 0 { return Color{ 0, 0, 0 }; }

    if hit_any, record := collision(world, ray, 0.001, Infinity); hit_any {
        target := record.hit_point + random_vec3_in_hemisphere(record.normal);
        return 0.5 * ray_to_color(
            Ray{ origin = record.hit_point, direction = target - record.hit_point },
            world, depth - 1,
        );
    }

    unit_dir := vec3_unit(ray.direction);
    t := 0.5 * (unit_dir.y + 1.0);
    return (1.0 - t) * Color{ 1.0, 1.0, 1.0 } + t * Color { 0.5, 0.7, 1.0 }
}
