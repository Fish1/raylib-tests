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
};

pub const TextureLoader = struct {
    textures: [13]rl.Texture,

    pub fn init() !@This() {
        return .{
            .textures = .{
                try rl.loadTexture("./assets/red_gems/star.png"),
                try rl.loadTexture("./assets/red_gems/diamond.png"),
                try rl.loadTexture("./assets/red_gems/pentagon.png"),
                try rl.loadTexture("./assets/green_gems/star.png"),
                try rl.loadTexture("./assets/green_gems/diamond.png"),
                try rl.loadTexture("./assets/green_gems/pentagon.png"),
                try rl.loadTexture("./assets/blue_gems/star.png"),
                try rl.loadTexture("./assets/blue_gems/diamond.png"),
                try rl.loadTexture("./assets/blue_gems/pentagon.png"),
                try rl.loadTexture("./assets/grey_gems/star.png"),
                try rl.loadTexture("./assets/grey_gems/diamond.png"),
                try rl.loadTexture("./assets/grey_gems/pentagon.png"),
                try rl.loadTexture("./assets/laser.png"),
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
