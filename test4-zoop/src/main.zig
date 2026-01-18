const std = @import("std");
const rl = @import("raylib");
const ease = @import("ease.zig");
const Player = @import("player.zig").Player;
const Map = @import("map.zig").Map;

const tile_size = 64;

const State = enum {
    main_menu,
    game,
    game_over,
};

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

    var state: State = .main_menu;

    rl.initWindow(width, height, "Zoop!");
    defer rl.closeWindow();
    rl.initAudioDevice();
    rl.setTargetFPS(60);

    var map: Map = try Map.init();
    defer map.deinit();
    var player: Player = try Player.init();
    defer player.deinit();

    while (rl.windowShouldClose() == false) {
        switch (state) {
            .main_menu => main_menu_state(&state),
            .game => game_state(&player, &map, &state),
            .game_over => game_over_state(&player, &map, &state),
        }
    }
}

fn main_menu_state(state: *State) void {
    rl.beginDrawing();
    defer rl.endDrawing();
    rl.drawText("Zoop!", 64, 1024 / 4, 64, .white);
    rl.drawText("Press Space to Play", 64, 1024 / 2, 64, .white);
    if (rl.isKeyPressed(.space)) {
        state.* = .game;
    }
}

fn game_over_state(player: *Player, map: *Map, state: *State) void {
    rl.beginDrawing();
    defer rl.endDrawing();

    rl.clearBackground(.black);
    rl.drawText("Game Over!", 64, 1024 / 4, 64, .white);
    rl.drawText("Press Space to Play Again", 64, 1024 / 2, 64, .white);
    if (rl.isKeyPressed(.space)) {
        map.deinit();
        map.* = Map.init() catch unreachable;
        player.deinit();
        player.* = Player.init() catch unreachable;
        state.* = .game;
    }
}

fn game_state(player: *Player, map: *Map, state: *State) void {
    const delta = rl.getFrameTime();
    game_state_process(player, map, delta);
    game_state_draw(player, map);
    if (map.is_game_over()) {
        rl.playSound(map.game_over_sound);
        state.* = .game_over;
    }
}

fn game_state_process(player: *Player, map: *Map, delta: f32) void {
    map.process(player, delta);
    player.process(map, delta);
}

fn game_state_draw(player: *Player, map: *Map) void {
    rl.beginDrawing();
    defer rl.endDrawing();

    rl.beginMode2D(camera);
    rl.clearBackground(.black);
    draw_player_map();
    player.draw();
    map.draw();
    rl.endMode2D();

    var buffer: [32]u8 = undefined;
    const result = std.fmt.bufPrintZ(&buffer, "Score {d}", .{player.score}) catch unreachable;
    rl.drawText(result, 32, 32, 32, .white);

    const result2 = std.fmt.bufPrintZ(&buffer, "Speed {d}", .{map.spawn_time}) catch unreachable;
    rl.drawText(result2, 32, 64, 32, .white);
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
