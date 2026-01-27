pub const Action = enum {
    score,
    swap,

    power_laser,
    power_large_laser,
    power_giant_laser,
};

pub const Direction = enum {
    up,
    down,
    left,
    right,
};

pub const GemColor = enum {
    red,
    green,
    blue,
};

pub const GemShape = enum {
    star,
    diamond,
    pentagon,
};

pub const GemPower = enum {
    laser,
    large_laser,
    giant_laser,
};

pub const Difficulty = enum {
    easy,
    medium,
    hard,
};
