package raytracer;

Material :: union {
    ^Lambertian_Material,
    ^Metal_Material,
}

Lambertian_Material :: struct {
    albedo : Color,
}

Metal_Material :: struct {
    albedo    : Color,
    roughness : f64,
}

new_lambertian_material :: proc(albedo : Color) -> (mat : ^Lambertian_Material) {
    mat = new(Lambertian_Material);
    mat.albedo = albedo;
    return;
}

new_metal_material :: proc(albedo : Color, roughness : f64 = 0.0) -> (mat : ^Metal_Material) {
    mat = new(Metal_Material);
    mat.albedo = albedo;
    mat.roughness = clamp(roughness, 0.0, 1.0);
    return;
}

material_scatter :: proc(mat : Material, ray_in : Ray, hit_record : Hit_Record) -> (ok : bool, attenuation : Color, scattered : Ray) {
    ok, attenuation, scattered = false, {}, {};
    switch m in mat {
        case ^Lambertian_Material: {
            ok, attenuation, scattered = lambertian_material_scatter(m, ray_in, hit_record);
            return;
        }
        case ^Metal_Material: {
            ok, attenuation, scattered = metal_material_scatter(m, ray_in, hit_record);
            return;
        }
        case: {
            return;
        }
    }
}

@(private)
lambertian_material_scatter :: proc(mat : ^Lambertian_Material, ray_in : Ray, record : Hit_Record) -> (ok : bool, attenuation : Color, scattered : Ray) {
    scatter_direction := record.normal + random_unit_vec3();
    if vec_is_near_zero(scatter_direction) { scatter_direction = record.normal }
    scattered = Ray{ origin = record.hit_point, direction = scatter_direction };
    attenuation = mat.albedo;
    ok = true;
    return;
}

@(private)
metal_material_scatter :: proc(mat : ^Metal_Material, ray_in : Ray, record : Hit_Record) -> (ok : bool, attenuation : Color, scattered : Ray) {
    reflected_direction := vec3_reflect(vec3_unit(ray_in.direction), record.normal);
    scattered = Ray{ origin = record.hit_point, direction = reflected_direction + mat.roughness * random_vec3_in_unit_sphere() };
    attenuation = mat.albedo;
    ok = vec3_dot(scattered.direction, record.normal) > 0;
    return;
}
