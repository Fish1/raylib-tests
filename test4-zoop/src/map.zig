const std = @import("std");
const rl = @import("raylib");

const TextureLoader = @import("texture_loader.zig").TextureLoader;
const SoundLoader = @import("audio.zig").SoundLoader;
const SoundQueue = @import("audio.zig").SoundQueue;
const SoundID = @import("audio.zig").SoundID;

const Enemy = @import("enemy.zig").Enemy;
const Player = @import("player.zig").Player;

const Direction = @import("types.zig").Direction;
const Action = @import("types.zig").Action;
const GemColor = @import("types.zig").GemColor;
const GemPower = @import("types.zig").GemPower;
const Difficulty = @import("types.zig").Difficulty;

const width = 14;
const height = 4;
const size = width * height;

const LevelAnnouncement = enum {
    level,
    number,
};

pub const Map = struct {
    enemies: [14 * 4 * 4]?Enemy,
    enemy_prototype: Enemy,

    time_total: f32 = 0.0,

    spawn_time: f32 = 0.01,
    time: f32 = 0.0,

    can_increase_level: bool = false,
    level: i32 = 0,
    level_announcement_state: LevelAnnouncement = .number,

    say_hurry_up_timeout: f32 = 0.0,

    sound_loader: *SoundLoader,
    announcement_sound_queue: SoundQueue = .{},

    difficulty: Difficulty = .medium,

    pub fn init(texture_loader: *TextureLoader, sound_loader: *SoundLoader) !@This() {
        return .{
            .enemies = std.mem.zeroes([14 * 4 * 4]?Enemy),
            .enemy_prototype = .init(0, 0, 0, 0, .red, .star, .laser, false, texture_loader),
            .sound_loader = sound_loader,
        };
    }

    pub fn reset(self: *@This()) void {
        self.time_total = 0.0;
        self.spawn_time = 0.01;
        self.time = 0.0;
        self.enemies = std.mem.zeroes([14 * 4 * 4]?Enemy);
        self.can_increase_level = false;
        self.level_announcement_state = .number;
        self.level = 0;
        self.say_hurry_up_timeout = 0.0;
    }

    pub fn set_difficulty(self: *@This(), difficulty: Difficulty) void {
        self.difficulty = difficulty;
    }

    pub fn process(self: *@This(), player: *Player, delta: f32) void {
        self.time_total = self.time_total + delta;
        // self.spawn_time = (1 / (1 + (self.time_total / 300)));
        self.spawn_time = self.get_spawn_time();
        self.say_hurry_up_timeout = @max(0.0, self.say_hurry_up_timeout - delta);
        // self.spawn_time = 1.0 / @as(f32, @floatFromInt(self.level));

        self.time = self.time + delta;
        if (self.time >= self.spawn_time and player.state == .player_control) {
            self.time = 0.0;
            const wall: Direction = @enumFromInt(rl.getRandomValue(0, 3));
            const wall_part: i32 = rl.getRandomValue(0, 3);

            self.spawn(wall, wall_part);
        }

        for (0..self.enemies.len) |index| {
            if (self.enemies[index]) |*enemy| {
                enemy.process(delta);
            }
        }

        self.can_increase_level = player.score > self.score_required_to_level_up();

        if (self.can_increase_level == true and rl.isKeyPressed(.space)) {
            self.level = self.level + 1;
            std.debug.print("level up = {d}\n", .{self.level});
        }

        if (self.say_hurry_up_timeout <= 0.0 and self.is_gem_close()) {
            self.say_hurry_up_timeout = 20.0;
            _ = self.announcement_sound_queue.add(self.sound_loader.get(.say_hurry_up));
        }

        const next_level = self.get_current_level(player);
        if (next_level != self.level) {
            _ = self.announcement_sound_queue.add(self.sound_loader.get(.say_level));
            const sound_id: SoundID = switch (next_level) {
                1 => .say_one,
                2 => .say_two,
                3 => .say_three,
                4 => .say_four,
                5 => .say_five,
                6 => .say_six,
                7 => .say_seven,
                8 => .say_eight,
                9 => .say_nine,
                else => .say_ten,
            };
            _ = self.announcement_sound_queue.add(self.sound_loader.get(sound_id));
            self.level = next_level;
        }

        self.announcement_sound_queue.process();
    }

    pub fn score_required_to_level_up(self: @This()) i32 {
        const result = @floor(300 * std.math.pow(f32, 1.8, @floatFromInt(self.level)));
        return @intFromFloat(result);
    }

    pub fn add_enemy(self: *@This(), enemy: Enemy) void {
        for (0..self.enemies.len) |index| {
            const _enemy = self.enemies[index];
            if (_enemy) |_| {} else {
                self.enemies[index] = enemy;
                return;
            }
        }
    }

    pub fn spawn(self: *@This(), direction: Direction, wall_part: i32) void {
        if (wall_part < 0 or wall_part >= 4) {
            return;
        }

        if (direction == .left) {
            const y = 14 + wall_part;
            for (&self.enemies) |*_check_enemy| {
                if (_check_enemy.*) |*check_enemy| {
                    if (check_enemy.y != y or check_enemy.x > 14) {
                        continue;
                    }
                    check_enemy.move(.right);
                }
            }
            var new_enemy = self.enemy_prototype.copy_to(0, y, -1, y);
            var power: ?GemPower = null;
            const is_power = rl.getRandomValue(0, 9);
            if (is_power == 0) {
                const power_type = rl.getRandomValue(0, 9);
                if (power_type < 8) {
                    power = .laser;
                } else if (power_type < 10) {
                    power = .large_laser;
                } else if (power_type < 10) {
                    power = .giant_laser;
                }
            }
            new_enemy.set_power(power);
            new_enemy.update_texture();
            self.add_enemy(new_enemy);
        } else if (direction == .up) {
            const x = 14 + wall_part;
            for (&self.enemies) |*_check_enemy| {
                if (_check_enemy.*) |*check_enemy| {
                    if (check_enemy.x != x or check_enemy.y > 14) {
                        continue;
                    }
                    check_enemy.move(.down);
                }
            }
            self.add_enemy(self.enemy_prototype.copy_to(x, 0, x, -1));
        } else if (direction == .right) {
            const y = 14 + wall_part;
            for (&self.enemies) |*_check_enemy| {
                if (_check_enemy.*) |*check_enemy| {
                    if (check_enemy.y != y or check_enemy.x < 14) {
                        continue;
                    }
                    check_enemy.move(.left);
                }
            }
            self.add_enemy(self.enemy_prototype.copy_to(31, y, 32, y));
        } else if (direction == .down) {
            const x = 14 + wall_part;
            for (&self.enemies) |*_check_enemy| {
                if (_check_enemy.*) |*check_enemy| {
                    if (check_enemy.x != x or check_enemy.y < 14) {
                        continue;
                    }
                    check_enemy.move(.up);
                }
            }
            self.add_enemy(self.enemy_prototype.copy_to(x, 31, x, 32));
        }
    }

    pub fn remove_enemy(self: *@This(), x: i32, y: i32) void {
        for (self.enemies, 0..) |_enemy, index| {
            if (_enemy) |enemy| {
                if (enemy.x == x and enemy.y == y) {
                    self.enemies[index] = null;
                }
            }
        }
    }

    pub fn remove_enemies_between(self: *@This(), x: i32, y: i32, x2: i32, y2: i32) i32 {
        var score: i32 = 0;
        for (self.enemies, 0..) |_enemy, index| {
            const enemy = _enemy orelse continue;

            var x_between: bool = undefined;
            if (x < x2) {
                x_between = enemy.x >= x and enemy.x <= x2;
            } else if (x2 <= x) {
                x_between = enemy.x >= x2 and enemy.x <= x;
            }

            var y_between: bool = undefined;
            if (y < y2) {
                y_between = enemy.y >= y and enemy.y <= y2;
            } else if (y2 <= y) {
                y_between = enemy.y >= y2 and enemy.y <= y;
            }

            if (x_between and y_between) {
                self.enemies[index] = null;
                score = score + 1;
            }
        }
        return score;
    }

    pub fn get_enemy(self: *@This(), x: i32, y: i32) ?*Enemy {
        for (&self.enemies) |*__enemy| {
            const _enemy = __enemy.* orelse continue;
            if (_enemy.x == x and _enemy.y == y) {
                if (__enemy.*) |*enemy| {
                    return enemy;
                }
                return null;
            }
        }
        return null;
    }

    pub fn get_jump_to(self: *@This(), x: i32, y: i32, i: GemColor, direction: Direction) struct { x: i32, y: i32, action: Action } {
        var tx: i32 = undefined;
        var ty: i32 = undefined;
        var _first_enemy: ?Enemy = null;

        if (direction == .left) {
            tx = 0;
            ty = y;
        } else if (direction == .up) {
            tx = x;
            ty = 0;
        } else if (direction == .right) {
            tx = 31;
            ty = y;
        } else if (direction == .down) {
            tx = x;
            ty = 31;
        }

        for (self.enemies) |_enemy| {
            const enemy = _enemy orelse continue;
            if (direction == .left) {
                if (enemy.x <= x and enemy.x >= tx and enemy.y == y) {
                    tx = enemy.x;
                    _first_enemy = enemy;
                }
            } else if (direction == .right) {
                if (enemy.x >= x and enemy.x <= tx and enemy.y == y) {
                    tx = enemy.x;
                    _first_enemy = enemy;
                }
            } else if (direction == .up) {
                if (enemy.y <= y and enemy.y >= ty and enemy.x == x) {
                    ty = enemy.y;
                    _first_enemy = enemy;
                }
            } else if (direction == .down) {
                if (enemy.y >= y and enemy.y <= ty and enemy.x == x) {
                    ty = enemy.y;
                    _first_enemy = enemy;
                }
            }
        }

        var action: Action = .swap;
        if (_first_enemy) |first_enemy| {
            if (first_enemy.power) |power| {
                switch (power) {
                    .laser => action = .power_laser,
                    .large_laser => action = .power_large_laser,
                    .giant_laser => action = .power_giant_laser,
                }
            } else if (first_enemy.color == i) {
                action = .score;
            }
        }

        if (action == .score) {
            var new_x = tx;
            var new_y = ty;
            while (true) {
                var position: struct { i32, i32 } = undefined;
                switch (direction) {
                    .left => position = .{ new_x - 1, new_y },
                    .right => position = .{ new_x + 1, new_y },
                    .up => position = .{ new_x, new_y - 1 },
                    .down => position = .{ new_x, new_y + 1 },
                }

                const first_enemy = _first_enemy orelse break;
                const new_enemy = self.get_enemy(position[0], position[1]) orelse break;
                if (first_enemy.power != null) {
                    break;
                }
                if (new_enemy.color != first_enemy.color) {
                    break;
                }
                if (new_enemy.power != null) {
                    break;
                }
                new_x = new_enemy.x;
                new_y = new_enemy.y;
            }
            tx = new_x;
            ty = new_y;
        }

        return .{
            .x = tx,
            .y = ty,
            .action = action,
        };
    }

    pub fn draw(self: @This()) void {
        for (self.enemies) |_enemy| {
            const enemy = _enemy orelse continue;
            enemy.draw();
        }
    }

    pub fn get_x_left(self: @This(), y: i32) i32 {
        const start: usize = @intCast(y * width);
        const end: usize = @intCast((y + 1) * width);
        for (start..end) |index| {
            const _enemy = self.enemies_left[index];
            if (_enemy) |_| {} else {
                const x: i32 = @intCast(@mod(index, width));
                return x;
            }
        }
        return width;
    }

    pub fn get_x_right(self: @This(), y: i32) i32 {
        const start: usize = @intCast(y * width);
        const end: usize = @intCast((y + 1) * width);
        var index: usize = end - 1;
        while (index >= start) : (index = index - 1) {
            const _enemy = self.enemies_right[index];
            if (_enemy) |_| {} else {
                return @intCast(@mod(index, width) + 18);
            }
        }
        return width + 18;
    }

    pub fn get_y_up(x: i32) i32 {
        return x + 1;
    }

    pub fn get_y_down(x: i32) i32 {
        return x + 1;
    }

    pub fn get_spawn_time(self: @This()) f32 {
        const level = self.level;
        return switch (self.difficulty) {
            .easy => (-1.0 / 12.0) * @as(f32, @floatFromInt(level)) + 1.25,
            .medium => (-1.0 / 10.0) * @as(f32, @floatFromInt(level)) + 1.25,
            .hard => (-1.0 / 9.0) * @as(f32, @floatFromInt(level)) + 1.25,
        };
    }

    pub fn get_current_level(_: @This(), player: *Player) i32 {
        return switch (player.score) {
            0...99 => 1,
            100...299 => 2,
            300...599 => 3,
            600...1399 => 4,
            1400...2999 => 5,
            3000...6199 => 6,
            6200...12599 => 7,
            12600...25399 => 8,
            25400...50999 => 9,
            else => 10,
        };
    }

    pub fn get_score_to_levelup(self: @This(), player: *Player) i32 {
        return switch (self.get_current_level(player)) {
            1 => 100,
            2 => 300,
            3 => 600,
            4 => 1400,
            5 => 3000,
            6 => 6200,
            7 => 12600,
            8 => 25400,
            9 => 51000,
            else => 100000,
        };
    }

    pub fn is_game_over(self: *@This()) bool {
        for (self.enemies) |_enemy| {
            const enemy = _enemy orelse continue;
            if (enemy.x >= 14 and enemy.x < 18 and enemy.y >= 14 and enemy.y < 18) {
                return true;
            }
        }
        return false;
    }

    pub fn is_gem_close(self: @This()) bool {
        for (self.enemies) |_enemy| {
            const enemy = _enemy orelse continue;
            if (enemy.y >= 14 and enemy.y <= 17 and enemy.x >= 11 and enemy.x <= 20) {
                return true;
            } else if (enemy.x >= 14 and enemy.x <= 17 and enemy.y >= 11 and enemy.y <= 20) {
                return true;
            }
        }
        return false;
    }
};
