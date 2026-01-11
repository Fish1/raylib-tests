const rl = @import("raylib");
const std = @import("std");
const Map = @import("map.zig").Map;
const Animation = @import("ease.zig").Animation;

const State = enum {
    player_control,
    attack_init,
    attack_back,
};

pub const Player = struct {
    x: i32,
    y: i32,
    px: i32,
    py: i32,
    e: f32,

    state: State,
    animation: Animation,

    pub fn init() @This() {
        return .{
            .x = 16,
            .y = 16,
            .px = 16,
            .py = 16,
            .e = 0,
            .state = .player_control,
            .animation = .EaseInBack,
        };
    }

    pub fn process(self: *@This(), map: Map, delta: f32) void {
        switch (self.state) {
            .attack_init => attack_init_state(self, delta),
            .attack_back => attack_back_state(self, delta),
            .player_control => player_control_state(self, map, delta),
        }
    }

    fn attack_init_state(self: *@This(), delta: f32) void {
        self.e = self.e + delta * 5;
        self.animation = .EaseInCubic;
        if (self.e >= 1) {
            const rx = self.px;
            const ry = self.py;
            self.px = self.x;
            self.py = self.y;
            self.x = rx;
            self.y = ry;
            self.e = 0;
            self.state = .attack_back;
        }
    }

    fn attack_back_state(self: *@This(), delta: f32) void {
        self.e = self.e + delta * 5;
        self.animation = .EaseInCubic;
        if (self.e >= 1) {
            self.state = .player_control;
        }
    }

    fn player_control_state(self: *@This(), map: Map, delta: f32) void {
        self.e = self.e + delta * 1.5;
        self.animation = .EaseOutElastic;
        if (rl.isKeyPressed(.right) and self.x <= 16) {
            self.py = self.y;
            self.px = self.x;
            self.x = self.x + 1;
            self.e = 0;
        } else if (rl.isKeyPressed(.left) and self.x > 14) {
            self.py = self.y;
            self.px = self.x;
            self.x = self.x - 1;
            self.e = 0;
        } else if (rl.isKeyPressed(.up) and self.y > 14) {
            self.py = self.y;
            self.px = self.x;
            self.y = self.y - 1;
            self.e = 0;
        } else if (rl.isKeyPressed(.down) and self.y <= 16) {
            self.py = self.y;
            self.px = self.x;
            self.y = self.y + 1;
            self.e = 0;
        }

        if (rl.isKeyPressed(.a)) {
            self.px = self.x;
            self.py = self.y;
            const tx = map.get_x_left(self.y - 14);
            std.debug.print("tx = {any}\n", .{tx});
            self.x = tx;
            self.e = 0;
            self.state = .attack_init;
        } else if (rl.isKeyPressed(.s)) {
            self.px = self.x;
            self.py = self.y;
            self.y = 31;
            self.e = 0;
            self.state = .attack_init;
        } else if (rl.isKeyPressed(.d)) {
            self.px = self.x;
            self.py = self.y;
            const tx = map.get_x_right(self.y - 14);
            std.debug.print("tx = {any}\n", .{tx});
            self.x = 31;
            self.x = tx;
            self.e = 0;
            self.state = .attack_init;
        } else if (rl.isKeyPressed(.w)) {
            self.px = self.x;
            self.py = self.y;
            self.y = 0;
            self.e = 0;
            self.state = .attack_init;
        }
    }
};
