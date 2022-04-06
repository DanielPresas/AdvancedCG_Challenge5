package raytracer;

import "core:fmt";
import "core:math";
import "core:math/rand";

main :: proc() {
    // @Note: World
    world := make([dynamic]^Hittable, 0, 500);
    random_world(&world);
    defer {
        for h in world {
            free(h.material);
            free(h);
        }
        delete(world);
    }

    // @Note: Camera
    position       :: Point{ 13, 2, 3 };
    look_at        :: Point{  0, 0, 0 };
    view_up        :: Vec3 {  0, 1, 0 };
    vertical_fov   :: 30;
    aspect_ratio   :: 16.0 / 10.0;
    aperture       :: 0.1;
    focus_distance :: 10;

    camera := make_camera(
        position, look_at, view_up,
        vertical_fov, aspect_ratio, aperture, focus_distance,
    );

    // @Note: Image
    image_width       :: 400;
    image_height      :: cast(int)(image_width / aspect_ratio);
    samples_per_pixel :: 100;
    max_depth         :: 50;

    // output := make([]Color, image_width * image_height);

    fmt.printf("P3\n{} {}\n255\n", image_width, image_height);
    for y := image_height - 1; y >= 0; y -= 1 {
        fmt.eprintf("\rScanlines remaining: {: 4d} ({}%% done)", y, int(100.0 * f64(image_height - 1 - y) / f64(image_height - 1)));
        for x in 0 ..< image_width {
            color := Color{ 0, 0, 0 };
            for _ in 0 ..< samples_per_pixel {
                u := (f64(x) + rand.float64()) / f64(image_width  - 1);
                v := (f64(y) + rand.float64()) / f64(image_height - 1);
                ray := camera_get_ray(camera, u, v);
                color += ray_to_color(ray, world[:], max_depth);
            }

            scale := 1.0 / f64(samples_per_pixel);
            sr, sg, sb := math.sqrt(color.r * scale), math.sqrt(color.g * scale), math.sqrt(color.b * scale);
            ir, ig, ib := int(256 * clamp(sr, 0.0, 0.999)), int(256 * clamp(sg, 0.0, 0.999)), int(256 * clamp(sb, 0.0, 0.999));
            // output[y * image_width + x] = Color{ f64(ir), f64(ig), f64(ib) };
            fmt.printf("{} {} {}\n", ir, ig, ib);
        }
    }
    fmt.eprintf("\nDone.\n");
}

random_world :: proc(world : ^[dynamic]^Hittable) {
    ground_material := new_lambertian_material(Color{ 0.5, 0.5, 0.5 });
    append(world, new_sphere(Point{ 0, -1000 , 0 }, 1000, ground_material));

    for a in -11 ..< 11 {
        for b in -11 ..< 11 {
            choose_mat := rand.float64();
            center := Point{ f64(a) + 0.9 * rand.float64(), 0.2, f64(b) + 0.9 * rand.float64() };

            if vec3_length(center - Point{ 4.0, 0.2, 0.0 }) > 0.9 {
                sphere_material : ^Material;
                switch {
                    case choose_mat < 0.8: {
                        // diffuse
                        albedo := random_vec3() * random_vec3();
                        sphere_material = new_lambertian_material(albedo);
                    }
                    case choose_mat < 0.95: {
                        // metal
                        albedo := random_vec3(0.5, 1.0);
                        fuzz   := rand.float64_range(0.0, 0.5);
                        sphere_material = new_metal_material(albedo, fuzz);
                    }
                    case: {
                        // glass
                        refrac := rand.float64_range(1.3, 1.7);
                        sphere_material = new_dielectric_material(refrac);
                    }
                }
                append(world, new_sphere(center, 0.2, sphere_material));
            }
        }
    }

    mat1 := new_dielectric_material(1.5);
    mat2 := new_lambertian_material(Color{ 0.4, 0.2, 0.1 });
    mat3 := new_metal_material(Color{ 0.7, 0.6, 0.5 }, 0.0);

    append(world, new_sphere(Point{  0, 1, 0 }, 1.0, mat1));
    append(world, new_sphere(Point{ -4, 1, 0 }, 1.0, mat2));
    append(world, new_sphere(Point{  4, 1, 0 }, 1.0, mat3));
}
