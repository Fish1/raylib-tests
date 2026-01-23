const std = @import("std");
const rl = @import("raylib");
const ease = @import("ease.zig");
const Player = @import("player.zig").Player;
const Map = @import("map.zig").Map;

const TextureLoader = @import("texture_loader.zig").TextureLoader;
const FontLoader = @import("font_loader.zig").FontLoader;

const tile_size = 64;

const State = enum {
    main_menu,
    game,
    game_over,
};

var game_over_score: u64 = undefined;

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
    const width = 1024;
    const height = 1024;

    var state: State = .main_menu;

    rl.initWindow(width, height, "Zoop!");
    defer rl.closeWindow();
    rl.initAudioDevice();
    rl.setTargetFPS(60);

    var texture_loader = try TextureLoader.init();
    defer texture_loader.deinit();

    var font_loader = try FontLoader.init();
    defer font_loader.deinit();

    const music: rl.Music = try rl.loadMusicStream("./assets/song.wav");
    defer rl.unloadMusicStream(music);
    rl.playMusicStream(music);

    var map: Map = try Map.init(&texture_loader);
    defer map.deinit();
    var player: Player = try Player.init(&texture_loader);
    defer player.deinit();

    while (rl.windowShouldClose() == false) {
        rl.updateMusicStream(music);
        switch (state) {
            .main_menu => main_menu_state(&font_loader, &state),
            .game => game_state(&font_loader, &player, &map, &state),
            .game_over => game_over_state(&font_loader, &player, &map, &state),
        }
    }
}

fn main_menu_state(font_loader: *FontLoader, state: *State) void {
    rl.beginDrawing();
    defer rl.endDrawing();
    var position: rl.Vector2 = .{
        .x = 64,
        .y = 1024 / 4,
    };
    rl.drawTextEx(font_loader.get(.kenney_future).*, "Zoop!", position, 64, 0, .white);
    position.y = 1024 / 2;
    rl.drawTextEx(font_loader.get(.kenney_future).*, "Press Space to Play", position, 64, 0, .white);
    if (rl.isKeyPressed(.space)) {
        state.* = .game;
    }
}

fn game_over_state(font_loader: *FontLoader, player: *Player, map: *Map, state: *State) void {
    rl.beginDrawing();
    defer rl.endDrawing();

    var buffer: [32]u8 = undefined;
    const score_text = std.fmt.bufPrintZ(&buffer, "You scored {d}!", .{game_over_score}) catch unreachable;

    rl.clearBackground(.black);

    var position: rl.Vector2 = .{
        .x = 64,
        .y = 1024 / 4,
    };
    rl.drawTextEx(font_loader.get(.kenney_future).*, "Game Over!", position, 64, 0, .white);
    position.y = 1024 / 3;
    rl.drawTextEx(font_loader.get(.kenney_future).*, score_text, position, 64, 0, .white);
    position.y = 1024 / 2;
    rl.drawTextEx(font_loader.get(.kenney_future).*, "Press Space to Play Again", position, 64, 0, .white);
    if (rl.isKeyPressed(.space)) {
        map.reset();
        player.reset();
        state.* = .game;
    }
}

fn game_state(font_loader: *FontLoader, player: *Player, map: *Map, state: *State) void {
    const delta = rl.getFrameTime();
    game_state_process(player, map, delta);
    game_state_draw(font_loader, player, map);
    if (map.is_game_over()) {
        rl.playSound(map.game_over_sound);
        game_over_score = player.score;
        state.* = .game_over;
    }
}

fn game_state_process(player: *Player, map: *Map, delta: f32) void {
    map.process(player, delta);
    player.process(map, delta);
}

fn game_state_draw(font_loader: *FontLoader, player: *Player, map: *Map) void {
    rl.beginDrawing();
    defer rl.endDrawing();

    rl.beginMode2D(camera);
    rl.clearBackground(.black);
    draw_player_map(player);
    map.draw();
    player.draw();

    const r = 320;
    rl.drawCircle((1024 * 2) - r - 64, (1024 * 2) - r - 64, r, .white);
    rl.endMode2D();

    var buffer: [32]u8 = undefined;

    var result = std.fmt.bufPrintZ(&buffer, "{d}", .{player.score}) catch unreachable;
    rl.drawText(result, 32, 32, 64, .white);

    var position: rl.Vector2 = .{
        .x = 1024 - (32 * 9),
        .y = 1024 - (32 * 8),
    };
    result = std.fmt.bufPrintZ(&buffer, "Laz x{d}", .{player.power_laser}) catch unreachable;
    rl.drawTextEx(font_loader.get(.kenney_future).*, result, position, 32, 0, .black);
    position.y = 1024 - (32 * 7);
    result = std.fmt.bufPrintZ(&buffer, "Large Laz x{d}", .{player.power_large_laser}) catch unreachable;
    rl.drawTextEx(font_loader.get(.kenney_future).*, result, position, 32, 0, .black);
    position.y = 1024 - (32 * 6);
    result = std.fmt.bufPrintZ(&buffer, "Giant Laz x{d}", .{player.power_giant_laser}) catch unreachable;
    rl.drawTextEx(font_loader.get(.kenney_future).*, result, position, 32, 0, .black);
}

fn draw_player_map(player: *Player) void {
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
            var color: rl.Color = undefined;
            switch (player.gem_color) {
                .red => color = .red,
                .green => color = .green,
                .blue => color = .blue,
            }
            rl.drawCircle(x + 32, y + 32, tile_size * 0.1, color);
        }
    }
}
