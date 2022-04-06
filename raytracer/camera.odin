package raytracer;

import "core:math";

Camera :: struct {
    position, lower_left : Point,
    horizontal, vertical : Vec3,
    right, up, forward   : Vec3,
    // lens_radius          : f64,
}

make_camera :: proc(
    look_from, look_at, view_up : Vec3,
    vertical_fov, aspect_ratio : f64,
) -> (
    cam : Camera,
) {
    theta := deg_to_rad(vertical_fov);
    h := math.tan(theta / 2.0);
    viewport_height := 2.0 * h;
    viewport_width  := viewport_height * aspect_ratio;

    cam.forward = vec3_unit(look_from - look_at);
    cam.right   = vec3_unit(vec3_cross(view_up, cam.forward));
    cam.up      = vec3_cross(cam.forward, cam.right);

    cam.position    = look_from;
    cam.horizontal  = cam.right * viewport_width;
    cam.vertical    = cam.up * viewport_height;
    cam.lower_left  = cam.position - (cam.horizontal / 2.0) - (cam.vertical / 2.0) - (cam.forward);

    return;
}

camera_get_ray :: proc(using cam : Camera, u, v : f64) -> Ray {
    return Ray{
        origin = position,
        direction = lower_left + u * horizontal + v * vertical - position,
    };
}
