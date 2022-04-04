package main;

import "core:fmt";
import "core:math/rand";

main :: proc() {
    // @Note: Image
    aspect_ratio      :: 16.0 / 9.0;
    image_width       :: 400;
    image_height      :: cast(int)(image_width / aspect_ratio);
    samples_per_pixel :: 100;

    // @Note: World
    world := make([dynamic]Hittable, 2, 100);
    defer delete(world);
    append(&world, Sphere{ center = Point{ 0,      0, -1 }, radius =   0.5 });
    append(&world, Sphere{ center = Point{ 0, -100.5, -1 }, radius = 100   });

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
                color += ray_to_color(ray, ..world[:]);
            }

            write_color(color, samples_per_pixel);
        }
    }
    fmt.eprintf("\nDone.\n");
}
