package raytracer;

import "core:fmt";
import "core:math";
import "core:math/rand";
import "core:strings";
import "core:thread";
import "core:time";

main :: proc() {
    // @Note: World
    world := make([dynamic]^Hittable, 0, 500);
    // three_sphere_world(&world);
    random_world(&world);
    defer {
        for h in world {
            free(h.material);
            free(h);
        }
        delete(world);
    }

    // @Note: Camera
    // position       :: Point{  0.2, 1.0,  3.0 };
    // look_at        :: Point{  0.0, 0.0, -3.0 };
    // focus_distance := vec3_length(position - look_at);
    position       :: Point{ 13.0, 2.0,  3.0 };
    look_at        :: Point{  0.0, 0.0,  0.0 };
    focus_distance :: 10;

    view_up        :: Vec3 {  0.0, 1.0,  0.0 };
    vertical_fov   :: 30;
    aspect_ratio   :: 16.0 / 10.0;
    aperture       :: 0.1;

    camera := make_camera(
        position, look_at, view_up,
        vertical_fov, aspect_ratio, aperture, focus_distance,
    );

    // @Note: Image
    samples_per_pixel :: 300;
    max_depth         :: 50;
    image_width       := 400;
    image_height      := int(f64(image_width) / aspect_ratio);

    output := make([]Color, image_width * image_height);
    defer delete(output)

    // render_scene(
    render_scene_multithreaded(
        output = &output, world = world[:], camera = camera,
        image_width = image_width, image_height = image_height,
        samples_per_pixel = samples_per_pixel, max_depth = max_depth,
        num_threads = 8,
    );
    output_to_ppm(output, image_width, image_height);
}

three_sphere_world :: proc(world : ^[dynamic]^Hittable) {
    mat_ground := new_lambertian_material(Color{ 0.2, 0.8, 0.3 });
    append(world, new_sphere(Point{ 0, -100 , 0 }, 100, mat_ground));

    mat_left   := new_dielectric_material(1.3);
    mat_center := new_lambertian_material(Color{ 0.7, 0.2, 0.8 });
    mat_right  := new_metal_material(Color{ 0.4, 0.6, 0.2 });

    append(world, new_sphere(Point{ -0.8, 0.3 , -1.0 }, 0.3, mat_left));
    append(world, new_sphere(Point{  0.0, 0.5 , -1.2 }, 0.5, mat_center));
    append(world, new_sphere(Point{  0.8, 0.2 , -1.0 }, 0.2, mat_right));
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

render_scene :: proc(
    output : ^[]Color, world : []^Hittable, camera : Camera,
    image_width, image_height, samples_per_pixel, max_depth : int,
) {
    for y := image_height - 1; y >= 0; y -= 1 {
        current_line := image_height - y;
        fmt.eprintf("\rTracing rays:         {: 4d} / {: 4d} ({:.2f}%% done)...", current_line, image_height, 100.0 * f64(current_line) / f64(image_height));
        for x in 0 ..< image_width {
            color := Color{ 0, 0, 0 };
            for _ in 0 ..< samples_per_pixel {
                u := (f64(x) + rand.float64()) / f64(image_width  - 1);
                v := (f64(y) + rand.float64()) / f64(image_height - 1);
                ray := camera_get_ray(camera, u, v);
                color += ray_to_color(ray, world, max_depth);
            }

            scale := 1.0 / f64(samples_per_pixel);
            sr, sg, sb := math.sqrt(color.r * scale), math.sqrt(color.g * scale), math.sqrt(color.b * scale);
            output[y * image_width + x] = Color{ sr, sg, sb };
        }
    }
    fmt.eprint("Done.\n")
}

Task_Data :: struct {
    output : []Color,
    world : []^Hittable,
    camera : Camera,
    width, height : int,
    samples_per_pixel, max_depth : int,
    start, end : int,
}

render_scene_multithreaded :: proc(
    output : ^[]Color, world : []^Hittable, camera : Camera,
    image_width, image_height, samples_per_pixel, max_depth : int,
    num_threads : int,
) {
    stride := image_height / num_threads;
    end := image_height;
    start := end - stride;

    pool : thread.Pool;
    thread.pool_init(&pool, num_threads + 1, context.allocator);
    defer thread.pool_destroy(&pool);

    out := make([][]Color, num_threads + 1);
    defer delete(out);

    for it in 0 ..< num_threads + 1 {
        data := new(Task_Data);
        out[it] = make([]Color, image_width * (end - start));
        data^ = Task_Data{ out[it], world, camera, image_width, image_height, samples_per_pixel, max_depth, start, end };
        end = max(end - stride, start - 1);
        start = max(start - stride, 0);

        thread.pool_add_task(&pool, render_scene_thread, data, it);
        if end <= 0 { break; }
    }

    thread.pool_start(&pool);
    thread.pool_finish(&pool);

    for t in pool.tasks_done {
        d := (^Task_Data)(t.data)^;
        // mem.copy(mem.raw_slice_data(output[data.start:data.end - 1]), mem.raw_slice_data(data.output), data.end - data.start - 1);
        for c, i in d.output {
            output^[d.start * image_width + i] = c
        }
    }
}

render_scene_thread :: proc(t : thread.Task) {
    using d := (^Task_Data)(t.data)^;
    time.sleep(time.Duration(t.user_index) * 10 * time.Millisecond);
    fmt.eprintf("[Thread {}] Tracing rays...\n", t.user_index);

    h := end - start;
    for y := end - 1; y >= start; y -= 1 {
        current_line := end - y;
        fmt.eprintf("[Thread {}] {: 4d} / {: 4d} ({:2.2f}%%)\n", t.user_index, start + current_line, end, 100.0 * f64(current_line - 1) / f64(h));
        for x in 0 ..< width {
            color := Color{ 0, 0, 0 };
            for _ in 0 ..< samples_per_pixel {
                u := (f64(x) + rand.float64()) / f64(width  - 1);
                v := (f64(y) + rand.float64()) / f64(height - 1);
                ray := camera_get_ray(camera, u, v);
                color += ray_to_color(ray, world, max_depth);
            }

            scale := 1.0 / f64(samples_per_pixel);
            sr, sg, sb := math.sqrt(color.r * scale), math.sqrt(color.g * scale), math.sqrt(color.b * scale);
            output[(h - current_line) * width + x] = Color{ sr, sg, sb };
        }
    }
    fmt.eprintf("[Thread {}] --- Done. ---\n", t.user_index);
    (^Task_Data)(t.data)^ = d;
}

output_to_ppm :: proc(output : []Color, image_width, image_height : int) {
    sb : strings.Builder;
    strings.init_builder(&sb);
    defer strings.destroy_builder(&sb);

    fmt.printf("P3\n{} {}\n255\n", image_width, image_height);
    for y := image_height - 1; y >= 0; y -= 1 {
        current_line := image_height - y;
        fmt.eprintf("\rOutputting scanlines: {: 4d} / {: 4d} ({:.2f}%% done)...", current_line, image_height, 100.0 * f64(current_line) / f64(image_height));
        for x in 0 ..< image_width {
            c := output[y * image_width + x];
            ir, ig, ib := int(256 * clamp(c.r, 0.0, 0.999)), int(256 * clamp(c.g, 0.0, 0.999)), int(256 * clamp(c.b, 0.0, 0.999));
            strings.write_string(&sb, fmt.tprintf("{} {} {}\n", ir, ig, ib));
        }
    }

    fmt.print(strings.to_string(sb));
    fmt.eprint("Done.");
}
