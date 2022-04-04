package main;

Camera :: struct {
    origin     : Point,
    lower_left : Point,
    horizontal : Vec3,
    vertical   : Vec3,
}

make_camera :: proc(aspect_ratio : f64) -> (cam : Camera) {
    viewport_height : f64 = 2.0;
    viewport_width  : f64 = viewport_height * aspect_ratio;
    focal_length    : f64 = 1.0;

    cam.origin     = Point{ 0, 0, 0 };
    cam.horizontal = Vec3{ viewport_width,  0, 0 };
    cam.vertical   = Vec3{ 0, viewport_height, 0 };
    cam.lower_left = cam.origin - (cam.horizontal / 2.0) - (cam.vertical / 2.0) - Vec3{ 0, 0, focal_length };

    return;
}

camera_get_ray :: proc(using cam : Camera, u, v : f64) -> Ray {
    return Ray{
        origin = origin,
        direction = lower_left + u * horizontal + v * vertical - origin,
    };
}
