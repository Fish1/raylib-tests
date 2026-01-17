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

    const width = 1024;
    const height = 1024;

    rl.initWindow(width, height, "Zoop!");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var map: Map = try Map.init();
    var player: Player = try Player.init();
    defer player.deinit();

    while (rl.windowShouldClose() == false) {
        const delta = rl.getFrameTime();
        process(&player, &map, delta);
        draw(&player, &map);
    }
}

fn process(player: *Player, map: *Map, delta: f32) void {
    map.process(player, delta);
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

    var buffer: [32]u8 = undefined;
    const result = std.fmt.bufPrintZ(&buffer, "score: {d}", .{player.score}) catch unreachable;
    rl.drawText(result, 15, 15, 24, .white);
}

fn draw_player_map() void {
    const width = 32;
    const height = 32;
    for (0..width * height) |index| {
        const tx: i32 = @intCast(@mod(index, width));
        const ty: i32 = @intCast(@divFloor(index, height));
        const x: i32 = @intCast(tx * tile_size);
        const y: i32 = @intCast(ty * tile_size);
        if (tx >= 14 and tx < 18 and ty >= 14 and ty < 18) {
            rl.drawRectangle(x, y, tile_size, tile_size, .gray);
            rl.drawCircle(x + 32, y + 32, tile_size * 0.1, .black);
        } else if (tx >= 14 and tx < 18 or ty >= 14 and ty < 18) {
            rl.drawCircle(x + 32, y + 32, tile_size * 0.1, .dark_gray);
        }
    }
}
