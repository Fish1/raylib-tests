const rl = @import("raylib");

pub const RedEnemy = Enemy.init(0, 0, 0, .red);
pub const GreenEnemy = Enemy.init(0, 0, 1, .green);
pub const BlueEnemy = Enemy.init(0, 0, 2, .blue);

pub const Enemy = struct {
    x: i32,
    y: i32,
    px: i32,
    py: i32,
    e: f32,

    identifier: i32,
    color: rl.Color,

    pub fn init(x: i32, y: i32, identifier: i32, color: rl.Color) @This() {
        return .{
            .x = x,
            .y = y,
            .px = x,
            .py = y,
            .e = 1.0,
            .identifier = identifier,
            .color = color,
        };
    }

    pub fn copy_to(self: @This(), x: i32, y: i32) @This() {
        return .{
            .x = x,
            .y = y,
            .px = x,
            .py = y,
            .e = 1.0,
            .identifier = self.identifier,
            .color = self.color,
        };
    }
};
