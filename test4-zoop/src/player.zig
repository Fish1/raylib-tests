const rl = @import("raylib");
const std = @import("std");
const ease = @import("ease.zig");

const Score = @import("score.zig");

const TextureLoader = @import("texture_loader.zig").TextureLoader;
const SoundLoader = @import("audio.zig").SoundLoader;

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

    init_large_laser,
    large_laser,
    end_large_laser,
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

    goals: i32,
    player_texture: *rl.Texture,
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

    red_laser_texture: *rl.Texture,
    green_laser_texture: *rl.Texture,
    blue_laser_texture: *rl.Texture,

    power_laser: i32,
    power_large_laser: i32,
    power_giant_laser: i32,

    sound_loader: *SoundLoader,

    pub fn init(texture_loader: *TextureLoader, sound_loader: *SoundLoader) !@This() {
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
            .goals = 0,
            .player_texture = texture_loader.get(.player),
            .texture_index_count = 2,
            .texture_index_speed = 0.7,
            .texture_timer = 0.0,

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

            .red_laser_texture = texture_loader.get(.laser_red),
            .green_laser_texture = texture_loader.get(.laser_green),
            .blue_laser_texture = texture_loader.get(.laser_blue),

            .sound_loader = sound_loader,
        };
    }

    pub fn reset(self: *@This()) void {
        self.x = 16;
        self.y = 16;
        self.px = 16;
        self.py = 16;
        self.power_laser = 0;
        self.power_large_laser = 0;
        self.power_giant_laser = 0;
        self.goals = 0;
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

            .init_large_laser => init_large_laser_state(self, delta),
            .large_laser => large_laser_state(self, delta),
            .end_large_laser => end_large_laser_state(self, map, delta),
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

        rl.drawTexturePro(self.player_texture.*, source, destination, .zero(), 0.0, .white);

        if (self.state == .laser or self.state == .large_laser) {
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
            var laser_destination: rl.Rectangle = .{
                .x = rlx + 32.0,
                .y = rly + 32.0,
                .width = @floatFromInt(self.laser_texture.width),
                .height = @floatFromInt(self.laser_texture.height),
            };

            if (self.state == .large_laser) {
                laser_destination.width = laser_destination.width * 4;
            }

            const origin: rl.Vector2 = .{
                .x = @as(f32, @floatFromInt(self.laser_texture.width)) / 2.0,
                .y = @as(f32, @floatFromInt(self.laser_texture.height)) / 2.0,
            };
            rl.drawTexturePro(self.laser_texture.*, source_laser, laser_destination, origin, rotation, .white);
        }
    }

    fn init_attack_state(self: *@This(), _: f32) void {
        self.sound_loader.play(.jump);
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
            self.sound_loader.play(.swap);
        } else if (self.action == .score) {
            const gems = map.remove_enemies_between(self.x, self.y, self.px, self.py);
            Score.score = Score.score + Score.calculate_score(gems);
            self.sound_loader.play(.score);
            Score.increase_pickup_speed_multiplier();
        } else if (self.action == .goal) {
            _ = map.remove_enemies_between(self.x, self.y, self.px, self.py);
            self.goals = self.goals + 1;
            self.sound_loader.play(.score);
            Score.increase_pickup_speed_multiplier();
        } else if (self.action == .power_laser) {
            _ = map.remove_enemies_between(self.x, self.y, self.px, self.py);
            self.power_laser = self.power_laser + 1;
            self.sound_loader.play(.powerup);
            Score.increase_pickup_speed_multiplier();
            if (self.power_laser >= 3) {
                self.sound_loader.play(.say_power_up);
            }
        } else if (self.action == .power_large_laser) {
            _ = map.remove_enemies_between(self.x, self.y, self.px, self.py);
            self.power_large_laser = self.power_large_laser + 1;
            self.sound_loader.play(.powerup);
            Score.increase_pickup_speed_multiplier();
            if (self.power_large_laser >= 3) {
                self.sound_loader.play(.say_power_up);
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
        self.sound_loader.play(.laser);
    }

    fn laser_state(self: *@This(), delta: f32) void {
        self.laser_e = self.laser_e + delta * 2.0;
        if (self.laser_e > 1.0) {
            self.state = .end_laser;
        }
    }

    fn end_laser_state(self: *@This(), map: *Map, _: f32) void {
        const gems = map.remove_enemies_between(self.laser_x, self.laser_y, self.laser_px, self.laser_py);
        Score.add_gem_score(gems);
        self.state = .player_control;
        self.sound_loader.play(.score);
    }

    fn init_large_laser_state(self: *@This(), _: f32) void {
        self.state = .large_laser;
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
        self.sound_loader.play(.laser);
    }

    fn large_laser_state(self: *@This(), delta: f32) void {
        self.laser_e = self.laser_e + delta * 2.0;
        if (self.laser_e > 1.0) {
            self.state = .end_large_laser;
        }
    }

    fn end_large_laser_state(self: *@This(), map: *Map, _: f32) void {
        const gems: i32 = switch (self.laser_direction) {
            .left => @intCast(map.remove_enemies_between(0, 0, 13, 31)),
            .right => @intCast(map.remove_enemies_between(18, 0, 31, 31)),
            .up => @intCast(map.remove_enemies_between(0, 0, 31, 13)),
            .down => @intCast(map.remove_enemies_between(0, 18, 31, 31)),
        };
        Score.add_gem_score(gems);
        self.state = .player_control;
        self.sound_loader.play(.score);
    }

    fn shoot_power(self: *@This(), power: GemPower, direction: Direction) void {
        self.action = .score;
        self.laser_direction = direction;
        switch (power) {
            .laser => {
                self.state = .init_laser;
                self.power_laser = 0;
            },
            .large_laser => {
                self.state = .init_large_laser;
                self.power_large_laser = 0;
            },
            .giant_laser => {
                self.state = .init_laser;
                self.power_giant_laser = 0;
            },
        }
    }

    fn collect_gems(self: *@This(), map: *Map, direction: Direction) void {
        self.px = self.x;
        self.py = self.y;
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
        Score.process_pickup_speed_muliplier_timer(delta);

        if (rl.isKeyPressed(.right)) {
            self.move(.right);
        } else if (rl.isKeyPressed(.left)) {
            self.move(.left);
        } else if (rl.isKeyPressed(.up)) {
            self.move(.up);
        } else if (rl.isKeyPressed(.down)) {
            self.move(.down);
        }

        var action_direction: ?Direction = null;
        if (rl.isKeyPressed(.a)) {
            action_direction = .left;
        } else if (rl.isKeyPressed(.d)) {
            action_direction = .right;
        } else if (rl.isKeyPressed(.w)) {
            action_direction = .up;
        } else if (rl.isKeyPressed(.s)) {
            action_direction = .down;
        }

        if (action_direction) |direction| {
            if (self.power_laser >= 3) {
                self.shoot_power(.laser, direction);
            } else if (self.power_large_laser >= 3) {
                self.shoot_power(.large_laser, direction);
            } else {
                self.collect_gems(map, direction);
            }
        }
    }
};
