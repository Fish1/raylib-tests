const math = @import("std").math;

pub const Animation = enum {
    EaseInCubic,
    EaseOutElastic,
    EaseInBack,
};

pub fn ease(animation: Animation, a: f32, b: f32, time: f32) f32 {
    return switch (animation) {
        .EaseInCubic => ease_in_cubic(a, b, time),
        .EaseOutElastic => ease_out_elastic(a, b, time),
        .EaseInBack => ease_in_back(a, b, time),
    };
}

pub fn ease_in_cubic(a: f32, b: f32, time: f32) f32 {
    if (time <= 0) {
        return a;
    }
    if (time >= 1) {
        return b;
    }
    const result = time * time * time;
    return ((b - a) * result) + a;
}

pub fn ease_out_elastic(a: f32, b: f32, time: f32) f32 {
    const c4: f32 = (2.0 * math.pi) / 3.0;
    if (time <= 0) {
        return a;
    }
    if (time >= 1) {
        return b;
    }
    const result = math.pow(f32, 2.0, -10.0 * time) * math.sin((time * 10 - 0.75) * c4) + 1;
    return ((b - a) * result) + a;
}

pub fn ease_in_back(a: f32, b: f32, time: f32) f32 {
    const c1 = 1.70158;
    const c3 = c1 + 1;

    if (time <= 0) {
        return a;
    }
    if (time >= 1) {
        return b;
    }

    const result = c3 * time * time * time - c1 * time * time;
    return ((b - a) * result) + a;
}
