const std = @import("std");
const rl = @import("raylib");
const ease = @import("ease.zig");
const Player = @import("player.zig").Player;
const Map = @import("map.zig").Map;

const tile_size = 64;

var map: Map = Map.init() catch unreachable;
var player: Player = .init();

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

pub fn main() void {
    std.debug.print("Zoop!\n", .{});

    const width = 1024;
    const height = 1024;

    rl.initWindow(width, height, "Zoot");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    while (rl.windowShouldClose() == false) {
        process(rl.getFrameTime());
        draw();
    }
}

fn process(delta: f32) void {
    player.process(&map, delta);
}

fn draw() void {
    rl.beginDrawing();
    defer rl.endDrawing();

    rl.beginMode2D(camera);
    rl.clearBackground(.black);
    draw_player_map();
    draw_player();
    map.draw();
    rl.endMode2D();
}

fn draw_player() void {
    const rx = ease.ease(player.animation, @floatFromInt(player.px), @floatFromInt(player.x), player.e) * tile_size;
    const ry = ease.ease(player.animation, @floatFromInt(player.py), @floatFromInt(player.y), player.e) * tile_size;
    rl.drawCircle(@intFromFloat(rx + 32), @intFromFloat(ry + 32), 32, player.color);
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
