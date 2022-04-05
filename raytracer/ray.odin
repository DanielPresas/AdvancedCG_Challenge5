package raytracer;

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
        if ok, attenuation, scattered_ray := material_scatter(record.material, ray, record); ok {
            return attenuation * ray_to_color(scattered_ray, world, depth - 1);
        }
        return Color{ 0, 0, 0 };
    }

    unit_dir := vec3_unit(ray.direction);
    t := 0.5 * (unit_dir.y + 1.0);
    return (1.0 - t) * Color{ 1.0, 1.0, 1.0 } + t * Color { 0.5, 0.7, 1.0 }
}
