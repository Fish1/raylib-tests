const std = @import("std");
const rl = @import("raylib");
const Enemy = @import("enemy.zig").Enemy;
const Player = @import("player.zig").Player;
const Direction = @import("direction.zig").Direction;
const Action = @import("action.zig").Action;

const EnemyTypes = @import("enemy_types.zig");

const width = 14;
const height = 4;
const size = width * height;

pub const Map = struct {
    prng: std.Random.DefaultPrng = undefined,
    rand: std.Random = undefined,
    enemies: [14 * 4 * 4]?Enemy = undefined,

    spawn_time: f32 = undefined,
    time: f32 = undefined,

    pub fn init() !@This() {
        var result: Map = .{};

        result.spawn_time = 1.0;
        result.time = 0.0;

        result.enemies = std.mem.zeroes([14 * 4 * 4]?Enemy);

        result.prng = .init(blk: {
            var seed: u64 = undefined;
            try std.posix.getrandom(std.mem.asBytes(&seed));
            break :blk seed;
        });
        result.rand = result.prng.random();

        return result;
    }

    pub fn process(self: *@This(), player: *Player, delta: f32) void {
        self.time = self.time + delta;
        if (self.time >= self.spawn_time and player.state == .player_control) {
            self.time = 0.0;
            const wall = self.rand.intRangeLessThan(i32, 0, 4);
            const wall_part = self.rand.intRangeLessThan(i32, 0, 4);
            const enemy_rand = self.rand.intRangeLessThan(i32, 0, 4);

            var direction: Direction = undefined;
            switch (wall) {
                0 => direction = .left,
                1 => direction = .up,
                2 => direction = .right,
                3 => direction = .down,
                else => direction = .left,
            }

            var en: Enemy = undefined;
            switch (enemy_rand) {
                0 => en = EnemyTypes.RedEnemy,
                1 => en = EnemyTypes.GreenEnemy,
                2 => en = EnemyTypes.BlueEnemy,
                3 => en = EnemyTypes.BlueEnemy,
                else => en = EnemyTypes.RedEnemy,
            }
            self.spawn(direction, wall_part, en);
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

    pub fn spawn(self: *@This(), direction: Direction, wall_part: i32, enemy_copy: Enemy) void {
        if (direction == .left) {
            const y = 14 + wall_part;
            for (&self.enemies) |*_check_enemy| {
                const check_enemy = _check_enemy.* orelse continue;
                if (check_enemy.y != y or check_enemy.x > 14) {
                    continue;
                }
                if (_check_enemy.*) |*enemy| {
                    enemy.*.x = enemy.*.x + 1;
                }
            }
            self.add_enemy(enemy_copy.copy_to(0, y));
        } else if (direction == .up) {
            const x = 14 + wall_part;
            for (&self.enemies) |*_check_enemy| {
                const check_enemy = _check_enemy.* orelse continue;
                if (check_enemy.x != x or check_enemy.y > 14) {
                    continue;
                }
                if (_check_enemy.*) |*enemy| {
                    enemy.*.y = enemy.*.y + 1;
                }
            }
            self.add_enemy(enemy_copy.copy_to(x, 0));
        } else if (direction == .right) {
            const y = 14 + wall_part;
            for (&self.enemies) |*_check_enemy| {
                const check_enemy = _check_enemy.* orelse continue;
                if (check_enemy.y != y or check_enemy.x < 14) {
                    continue;
                }
                if (_check_enemy.*) |*enemy| {
                    enemy.*.x = enemy.*.x - 1;
                }
            }
            self.add_enemy(enemy_copy.copy_to(31, y));
        } else if (direction == .down) {
            const x = 14 + wall_part;
            for (&self.enemies) |*_check_enemy| {
                const check_enemy = _check_enemy.* orelse continue;
                if (check_enemy.x != x or check_enemy.y < 14) {
                    continue;
                }
                if (_check_enemy.*) |*enemy| {
                    enemy.*.y = enemy.*.y - 1;
                }
            }
            self.add_enemy(enemy_copy.copy_to(x, 31));
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

    pub fn get_enemy(self: *@This(), x: i32, y: i32) ?*?Enemy {
        for (&self.enemies) |*_enemy| {
            const enemy = _enemy.* orelse continue;
            if (enemy.x == x and enemy.y == y) {
                return _enemy;
            }
        }
        return null;
    }

    pub fn get_jump_to(self: *@This(), x: i32, y: i32, i: i32, direction: Direction) struct { x: i32, y: i32, action: Action } {
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
            if (first_enemy.identifier == i) {
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
                const _new_enemy = self.get_enemy(position[0], position[1]) orelse break;
                const new_enemy = _new_enemy.* orelse break;
                if (new_enemy.identifier != first_enemy.identifier) {
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
        const tile_size = 64;

        for (self.enemies) |_enemy| {
            const enemy = _enemy orelse continue;
            const x = enemy.x * tile_size;
            const y = enemy.y * tile_size;
            rl.drawRectangle(x, y, tile_size, tile_size, enemy.color);
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
};
