const rl = @import("raylib");
const std = @import("std");
const ease = @import("ease.zig");

const TextureLoader = @import("texture_loader.zig").TextureLoader;

const Map = @import("map.zig").Map;
const Animation = @import("ease.zig").Animation;
const Action = @import("types.zig").Action;

const GemColor = @import("types.zig").GemColor;
const GemPower = @import("types.zig").GemPower;
const Direction = @import("types.zig").Direction;

const State = enum {
    player_control,

    init_attack,
    attack,

    init_attack_back,
    attack_back,

    init_laser,
    laser,
    end_laser,
};

pub const Player = struct {
    x: i32,
    y: i32,
    px: i32,
    py: i32,
    e: f32,

    gem_color: GemColor,

    state: State,
    animation: Animation,
    action: Action,

    score: u64,
    player_texture: rl.Texture,
    texture_index_count: i32,
    texture_index_speed: f32,
    texture_timer: f32,

    laser_x: i32,
    laser_y: i32,
    laser_px: i32,
    laser_py: i32,
    laser_e: f32,
    laser_rotation: i32,
    laser_direction: Direction,
    laser_texture: *rl.Texture,

    score_sound: rl.Sound,
    swap_sound: rl.Sound,
    jump_sound: rl.Sound,
    powerup_sound: rl.Sound,
    laser_sound: rl.Sound,

    power_laser: i32,
    power_large_laser: i32,
    power_giant_laser: i32,

    pub fn init(texture_loader: *TextureLoader) !@This() {
        const score_sound = try rl.loadSound("./assets/score.wav");
        const swap_sound = try rl.loadSound("./assets/swap.wav");
        const jump_sound = try rl.loadSound("./assets/jump.wav");
        const powerup_sound = try rl.loadSound("./assets/powerup.wav");
        const laser_sound = try rl.loadSound("./assets/laser.wav");
        const player_texture = try rl.loadTexture("./assets/player.png");
        return .{
            .x = 16,
            .y = 16,
            .px = 16,
            .py = 16,
            .e = 0,
            .gem_color = .red,
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
            .powerup_sound = powerup_sound,
            .laser_sound = laser_sound,

            .power_laser = 0,
            .power_large_laser = 0,
            .power_giant_laser = 0,

            .laser_x = 0,
            .laser_y = 0,
            .laser_px = 0,
            .laser_py = 0,
            .laser_e = 0,
            .laser_rotation = 0,
            .laser_direction = .left,
            .laser_texture = texture_loader.get(.laser),
        };
    }

    pub fn deinit(self: *@This()) void {
        rl.unloadTexture(self.player_texture);
        rl.unloadSound(self.score_sound);
        rl.unloadSound(self.swap_sound);
        rl.unloadSound(self.jump_sound);
        rl.unloadSound(self.laser_sound);
    }

    pub fn reset(self: *@This()) void {
        self.x = 16;
        self.y = 16;
        self.px = 16;
        self.py = 16;
        self.power_laser = 0;
        self.power_large_laser = 0;
        self.power_giant_laser = 0;
        self.score = 0;
    }

    pub fn process(self: *@This(), map: *Map, delta: f32) void {
        self.texture_timer = self.texture_timer + delta;
        switch (self.state) {
            .init_attack => init_attack_state(self, delta),
            .attack => attack_state(self, delta),
            .init_attack_back => init_attack_back_state(self, map, delta),
            .attack_back => attack_back_state(self, delta),
            .player_control => player_control_state(self, map, delta),
            .init_laser => init_laser_state(self, delta),
            .laser => laser_state(self, delta),
            .end_laser => end_laser_state(self, map, delta),
        }
    }

    pub fn draw(self: @This()) void {
        const rx = ease.ease(self.animation, @floatFromInt(self.px), @floatFromInt(self.x), self.e) * 64;
        const ry = ease.ease(self.animation, @floatFromInt(self.py), @floatFromInt(self.y), self.e) * 64;

        const texture_index_count_float: f32 = @floatFromInt(self.texture_index_count);
        const texture_index_divisor = self.texture_index_speed / texture_index_count_float;

        const t1: i32 = @intFromFloat(@divFloor(self.texture_timer, texture_index_divisor));
        const texture_index = @mod(t1, self.texture_index_count);

        const texture_color_index: i32 = @intFromEnum(self.gem_color);

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

        if (self.state == .laser) {
            const rlx = ease.ease(.EaseInCubic, @floatFromInt(self.laser_px), @floatFromInt(self.laser_x), self.laser_e) * 64;
            const rly = ease.ease(.EaseInCubic, @floatFromInt(self.laser_py), @floatFromInt(self.laser_y), self.laser_e) * 64;
            var rotation: f32 = undefined;
            switch (self.laser_direction) {
                .left => rotation = -90.0,
                .right => rotation = 90.0,
                .up => rotation = 0.0,
                .down => rotation = 180.0,
            }

            const source_laser: rl.Rectangle = .{
                .x = 0,
                .y = 0,
                .width = @floatFromInt(self.laser_texture.width),
                .height = @floatFromInt(self.laser_texture.height),
            };
            const laser_destination: rl.Rectangle = .{
                .x = rlx + 32.0,
                .y = rly + 32.0,
                .width = @floatFromInt(self.laser_texture.width),
                .height = @floatFromInt(self.laser_texture.height),
            };
            const origin: rl.Vector2 = .{
                .x = @as(f32, @floatFromInt(self.laser_texture.width)) / 2.0,
                .y = @as(f32, @floatFromInt(self.laser_texture.height)) / 2.0,
            };
            rl.drawTexturePro(self.laser_texture.*, source_laser, laser_destination, origin, rotation, .white);
        }
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
        const enemy = map.get_enemy(self.px, self.py) orelse {
            self.state = .attack_back;
            return;
        };
        const enemy_color = enemy.color;
        if (self.action == .swap) {
            enemy.set_type(self.gem_color, enemy.shape);
            self.gem_color = enemy_color;
            rl.playSound(self.swap_sound);
        } else if (self.action == .score) {
            const score: u64 = @intCast(map.remove_enemies_between(self.x, self.y, self.px, self.py));
            const score_bonus: u64 = @divFloor(self.score, 100);
            self.score = self.score + std.math.pow(u64, score, 3) + score_bonus;
            rl.playSound(self.score_sound);
        } else if (self.action == .power_laser) {
            _ = map.remove_enemies_between(self.x, self.y, self.px, self.py);
            rl.playSound(self.powerup_sound);
            self.power_laser = self.power_laser + 1;
        } else if (self.action == .power_large_laser) {
            _ = map.remove_enemies_between(self.x, self.y, self.px, self.py);
            rl.playSound(self.powerup_sound);
            self.power_large_laser = self.power_large_laser + 1;
        } else if (self.action == .power_giant_laser) {
            _ = map.remove_enemies_between(self.x, self.y, self.px, self.py);
            rl.playSound(self.powerup_sound);
            self.power_giant_laser = self.power_giant_laser + 1;
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

    fn init_laser_state(self: *@This(), _: f32) void {
        self.state = .laser;
        self.laser_x = self.x;
        self.laser_y = self.y;
        self.laser_px = self.x;
        self.laser_py = self.y;
        switch (self.laser_direction) {
            .left => self.laser_x = -1,
            .right => self.laser_x = 32,
            .up => self.laser_y = -1,
            .down => self.laser_y = 32,
        }
        self.laser_e = 0;
        rl.playSound(self.laser_sound);
    }

    fn laser_state(self: *@This(), delta: f32) void {
        self.laser_e = self.laser_e + delta * 2.0;
        if (self.laser_e > 1.0) {
            self.state = .end_laser;
        }
    }

    fn end_laser_state(self: *@This(), map: *Map, _: f32) void {
        const score: u64 = @intCast(map.remove_enemies_between(self.laser_x, self.laser_y, self.laser_px, self.laser_py));
        const score_bonus: u64 = @divFloor(self.score, 100);
        self.score = self.score + std.math.pow(u64, score, 3) + score_bonus;
        rl.playSound(self.score_sound);
        self.state = .player_control;
    }

    fn shoot_power(self: *@This(), power: GemPower, direction: Direction) void {
        switch (power) {
            .laser => {
                self.action = .score;
                self.state = .init_laser;
                self.laser_direction = direction;
                self.power_laser = 0;
            },
            .large_laser => {
                self.action = .score;
                self.state = .init_laser;
                self.laser_direction = direction;
                self.power_large_laser = 0;
            },
            .giant_laser => {
                self.action = .score;
                self.state = .init_laser;
                self.laser_direction = direction;
                self.power_giant_laser = 0;
            },
        }
    }

    fn collect_gems(self: *@This(), map: *Map, direction: Direction) void {
        const to = map.get_jump_to(self.x, self.y, self.gem_color, direction);
        self.x = to.x;
        self.y = to.y;
        self.action = to.action;
        self.e = 0;
        self.state = .init_attack;
    }

    fn move(self: *@This(), direction: Direction) void {
        var new_x = self.x;
        var new_y = self.y;
        switch (direction) {
            .left => new_x = self.x - 1,
            .right => new_x = self.x + 1,
            .up => new_y = self.y - 1,
            .down => new_y = self.y + 1,
        }

        if (new_x < 14 or new_x > 17 or new_y < 14 or new_y > 17) {
            return;
        }

        self.px = self.x;
        self.py = self.y;
        self.x = new_x;
        self.y = new_y;
        self.e = 0;
    }

    fn player_control_state(self: *@This(), map: *Map, delta: f32) void {
        self.e = self.e + delta * 1.5;
        self.animation = .EaseOutElastic;
        if (rl.isKeyPressed(.right)) {
            self.move(.right);
        } else if (rl.isKeyPressed(.left)) {
            self.move(.left);
        } else if (rl.isKeyPressed(.up)) {
            self.move(.up);
        } else if (rl.isKeyPressed(.down)) {
            self.move(.down);
        }

        if (rl.isKeyPressed(.a)) {
            self.px = self.x;
            self.py = self.y;
            if (self.power_laser >= 3) {
                self.shoot_power(.laser, .left);
            } else {
                self.collect_gems(map, .left);
            }
        } else if (rl.isKeyPressed(.s)) {
            self.px = self.x;
            self.py = self.y;
            if (self.power_laser >= 3) {
                self.shoot_power(.laser, .down);
            } else {
                self.collect_gems(map, .down);
            }
        } else if (rl.isKeyPressed(.d)) {
            self.px = self.x;
            self.py = self.y;
            if (self.power_laser >= 3) {
                self.shoot_power(.laser, .right);
            } else {
                self.collect_gems(map, .right);
            }
        } else if (rl.isKeyPressed(.w)) {
            self.px = self.x;
            self.py = self.y;
            if (self.power_laser >= 3) {
                self.shoot_power(.laser, .up);
            } else {
                self.collect_gems(map, .up);
            }
        }
    }
};
