const std = @import("std");
const rl = @import("raylib");
const ease = @import("ease.zig");
const Player = @import("player.zig").Player;
const Map = @import("map.zig").Map;

const tile_size = 64;

var camera: rl.Camera2D = .{
    .offset = .{
        .x = 0,
        .y = 0,
    },
    .target = .{
        .x = 0,
        .y = 0,
    },
    .zoom = 0.5,
    .rotation = 0.0,
};

pub fn main() !void {
    std.debug.print("Zoop!\n", .{});

    var map: Map = try Map.init();
    var player: Player = .init();

    const width = 1024;
    const height = 1024;

    rl.initWindow(width, height, "Zoop!");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    while (rl.windowShouldClose() == false) {
        const delta = rl.getFrameTime();
        process(&player, &map, delta);
        draw(&player, &map);
    }
}

fn process(player: *Player, map: *Map, delta: f32) void {
    map.process(delta);
    player.process(map, delta);
}

fn draw(player: *Player, map: *Map) void {
    rl.beginDrawing();
    defer rl.endDrawing();

    rl.beginMode2D(camera);
    rl.clearBackground(.black);
    draw_player_map();
    player.draw();
    map.draw();
    rl.endMode2D();
}

fn draw_player_map() void {
    const width = 4;
    const height = 4;
    for (0..width * height) |index| {
        const x: i32 = @intCast(@mod(index, width) * tile_size + (tile_size * 14));
        const y: i32 = @intCast(@divFloor(index, height) * tile_size + (tile_size * 14));
        rl.drawRectangle(x, y, tile_size, tile_size, .gray);
        rl.drawCircle(x + 32, y + 32, tile_size * 0.1, .black);
    }
}
