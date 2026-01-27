const std = @import("std");
const rl = @import("raylib");
const ease = @import("ease.zig");
const Player = @import("player.zig").Player;
const Map = @import("map.zig").Map;

const TextureLoader = @import("texture_loader.zig").TextureLoader;
const FontLoader = @import("font_loader.zig").FontLoader;
const SoundLoader = @import("audio.zig").SoundLoader;
const MusicLoader = @import("audio.zig").MusicLoader;

const UIDrawer = @import("ui_drawer.zig").UIDrawer;

const Difficulty = @import("types.zig").Difficulty;

const window_width = 1024;
const window_height = 1024;
const tile_size = 64;

const State = enum {
    main_menu,
    game,
    game_over,
};

var game_over_score: i32 = undefined;

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
    var state: State = .main_menu;
    var difficulty: Difficulty = .medium;

    rl.initWindow(window_width, window_height, "Zoop!");
    defer rl.closeWindow();
    rl.initAudioDevice();
    rl.setTargetFPS(60);

    var texture_loader = try TextureLoader.init();
    defer texture_loader.deinit();

    var font_loader = try FontLoader.init();
    defer font_loader.deinit();

    var sound_loader = try SoundLoader.init();
    defer sound_loader.deinit();

    var music_loader = try MusicLoader.init();
    defer music_loader.deinit();

    var buffer: [512]u8 = undefined;
    const ui_drawer = UIDrawer.init(&buffer, &texture_loader, &font_loader);

    music_loader.play(.example);

    var map: Map = try Map.init(&texture_loader, &sound_loader);
    var player: Player = try Player.init(&texture_loader, &sound_loader);

    while (rl.windowShouldClose() == false) {
        music_loader.update();
        switch (state) {
            .main_menu => main_menu_state(ui_drawer, &state, &map, &difficulty),
            .game => game_state(ui_drawer, &sound_loader, &font_loader, &player, &map, &state),
            .game_over => game_over_state(&font_loader, &player, &map, &state),
        }
    }
}

fn main_menu_state(ui_drawer: UIDrawer, state: *State, map: *Map, difficulty: *Difficulty) void {
    if (rl.isKeyPressed(.space)) {
        state.* = .game;
    }

    rl.beginDrawing();
    defer rl.endDrawing();
    ui_drawer.draw_main_menu_title((window_width / 2) - (475 / 2), (window_height / 2) - (475 / 2));
    ui_drawer.draw_main_menu_difficulty_select(32, 32, difficulty.*);

    if (rl.isKeyPressed(.left)) {
        difficulty.* = switch (difficulty.*) {
            .easy => .easy,
            .medium => .easy,
            .hard => .medium,
        };
        map.set_difficulty(difficulty.*);
    } else if (rl.isKeyPressed(.right)) {
        difficulty.* = switch (difficulty.*) {
            .easy => .medium,
            .medium => .hard,
            .hard => .hard,
        };
        map.set_difficulty(difficulty.*);
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

fn game_state(ui_drawer: UIDrawer, sound_loader: *SoundLoader, font_loader: *FontLoader, player: *Player, map: *Map, state: *State) void {
    const delta = rl.getFrameTime();
    game_state_process(player, map, delta);
    game_state_draw(ui_drawer, font_loader, player, map);
    if (map.is_game_over()) {
        sound_loader.play(.game_over);
        sound_loader.play(.say_you_lose);
        game_over_score = player.score;
        state.* = .game_over;
    }
}

fn game_state_process(player: *Player, map: *Map, delta: f32) void {
    map.process(player, delta);
    player.process(map, delta);
}

fn game_state_draw(ui_drawer: UIDrawer, _: *FontLoader, player: *Player, map: *Map) void {
    rl.beginDrawing();
    defer rl.endDrawing();

    rl.beginMode2D(camera);
    rl.clearBackground(.black);
    draw_player_map(player);
    map.draw();
    player.draw();
    rl.endMode2D();

    ui_drawer.draw_game_levelup(32, 32, map.level, player.score, map.get_score_to_levelup(player));
    ui_drawer.draw_game_powerups(64 * 10, 64 * 5, player.power_laser, player.power_large_laser);
}

fn draw_player_map(player: *Player) void {
    const color: rl.Color = switch (player.gem_color) {
        .red => .red,
        .green => .green,
        .blue => .blue,
    };

    for (0..16) |square| {
        const width = 4;
        const tx: i32 = @intCast(@mod(square, width));
        const ty: i32 = @intCast(@divFloor(square, width));
        const x: i32 = @intCast(tx * tile_size + tile_size * 14);
        const y: i32 = @intCast(ty * tile_size + tile_size * 14);
        rl.drawRectangle(x, y, tile_size, tile_size, .gray);
        rl.drawCircle(x + 32, y + 32, tile_size * 0.1, .black);
    }

    for (0..14 * 4) |dot| {
        const _width = 14;
        const tx: i32 = @intCast(@mod(dot, _width));
        const ty: i32 = @intCast(@divFloor(dot, _width));
        const x: i32 = @intCast(tx * tile_size);
        const y: i32 = @intCast((ty * tile_size) + (tile_size * 14));
        rl.drawCircle(x + 32, y + 32, tile_size * 0.1, color);
    }

    for (0..14 * 4) |dot| {
        const _width = 4;
        const tx: i32 = @intCast(@mod(dot, _width));
        const ty: i32 = @intCast(@divFloor(dot, _width));
        const x: i32 = @intCast(tx * tile_size + tile_size * 14);
        const y: i32 = @intCast(ty * tile_size);
        rl.drawCircle(x + 32, y + 32, tile_size * 0.1, color);
    }

    for (0..14 * 4) |dot| {
        const _width = 14;
        const tx: i32 = @intCast(@mod(dot, _width));
        const ty: i32 = @intCast(@divFloor(dot, _width));
        const x: i32 = @intCast(tx * tile_size + tile_size * 18);
        const y: i32 = @intCast(ty * tile_size + tile_size * 14);
        rl.drawCircle(x + 32, y + 32, tile_size * 0.1, color);
    }

    for (0..14 * 4) |dot| {
        const _width = 4;
        const tx: i32 = @intCast(@mod(dot, _width));
        const ty: i32 = @intCast(@divFloor(dot, _width));
        const x: i32 = @intCast(tx * tile_size + tile_size * 14);
        const y: i32 = @intCast(ty * tile_size + tile_size * 18);
        rl.drawCircle(x + 32, y + 32, tile_size * 0.1, color);
    }
}
