package raytracer;

import "core:math";

Camera :: struct {
    position, lower_left : Point,
    horizontal, vertical : Vec3,
    right, up, forward   : Vec3,
    lens_radius          : f64,
}

make_camera :: proc(
    look_from, look_at, view_up : Vec3,
    vertical_fov, aspect_ratio, aperture, focus_distance : f64,
) -> (
    cam : Camera,
) {
    theta := deg_to_rad(vertical_fov);
    half_height := math.tan(theta / 2.0);
    half_width  := half_height * aspect_ratio;

    cam.forward = vec3_unit(look_from - look_at);
    cam.right   = vec3_unit(vec3_cross(view_up, cam.forward));
    cam.up      = vec3_cross(cam.forward, cam.right);

    cam.position    = look_from;
    cam.horizontal  = cam.right * 2.0 * half_width * focus_distance;
    cam.vertical    = cam.up * 2.0 * half_height * focus_distance;
    cam.lower_left  = cam.position - (cam.horizontal / 2.0) - (cam.vertical / 2.0) - (cam.forward * focus_distance);
    cam.lens_radius = aperture / 2.0;

    return;
}

camera_get_ray :: proc(using cam : Camera, u, v : f64) -> Ray {
    r := lens_radius * random_vec3_in_unit_disk();
    offset := right * r.x + up * r.y;

    return Ray{
        origin = position + offset,
        direction = lower_left + u * horizontal + v * vertical - position - offset,
    };
}
