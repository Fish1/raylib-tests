const std = @import("std");
const rl = @import("raylib");
const ease = @import("ease.zig");
const TextureLoader = @import("texture_loader.zig").TextureLoader;

const Direction = @import("types.zig").Direction;
const GemColor = @import("types.zig").GemColor;
const GemShape = @import("types.zig").GemShape;
const GemPower = @import("types.zig").GemPower;

pub const Enemy = struct {
    x: i32,
    y: i32,
    px: i32,
    py: i32,
    e: f32,

    rotation: f32,
    rotation_velocity: f32,

    texture_loader: *TextureLoader,
    texture: *rl.Texture,

    color: GemColor,
    shape: GemShape,
    power: ?GemPower,

    pub fn init(x: i32, y: i32, px: i32, py: i32, color: GemColor, shape: GemShape, power: ?GemPower, texture_loader: *TextureLoader) @This() {
        const texture: *rl.Texture = get_texture(color, shape, power, texture_loader);
        return .{
            .x = x,
            .y = y,
            .px = px,
            .py = py,
            .e = 0.0,

            .rotation = 0.0,
            .rotation_velocity = 600.0,

            .texture_loader = texture_loader,
            .texture = texture,

            .color = color,
            .shape = shape,
            .power = power,
        };
    }

    pub fn copy_to(self: @This(), x: i32, y: i32, px: i32, py: i32) @This() {
        const color: GemColor = @enumFromInt(rl.getRandomValue(0, 2));
        const shape: GemShape = @enumFromInt(rl.getRandomValue(0, 2));

        var power: ?GemPower = null;
        const isPower = rl.getRandomValue(0, 9);
        if (isPower == 0) {
            const power_type = rl.getRandomValue(0, 9);
            if (power_type < 5) {
                power = .laser;
            } else if (power_type < 9) {
                power = .large_laser;
            } else if (power_type < 10) {
                power = .giant_laser;
            }
        }
        return Enemy.init(x, y, px, py, color, shape, power, self.texture_loader);
    }

    pub fn process(self: *@This(), delta: f32) void {
        self.e = self.e + delta * 5;
        self.rotation = self.rotation + self.rotation_velocity * delta;
        self.rotation_velocity = @max(20, self.rotation_velocity - 200 * delta);
    }

    pub fn draw(self: @This()) void {
        const x: f32 = ease.ease(.EaseInCubic, @floatFromInt(self.px), @floatFromInt(self.x), self.e);
        const y: f32 = ease.ease(.EaseInCubic, @floatFromInt(self.py), @floatFromInt(self.y), self.e);
        const source: rl.Rectangle = .{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(self.texture.width),
            .height = @floatFromInt(self.texture.height),
        };

        const destination: rl.Rectangle = .{
            .x = (x * 64 + 32),
            .y = (y * 64 + 32),
            .width = 64,
            .height = 64,
        };
        const origin: rl.Vector2 = .{
            .x = 32.0,
            .y = 32.0,
        };

        rl.drawTexturePro(self.texture.*, source, destination, origin, self.rotation, .white);
    }

    pub fn set_type(self: *@This(), color: GemColor, shape: GemShape) void {
        self.rotation_velocity = 900;
        self.color = color;
        self.shape = shape;
        const new_texture: *rl.Texture = get_texture(color, shape, self.power, self.texture_loader);
        self.texture = new_texture;
    }

    pub fn move(self: *@This(), direction: Direction) void {
        self.e = 0.0;
        self.rotation_velocity = 300;
        switch (direction) {
            .left => {
                self.px = self.*.x;
                self.x = self.*.x - 1;
            },
            .right => {
                self.px = self.*.x;
                self.x = self.*.x + 1;
            },
            .up => {
                self.py = self.y;
                self.y = self.y - 1;
            },
            .down => {
                self.py = self.y;
                self.y = self.y + 1;
            },
        }
    }

    pub fn get_texture(color: GemColor, shape: GemShape, power: ?GemPower, texture_loader: *TextureLoader) *rl.Texture {
        var texture: *rl.Texture = undefined;
        if (color == .red) {
            switch (shape) {
                .star => texture = texture_loader.get(.red_star_gem),
                .diamond => texture = texture_loader.get(.red_diamond_gem),
                .pentagon => texture = texture_loader.get(.red_pentagon_gem),
            }
        } else if (color == .green) {
            switch (shape) {
                .star => texture = texture_loader.get(.green_star_gem),
                .diamond => texture = texture_loader.get(.green_diamond_gem),
                .pentagon => texture = texture_loader.get(.green_pentagon_gem),
            }
        } else if (color == .blue) {
            switch (shape) {
                .star => texture = texture_loader.get(.blue_star_gem),
                .diamond => texture = texture_loader.get(.blue_diamond_gem),
                .pentagon => texture = texture_loader.get(.blue_pentagon_gem),
            }
        }

        if (power) |p| {
            switch (p) {
                .laser => texture = texture_loader.get(.grey_pentagon_gem),
                .large_laser => texture = texture_loader.get(.grey_diamond_gem),
                .giant_laser => texture = texture_loader.get(.grey_star_gem),
            }
        }

        return texture;
    }
};
