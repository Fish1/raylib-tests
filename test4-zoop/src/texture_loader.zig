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

    ui_button_square_gradient,
    ui_check_round_color,
    ui_check_round_round_circle,
};

pub const TextureLoader = struct {
    textures: [18]rl.Texture,

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
