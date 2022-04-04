package main;

import "core:fmt";

import "utils";

main :: proc() {
    using utils;

    // @Note: Image
    aspect_ratio :: 16.0 / 9.0;
    image_width  :: 400;
    image_height :: cast(int)(image_width / aspect_ratio);

    // @Note: World
    world := make([dynamic]Hittable, 2, 100);
    defer delete(world);
    append(&world, Sphere{ center = Point{ 0,      0, -1 }, radius =   0.5 });
    append(&world, Sphere{ center = Point{ 0, -100.5, -1 }, radius = 100   });

    // @Note: Camera
    viewport_height : f64 = 2.0;
    viewport_width  : f64 = viewport_height * aspect_ratio;
    focal_length    : f64 = 1.0;

    origin     := Point{ 0, 0, 0 };
    horizontal := Vec3{ viewport_width,  0, 0 };
    vertical   := Vec3{ 0, viewport_height, 0 };
    lower_left := origin - (horizontal / 2.0) - (vertical / 2.0) - Vec3{ 0, 0, focal_length };

    fmt.printf("P3\n{} {}\n255\n", image_width, image_height);

    for y := image_height - 1; y >= 0; y -= 1 {
        fmt.eprintf("\rScanlines remaining: {: 4d}", y);

        for x in 0 ..< image_width {
            u := f64(x) / f64(image_width  - 1);
            v := f64(y) / f64(image_height - 1);

            ray := Ray{ origin = origin, direction = (lower_left + u * horizontal + v * vertical - origin) };
            color := ray_to_color(ray, ..world[:]);
            write_color(color);
        }
    }

    fmt.eprintf("\nDone.\n");
}
