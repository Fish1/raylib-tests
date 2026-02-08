const std = @import("std");
const rl = @import("raylib");

pub const TextureID = enum(usize) {
    red_star_gem,
    red_diamond_gem,
    red_pentagon_gem,
    green_star_gem,
    green_diamond_gem,
    green_pentagon_gem,
    blue_star_gem,
    blue_diamond_gem,
    blue_pentagon_gem,
    grey_star_gem,
    grey_diamond_gem,
    grey_pentagon_gem,
    laser,
    goal,

    player,

    laser_red,
    laser_green,
    laser_blue,

    planet,
    noise08,
    noise09,
    noise10,
    noise11,

    ui_button_square_gradient,
    ui_check_round_color,
    ui_check_round_round_circle,
};

pub const TextureLoader = struct {
    textures: [26]rl.Texture,

    pub fn init() !@This() {
        return .{
            .textures = .{
                try rl.loadTexture("./assets/images/red_gems/star.png"),
                try rl.loadTexture("./assets/images/red_gems/diamond.png"),
                try rl.loadTexture("./assets/images/red_gems/pentagon.png"),
                try rl.loadTexture("./assets/images/green_gems/star.png"),
                try rl.loadTexture("./assets/images/green_gems/diamond.png"),
                try rl.loadTexture("./assets/images/green_gems/pentagon.png"),
                try rl.loadTexture("./assets/images/blue_gems/star.png"),
                try rl.loadTexture("./assets/images/blue_gems/diamond.png"),
                try rl.loadTexture("./assets/images/blue_gems/pentagon.png"),
                try rl.loadTexture("./assets/images/grey_gems/star.png"),
                try rl.loadTexture("./assets/images/grey_gems/diamond.png"),
                try rl.loadTexture("./assets/images/grey_gems/pentagon.png"),
                try rl.loadTexture("./assets/images/laser.png"),
                try rl.loadTexture("./assets/images/goal.png"),

                try rl.loadTexture("./assets/images/player.png"),

                try rl.loadTexture("./assets/images/laser_red.png"),
                try rl.loadTexture("./assets/images/laser_green.png"),
                try rl.loadTexture("./assets/images/laser_blue.png"),

                try rl.loadTexture("./assets/images/planet09.png"),
                try rl.loadTexture("./assets/images/noise08.png"),
                try rl.loadTexture("./assets/images/noise09.png"),
                try rl.loadTexture("./assets/images/noise10.png"),
                try rl.loadTexture("./assets/images/noise11.png"),

                try rl.loadTexture("./assets/ui/images/Blue/Double/button_square_gradient.png"),
                try rl.loadTexture("./assets/ui/images/Blue/Double/check_round_color.png"),
                try rl.loadTexture("./assets/ui/images/Blue/Double/check_round_round_circle.png"),
            },
        };
    }

    pub fn deinit(self: *@This()) void {
        for (self.textures) |texture| {
            texture.unload();
        }
    }

    pub fn get(self: *@This(), texture_id: TextureID) *rl.Texture {
        return &self.textures[@intFromEnum(texture_id)];
    }
};

const AnimatedTextureError = error{
    OutOfMemory,
};

pub const AnimatedTexture = struct {
    textures: [10]?*rl.Texture = std.mem.zeroes([10]?*rl.Texture),
    end: usize = 0,
    speed: f32,
    current_time: f32 = 0,
    current_index: usize = 0,

    pub fn init(speed: f32) @This() {
        return .{
            .speed = speed,
        };
    }

    pub fn add(self: *@This(), texture: *rl.Texture) AnimatedTextureError!void {
        if (self.size >= 10) {
            return AnimatedTextureError.OutOfMemory;
        }
        self.textures[self.size] = texture;
        self.size = self.size + 1;
        if (self.size > 10) {}
    }

    pub fn process(self: *@This(), delta: f32) void {
        self.current_time = self.current_time + delta;
        if (self.current_time >= self.speed) {
            self.current_time = 0.0;
            self.current_index = self.current_index + 1;
            if (self.current_index >= self.size) {
                self.current_index = 0;
            }
        }
    }

    pub fn is_full(self: @This()) bool {
        return self.size >= 9;
    }
};
