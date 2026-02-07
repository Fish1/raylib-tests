const std = @import("std");
const rl = @import("raylib");

const Scorer = @import("scorer.zig").Scorer;

const TextureLoader = @import("texture_loader.zig").TextureLoader;
const SoundLoader = @import("audio.zig").SoundLoader;
const MusicLoader = @import("audio.zig").MusicLoader;
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

    level: i32 = 0,
    level_announcement_state: LevelAnnouncement = .number,

    say_hurry_up_timeout: f32 = 0.0,

    sound_loader: *SoundLoader,
    announcement_sound_queue: SoundQueue = .{},

    music_loader: *MusicLoader,

    difficulty: Difficulty = .medium,

    scorer: *Scorer,

    pub fn init(texture_loader: *TextureLoader, sound_loader: *SoundLoader, music_loader: *MusicLoader, scorer: *Scorer) !@This() {
        return .{
            .enemies = std.mem.zeroes([14 * 4 * 4]?Enemy),
            .enemy_prototype = .init(0, 0, 0, 0, .red, .star, .laser, false, texture_loader),
            .sound_loader = sound_loader,
            .music_loader = music_loader,
            .scorer = scorer,
        };
    }

    pub fn reset(self: *@This()) void {
        self.time_total = 0.0;
        self.enemies = std.mem.zeroes([14 * 4 * 4]?Enemy);
        self.level_announcement_state = .number;
        self.level = 0;
        self.say_hurry_up_timeout = 0.0;
    }

    pub fn set_difficulty(self: *@This(), difficulty: Difficulty) void {
        self.difficulty = difficulty;
    }

    pub fn process(self: *@This(), delta: f32) void {
        self.time_total = self.time_total + delta;
        self.say_hurry_up_timeout = @max(0.0, self.say_hurry_up_timeout - delta);

        for (0..self.enemies.len) |index| {
            if (self.enemies[index]) |*enemy| {
                enemy.process(delta);
            }
        }

        if (self.say_hurry_up_timeout <= 0.0 and self.is_gem_close()) {
            self.say_hurry_up_timeout = 20.0;
            self.announcement_sound_queue.add(self.sound_loader.get(.say_hurry_up)) catch unreachable;
        }

        const next_level = self.scorer.get_current_level();
        if (next_level != self.level) {
            self.announcement_sound_queue.add(self.sound_loader.get(.say_level)) catch unreachable;
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
            self.announcement_sound_queue.add(self.sound_loader.get(sound_id)) catch unreachable;
            if (next_level == 1) {
                self.music_loader.play(.easy_song, 2.0, 15.0);
            } else if (self.level < 4 and next_level >= 4 and next_level <= 7) {
                self.music_loader.play(.medium_song, 1.0, 2.0);
            } else if (self.level < 8 and next_level >= 8) {
                self.music_loader.play(.hard_song, 1.0, 2.0);
            }
            self.level = next_level;
        }

        self.announcement_sound_queue.process();
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
            if (first_enemy.goal == true) {
                action = .goal;
            } else if (first_enemy.power) |power| {
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
                if (new_enemy.goal == true or
                    new_enemy.power != null or
                    new_enemy.color != first_enemy.color)
                {
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
