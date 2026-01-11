const std = @import("std");
const rl = @import("raylib");
const Enemy = @import("enemy.zig").Enemy;

const width = 14;
const height = 4;
const size = width * height;

pub const Map = struct {
    enemies_left: [size]?Enemy = std.mem.zeroes([size]?Enemy),
    enemies_right: [size]?Enemy = std.mem.zeroes([size]?Enemy),
    enemies_up: [size]?Enemy = std.mem.zeroes([size]?Enemy),
    enemies_down: [size]?Enemy = std.mem.zeroes([size]?Enemy),

    enemies: [14 * 4 * 4]?Enemy = std.mem.zeroes([14 * 4 * 4]?Enemy),

    pub fn init() !@This() {
        var result: Map = .{};
        // result.enemies_left[0] = .{ .red = .init(0, 0) };
        // result.enemies_right[0] = .{ .blue = .init(0, 0) };
        // result.enemies_up[0] = .{ .green = .init(0, 0) };
        // result.enemies_down[0] = .{ .green = .init(0, 0) };

        result.add_enemy(.{ .red = .init(14, 0) });
        result.add_enemy(.{ .green = .init(15, 0) });
        result.add_enemy(.{ .blue = .init(16, 0) });
        result.add_enemy(.{ .black = .init(17, 0) });
        result.add_enemy(.{ .red = .init(1, 1) });

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

    pub fn get_enemy(self: @This(), x: i32, y: i32) ?Enemy {
        for (0..self.enemies.len) |index| {
            const _enemy = self.enemies[index];
            if (_enemy) |enemy| {
                switch (enemy) {
                    inline else => |e| {
                        if (e.z == x and e.y == y) {
                            return e;
                        }
                    },
                }
            }
        }
        return null;
    }

    pub fn draw(self: @This()) void {
        const tile_size = 64;

        for (self.enemies) |__enemy| {
            const _enemy = __enemy orelse continue;
            switch (_enemy) {
                inline .red, .green, .blue, .black => |enemy| {
                    const x = enemy.x * tile_size;
                    const y = enemy.y * tile_size;
                    rl.drawRectangle(x, y, tile_size, tile_size, enemy.color);
                },
            }
        }

        for (0..width * height) |index| {
            const _e = self.enemies_left[index];
            if (_e) |e| {
                const tx = @mod(index, width);
                const px: i32 = @intCast(tx * tile_size);
                const ty = @divFloor(index, width) + width;
                const py: i32 = @intCast(ty * tile_size);
                switch (e) {
                    inline else => |re| {
                        rl.drawRectangle(px, py, tile_size, tile_size, re.color);
                    },
                }
            }

            const _e2 = self.enemies_right[index];
            if (_e2) |e| {
                const tx = 31 - @mod(index, width);
                const px: i32 = @intCast(tx * tile_size);
                const ty = width + 3 - @divFloor(index, width);
                const py: i32 = @intCast(ty * tile_size);
                switch (e) {
                    .red => |re| {
                        rl.drawRectangle(px, py, tile_size, tile_size, re.color);
                    },
                    .green => |ge| {
                        rl.drawRectangle(px, py, tile_size, tile_size, ge.color);
                    },
                    .blue => |be| {
                        rl.drawRectangle(px, py, tile_size, tile_size, be.color);
                    },
                    .black => |ge| {
                        rl.drawRectangle(px, py, tile_size, tile_size, ge.color);
                    },
                }
            }

            const _e3 = self.enemies_up[index];
            if (_e3) |e| {
                const tx = width + 3 - @divFloor(index, width);
                const px: i32 = @intCast(tx * tile_size);
                const ty = @mod(index, width);
                const py: i32 = @intCast(ty * tile_size);
                switch (e) {
                    .red => |re| {
                        rl.drawRectangle(px, py, tile_size, tile_size, re.color);
                    },
                    .green => |ge| {
                        rl.drawRectangle(px, py, tile_size, tile_size, ge.color);
                    },
                    .blue => |be| {
                        rl.drawRectangle(px, py, tile_size, tile_size, be.color);
                    },
                    .black => |ge| {
                        rl.drawRectangle(px, py, tile_size, tile_size, ge.color);
                    },
                }
            }

            const _e4 = self.enemies_down[index];
            if (_e4) |e| {
                const tx = width + @divFloor(index, width);
                const px: i32 = @intCast(tx * tile_size);
                const ty = 31 - @mod(index, width);
                const py: i32 = @intCast(ty * tile_size);
                switch (e) {
                    .red => |re| {
                        rl.drawRectangle(px, py, tile_size, tile_size, re.color);
                    },
                    .green => |ge| {
                        rl.drawRectangle(px, py, tile_size, tile_size, ge.color);
                    },
                    .blue => |be| {
                        rl.drawRectangle(px, py, tile_size, tile_size, be.color);
                    },
                    .black => |ge| {
                        rl.drawRectangle(px, py, tile_size, tile_size, ge.color);
                    },
                }
            }
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
