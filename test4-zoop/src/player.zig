const rl = @import("raylib");
const std = @import("std");
const Map = @import("map.zig").Map;
const Animation = @import("ease.zig").Animation;
const Action = @import("action.zig").Action;
const ease = @import("ease.zig");

const State = enum {
    player_control,

    init_attack,
    attack,

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

    score: u64,
    player_texture: rl.Texture,
    texture_index_count: i32,
    texture_index_speed: f32,
    texture_timer: f32,

    score_sound: rl.Sound,
    swap_sound: rl.Sound,
    jump_sound: rl.Sound,

    pub fn init() !@This() {
        const score_sound = try rl.loadSound("./assets/score.wav");
        const swap_sound = try rl.loadSound("./assets/swap.wav");
        const jump_sound = try rl.loadSound("./assets/jump.wav");
        const player_texture = try rl.loadTexture("./assets/player.png");
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
            .score = 0,
            .player_texture = player_texture,
            .texture_index_count = 2,
            .texture_index_speed = 0.7,
            .texture_timer = 0.0,
            .score_sound = score_sound,
            .swap_sound = swap_sound,
            .jump_sound = jump_sound,
        };
    }

    pub fn deinit(self: *@This()) void {
        rl.unloadTexture(self.player_texture);
        rl.unloadSound(self.score_sound);
        rl.unloadSound(self.swap_sound);
        rl.unloadSound(self.jump_sound);
    }

    pub fn process(self: *@This(), map: *Map, delta: f32) void {
        self.texture_timer = self.texture_timer + delta;
        switch (self.state) {
            .init_attack => init_attack_state(self, delta),
            .attack => attack_state(self, delta),
            .init_attack_back => init_attack_back_state(self, map, delta),
            .attack_back => attack_back_state(self, delta),
            .player_control => player_control_state(self, map, delta),
        }
    }

    pub fn draw(self: @This()) void {
        const rx = ease.ease(self.animation, @floatFromInt(self.px), @floatFromInt(self.x), self.e) * 64;
        const ry = ease.ease(self.animation, @floatFromInt(self.py), @floatFromInt(self.y), self.e) * 64;

        const texture_index_count_float: f32 = @floatFromInt(self.texture_index_count);
        const texture_index_divisor = self.texture_index_speed / texture_index_count_float;

        const t1: i32 = @intFromFloat(@divFloor(self.texture_timer, texture_index_divisor));
        const texture_index = @mod(t1, self.texture_index_count);

        const texture_color_index: i32 = self.identifier;

        const source: rl.Rectangle = .{
            .x = @floatFromInt(texture_index * 16),
            .y = @floatFromInt(texture_color_index * 16),
            .width = 16,
            .height = 16,
        };
        const destination: rl.Rectangle = .{
            .x = rx,
            .y = ry,
            .width = 64,
            .height = 64,
        };

        rl.drawTexturePro(self.player_texture, source, destination, .zero(), 0.0, .white);
    }

    fn init_attack_state(self: *@This(), _: f32) void {
        rl.playSound(self.jump_sound);
        self.state = .attack;
    }

    fn attack_state(self: *@This(), delta: f32) void {
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
                rl.playSound(self.swap_sound);
            } else if (self.action == .score) {
                const score: u64 = @intCast(map.remove_enemies_between(self.x, self.y, self.px, self.py));
                const score_bonus: u64 = @divFloor(self.score, 100);
                self.score = self.score + std.math.pow(u64, score, 3) + score_bonus;
                rl.playSound(self.score_sound);
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
        if (rl.isKeyPressed(.right)) {
            self.py = self.y;
            self.px = self.x;
            self.x = self.x + 1;
            if (self.x > 17) {
                self.x = 14;
            }
            self.e = 0;
        } else if (rl.isKeyPressed(.left)) {
            self.py = self.y;
            self.px = self.x;
            self.x = self.x - 1;
            if (self.x < 14) {
                self.x = 17;
            }
            self.e = 0;
        } else if (rl.isKeyPressed(.up)) {
            self.py = self.y;
            self.px = self.x;
            self.y = self.y - 1;
            if (self.y < 14) {
                self.y = 17;
            }
            self.e = 0;
        } else if (rl.isKeyPressed(.down)) {
            self.py = self.y;
            self.px = self.x;
            self.y = self.y + 1;
            if (self.y > 17) {
                self.y = 14;
            }
            self.e = 0;
        }

        if (rl.isKeyPressed(.a)) {
            self.px = self.x;
            self.py = self.y;
            const to = map.get_jump_to(self.x, self.y, self.identifier, .left);
            self.x = to.x;
            self.y = to.y;
            self.action = to.action;
            self.e = 0;
            self.state = .init_attack;
        } else if (rl.isKeyPressed(.s)) {
            self.px = self.x;
            self.py = self.y;
            const to = map.get_jump_to(self.x, self.y, self.identifier, .down);
            self.x = to.x;
            self.y = to.y;
            self.action = to.action;
            self.e = 0;
            self.state = .init_attack;
        } else if (rl.isKeyPressed(.d)) {
            self.px = self.x;
            self.py = self.y;
            const to = map.get_jump_to(self.x, self.y, self.identifier, .right);
            self.x = to.x;
            self.y = to.y;
            self.action = to.action;
            self.e = 0;
            self.state = .init_attack;
        } else if (rl.isKeyPressed(.w)) {
            self.px = self.x;
            self.py = self.y;
            const to = map.get_jump_to(self.x, self.y, self.identifier, .up);
            self.x = to.x;
            self.y = to.y;
            self.action = to.action;
            self.e = 0;
            self.state = .init_attack;
        }
    }
};
