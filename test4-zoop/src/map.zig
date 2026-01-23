const std = @import("std");
const rl = @import("raylib");

const TextureLoader = @import("texture_loader.zig").TextureLoader;

const Enemy = @import("enemy.zig").Enemy;
const Player = @import("player.zig").Player;

const Direction = @import("types.zig").Direction;
const Action = @import("types.zig").Action;
const GemColor = @import("types.zig").GemColor;

const width = 14;
const height = 4;
const size = width * height;

pub const Map = struct {
    prng: std.Random.DefaultPrng = undefined,
    rand: std.Random = undefined,

    enemies: [14 * 4 * 4]?Enemy = undefined,

    time_total: f32 = 0.0,

    spawn_time: f32 = undefined,
    time: f32 = undefined,

    enemy: Enemy,

    game_over_sound: rl.Sound,

    pub fn init(texture_loader: *TextureLoader) !@This() {
        const game_over_sound = try rl.loadSound("./assets/gameover.wav");
        var result: Map = .{
            .spawn_time = 0.01,
            .time = 0.0,
            .enemies = std.mem.zeroes([14 * 4 * 4]?Enemy),
            .game_over_sound = game_over_sound,

            .enemy = undefined,
        };

        var prng: std.Random.Xoshiro256 = .init(1);
        result.prng = prng;
        result.rand = prng.random();

        const enemy: Enemy = .init(0, 0, 0, 0, .red, .star, .laser, texture_loader);
        result.enemy = enemy;

        return result;
    }

    pub fn deinit(self: *@This()) void {
        rl.unloadSound(self.game_over_sound);
    }

    pub fn reset(self: *@This()) void {
        self.time_total = 0.0;
        self.time = 0.0;
        self.spawn_time = 0.01;
        self.enemies = std.mem.zeroes([14 * 4 * 4]?Enemy);
    }

    pub fn process(self: *@This(), player: *Player, delta: f32) void {
        self.time_total = self.time_total + delta;
        self.spawn_time = (1 / (1 + (self.time_total / 3)));

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
            self.add_enemy(self.enemy.copy_to(0, y, -1, y));
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
            self.add_enemy(self.enemy.copy_to(x, 0, x, -1));
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
            self.add_enemy(self.enemy.copy_to(31, y, 32, y));
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
            self.add_enemy(self.enemy.copy_to(x, 31, x, 32));
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

    pub fn is_game_over(self: *@This()) bool {
        for (self.enemies) |_enemy| {
            const enemy = _enemy orelse continue;
            if (enemy.x >= 14 and enemy.x < 18 and enemy.y >= 14 and enemy.y < 18) {
                return true;
            }
        }
        return false;
    }
};
