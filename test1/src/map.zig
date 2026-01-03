const std = @import("std");
const rl = @import("raylib");

const Tower = @import("tower.zig").Tower;
const Enemy = @import("enemy.zig").Enemy;

pub fn Map(width: usize) type {
    return struct {
        size: usize = width * width,
        towers: [width * width]?Tower,
        enemies: [width * width]?Enemy,
        build_position: rl.Vector2 = rl.Vector2{ .x = 0, .y = 0 },

        pub fn init() @This() {
            return @This(){
                .towers = std.mem.zeroes([width * width]?Tower),
                .enemies = std.mem.zeroes([width * width]?Enemy),
            };
        }

        pub fn add_tower(self: *@This(), tower: Tower, x: usize, y: usize) void {
            const index = (y * width) + x;
            self.towers[index] = tower;
        }

        pub fn add_enemy(self: *@This(), enemy: Enemy, x: usize, y: usize) void {
            const index = (y * width) + x;
            self.enemies[index] = enemy;
        }

        pub fn process(self: *@This(), camera: rl.Camera2D) void {
            self.put_build_template(camera);
        }

        pub fn put_build_template(self: *@This(), camera: rl.Camera2D) void {
            const world_position = rl.getScreenToWorld2D(rl.getMousePosition(), camera);
            self.build_position = world_position;
            std.debug.print("pos = {any}\n", .{self.build_position});
        }

        pub fn next_turn(self: *@This()) void {
            std.debug.print("next turn!\n", .{});

            for (self.enemies, 0..) |_enemy, index| {
                if (_enemy) |enemy| {
                    const x: usize = @intCast(index % width);
                    const y: usize = @intCast(index / width);
                    if (x + 1 >= width or y >= width) {
                        continue;
                    }
                    const new_index: usize = (y * width) + (x + 1);
                    if (self.towers[new_index]) |_| {
                        continue;
                    }
                    self.enemies[new_index] = enemy;
                    self.enemies[index] = null;
                }
            }
        }

        pub fn draw(self: @This()) void {
            for (self.towers, 0..) |_tower, index| {
                if (_tower) |tower| {
                    const x: i32 = @intCast(index % width);
                    const y: i32 = @intCast(index / width);
                    const px = x * 64;
                    const py = y * 64;
                    rl.drawRectangle(px, py, 64, 64, tower.color);
                }
            }

            for (self.enemies, 0..) |_enemy, index| {
                if (_enemy) |enemy| {
                    const x: i32 = @intCast(index % width);
                    const y: i32 = @intCast(index / width);
                    const px = x * 64;
                    const py = y * 64;
                    rl.drawRectangle(px, py, 64, 64, enemy.color);
                }
            }

            const build_tile_x: i32 = @intFromFloat(@floor(self.build_position.x / 64.0));
            const build_world_x: i32 = build_tile_x * 64;
            const build_tile_y: i32 = @intFromFloat(@floor(self.build_position.y / 64.0));
            const build_world_y: i32 = build_tile_y * 64;

            rl.drawRectangle(build_world_x, build_world_y, 12, 12, .white);
            rl.drawRectangle(build_world_x + 64 - 12, build_world_y, 12, 12, .white);
            rl.drawRectangle(build_world_x, build_world_y + 64 - 12, 12, 12, .white);
            rl.drawRectangle(build_world_x + 64 - 12, build_world_y + 64 - 12, 12, 12, .white);
        }
    };
}
