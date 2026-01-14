const std = @import("std");
const rl = @import("raylib");
const Enemy = @import("enemy.zig").Enemy;
const Direction = @import("direction.zig").Direction;
const Action = @import("action.zig").Action;

const width = 14;
const height = 4;
const size = width * height;

const RedEnemy = Enemy.init(0, 0, 0, .red);
const GreenEnemy = Enemy.init(0, 0, 1, .green);
const BlueEnemy = Enemy.init(0, 0, 2, .blue);

pub const Map = struct {
    enemies: [14 * 4 * 4]?Enemy = std.mem.zeroes([14 * 4 * 4]?Enemy),

    pub fn init() !@This() {
        var result: Map = .{};

        // result.add_enemy(GreenEnemy.copy_to(14, 0));
        result.add_enemy(RedEnemy.copy_to(14, 0));
        result.add_enemy(RedEnemy.copy_to(14, 1));
        result.add_enemy(RedEnemy.copy_to(14, 2));
        result.add_enemy(RedEnemy.copy_to(14, 3));
        result.add_enemy(RedEnemy.copy_to(15, 0));

        result.add_enemy(RedEnemy.copy_to(0, 14));
        result.add_enemy(GreenEnemy.copy_to(1, 14));
        result.add_enemy(BlueEnemy.copy_to(2, 14));

        result.add_enemy(RedEnemy.copy_to(31, 14));
        result.add_enemy(GreenEnemy.copy_to(30, 14));
        result.add_enemy(BlueEnemy.copy_to(29, 14));

        result.add_enemy(RedEnemy.copy_to(14, 31));
        result.add_enemy(GreenEnemy.copy_to(14, 30));
        result.add_enemy(BlueEnemy.copy_to(14, 29));

        return result;
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

    pub fn spawn_up(self: *@This(), x: i32) void {
        for (&self.enemies) |*_check_enemy| {
            const check_enemy = _check_enemy.* orelse continue;
            if (check_enemy.x != x or check_enemy.y > 14) {
                continue;
            }
            if (_check_enemy.*) |*enemy| {
                enemy.*.y = enemy.*.y + 1;
            }
            // _check_enemy.*.y = check_enemy.y + 1;
        }
        const new_enemy: Enemy = .{
            .x = x,
            .y = 0,
            .px = x,
            .py = 0,
            .identifier = 2,
            .color = .green,
            .e = 1.0,
        };
        self.add_enemy(new_enemy);
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

    pub fn remove_enemies_between(self: *@This(), x: i32, y: i32, x2: i32, y2: i32) void {
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
            }
        }
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
