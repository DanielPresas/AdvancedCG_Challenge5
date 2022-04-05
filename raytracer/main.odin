package raytracer;

import "core:fmt";
import "core:math/rand";

main :: proc() {
    // @Note: Image
    aspect_ratio      :: 16.0 / 9.0;
    image_width       :: 400;
    image_height      :: cast(int)(image_width / aspect_ratio);
    samples_per_pixel :: 100;
    max_depth         :: 50;

    // @Note: World
    mat_ground := new_lambertian_material(Color{ 0.7, 0.8, 0.2 });
    mat_center := new_lambertian_material(Color{ 0.3, 0.2, 0.8 });
    mat_left   := new_dielectric_material(1.7);
    mat_right  := new_metal_material(Color{ 0.8, 0.6, 0.2 }, 0.8);
    defer {
        free(mat_ground);
        free(mat_center);
        free(mat_left);
        free(mat_right);
    }

    world := make([dynamic]Hittable, 4, 100); defer delete(world);

    append(&world, Sphere{ center = Point{  0.0, -100.5, -1.0 }, radius = 100.0, material = mat_ground });
    append(&world, Sphere{ center = Point{  0.0,    0.0, -1.0 }, radius =   0.5, material = mat_center });
    append(&world, Sphere{ center = Point{ -1.1,    0.0, -1.0 }, radius =   0.5, material = mat_left   });
    append(&world, Sphere{ center = Point{ -1.1,    0.0, -1.0 }, radius =  -0.4, material = mat_left   });
    append(&world, Sphere{ center = Point{  0.9,    0.0, -1.0 }, radius =   0.3, material = mat_right  });

    // @Note: Camera
    camera := make_camera(aspect_ratio);

    fmt.printf("P3\n{} {}\n255\n", image_width, image_height);
    for y := image_height - 1; y >= 0; y -= 1 {
        fmt.eprintf("\rScanlines remaining: {: 4d}", y);
        for x in 0 ..< image_width {
            color := Color{ 0, 0, 0 };

            for _ in 0 ..< samples_per_pixel {
                u := (f64(x) + rand.float64()) / f64(image_width  - 1);
                v := (f64(y) + rand.float64()) / f64(image_height - 1);

                ray := camera_get_ray(camera, u, v);
                color += ray_to_color(ray, world[:], max_depth);
            }

            write_color(color, samples_per_pixel);
        }
    }
    fmt.eprintf("\nDone.\n");
}
