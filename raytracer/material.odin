package raytracer;

import "core:math";
import "core:math/rand";

Material :: struct {
    type : union {
        ^Lambertian_Material,
        ^Metal_Material,
        ^Dielectric_Material,
    },
}

Lambertian_Material :: struct {
    using _base : Material,
    albedo      : Color,
}

Metal_Material :: struct {
    using _base : Material,
    albedo      : Color,
    roughness   : f64,
}

Dielectric_Material :: struct {
    using _base      : Material,
    refractive_index : f64,
}

new_lambertian_material :: proc(albedo : Color) -> (mat : ^Lambertian_Material) {
    mat = new(Lambertian_Material);
    mat.type = mat;
    mat.albedo = albedo;
    return;
}

new_metal_material :: proc(albedo : Color, roughness : f64 = 0.0) -> (mat : ^Metal_Material) {
    mat = new(Metal_Material);
    mat.type = mat;
    mat.albedo = albedo;
    mat.roughness = clamp(roughness, 0.0, 1.0);
    return;
}

new_dielectric_material :: proc(refractive_index : f64) -> (mat : ^Dielectric_Material) {
    mat = new(Dielectric_Material);
    mat.type = mat;
    mat.refractive_index = refractive_index;
    return;
}

material_scatter :: proc(mat : ^Material, ray_in : Ray, hit_record : Hit_Record) -> (ok : bool, attenuation : Color, scattered : Ray) {
    ok, attenuation, scattered = false, {}, {};
    switch m in mat.type {
        case ^Lambertian_Material: {
            ok, attenuation, scattered = lambertian_material_scatter(m, ray_in, hit_record);
            return;
        }
        case ^Metal_Material: {
            ok, attenuation, scattered = metal_material_scatter(m, ray_in, hit_record);
            return;
        }
        case ^Dielectric_Material: {
            ok, attenuation, scattered = dielectric_material_scatter(m, ray_in, hit_record);
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

@(private)
dielectric_material_scatter :: proc(mat : ^Dielectric_Material, ray_in : Ray, record : Hit_Record) -> (ok : bool, attenuation : Color, scattered : Ray) {
    attenuation = Color{ 1, 1, 1 };
    refraction_ratio := 1.0 / mat.refractive_index if record.front_face else mat.refractive_index;

    unit_dir := vec3_unit(ray_in.direction);
    cos_theta := min(vec3_dot(-unit_dir, record.normal), 1.0);
    sin_theta := math.sqrt(1.0 - cos_theta * cos_theta);

    direction : Vec3;
    reflectance :: proc(cos_theta, ratio : f64) -> f64 {
        denom := 1e-8 if (1.0 + ratio) < 1e-8 else (1.0 + ratio);
        r0 := (1.0 - ratio) / denom;
        return (r0 * r0) + (1.0 - r0 * r0) * math.pow((1 - cos_theta), 5);
    }

    if refraction_ratio * sin_theta < 1.0 && reflectance(cos_theta, refraction_ratio) < rand.float64() {
        direction = vec3_refract(unit_dir, record.normal, refraction_ratio);
    }
    else {
        direction = vec3_reflect(unit_dir, record.normal);
    }

    scattered = Ray{ origin = record.hit_point, direction = direction };
    ok = true;
    return;
}
