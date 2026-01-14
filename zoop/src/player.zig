const rl = @import("raylib");
const std = @import("std");
const Map = @import("map.zig").Map;
const Animation = @import("ease.zig").Animation;
const Action = @import("action.zig").Action;

const State = enum {
    player_control,
    attack_init,
    init_attack_back,
    attack_back,
};

pub const Player = struct {
    x: i32,
    y: i32,
    px: i32,
    py: i32,
    e: f32,

    identifier: i32,
    color: rl.Color,

    state: State,
    animation: Animation,
    action: Action,

    pub fn init() @This() {
        return .{
            .x = 16,
            .y = 16,
            .px = 16,
            .py = 16,
            .e = 0,
            .identifier = 0,
            .color = .red,
            .state = .player_control,
            .animation = .EaseInBack,
            .action = .score,
        };
    }

    pub fn process(self: *@This(), map: *Map, delta: f32) void {
        switch (self.state) {
            .attack_init => attack_init_state(self, delta),
            .init_attack_back => init_attack_back_state(self, map, delta),
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
            self.state = .init_attack_back;
        }
    }

    fn init_attack_back_state(self: *@This(), map: *Map, _: f32) void {
        const _enemy = map.get_enemy(self.px, self.py) orelse {
            self.state = .attack_back;
            return;
        };
        if (_enemy.*) |*enemy| {
            const enemy_color = enemy.color;
            const enemy_identifier = enemy.identifier;
            if (self.action == .swap) {
                enemy.*.color = self.color;
                enemy.*.identifier = self.identifier;
                self.color = enemy_color;
                self.identifier = enemy_identifier;
            } else if (self.action == .score) {
                map.remove_enemies_between(self.x, self.y, self.px, self.py);
            }
        }
        self.state = .attack_back;
    }

    fn attack_back_state(self: *@This(), delta: f32) void {
        self.e = self.e + delta * 5;
        self.animation = .EaseInCubic;
        if (self.e >= 1) {
            self.state = .player_control;
        }
    }

    fn player_control_state(self: *@This(), map: *Map, delta: f32) void {
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
            map.spawn_up(15);
        }

        if (rl.isKeyPressed(.a)) {
            self.px = self.x;
            self.py = self.y;
            const to = map.get_jump_to(self.x, self.y, self.identifier, .left);
            self.x = to.x;
            self.y = to.y;
            self.action = to.action;
            self.e = 0;
            self.state = .attack_init;
        } else if (rl.isKeyPressed(.s)) {
            self.px = self.x;
            self.py = self.y;
            const to = map.get_jump_to(self.x, self.y, self.identifier, .down);
            self.x = to.x;
            self.y = to.y;
            self.action = to.action;
            self.e = 0;
            self.state = .attack_init;
        } else if (rl.isKeyPressed(.d)) {
            self.px = self.x;
            self.py = self.y;
            const to = map.get_jump_to(self.x, self.y, self.identifier, .right);
            self.x = to.x;
            self.y = to.y;
            self.action = to.action;
            self.e = 0;
            self.state = .attack_init;
        } else if (rl.isKeyPressed(.w)) {
            self.px = self.x;
            self.py = self.y;
            const to = map.get_jump_to(self.x, self.y, self.identifier, .up);
            self.x = to.x;
            self.y = to.y;
            self.action = to.action;
            self.e = 0;
            self.state = .attack_init;
        }
    }
};
