const std = @import("std");
const rl = @import("raylib");
const ease = @import("ease.zig");

const Player = @import("player.zig").Player;
const Map = @import("map.zig").Map;
const Spawner = @import("spawner.zig").Spawner;
const Scorer = @import("scorer.zig").Scorer;

const TextureID = @import("texture_loader.zig").TextureID;
const TextureLoader = @import("texture_loader.zig").TextureLoader;
const FontLoader = @import("font_loader.zig").FontLoader;
const SoundLoader = @import("audio.zig").SoundLoader;
const MusicLoader = @import("audio.zig").MusicLoader;

const SoundQueue = @import("audio.zig").SoundQueue;

const UIDrawer = @import("ui_drawer.zig").UIDrawer;

const Difficulty = @import("types.zig").Difficulty;

const window_width = @import("global.zig").WINDOW_WIDTH;
const window_height = @import("global.zig").WINDOW_HEIGHT;
const tile_size = @import("global.zig").TILE_WIDTH;

const State = enum {
    main_menu,
    game,
    game_over,
};

const GameOverType = enum {
    win,
    lose,
};

var game_over_type: GameOverType = undefined;

var noise_state_previous: TextureID = .noise11;
var noise_state: TextureID = .noise08;
var noise_time: f32 = 0.0;
var noise_speed: f32 = 8.0;

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

    var ui_sound_queue = SoundQueue{};

    var buffer: [512]u8 = undefined;
    const ui_drawer = UIDrawer.init(&buffer, &texture_loader, &font_loader);

    music_loader.play(.full_song, 0.0, 1.0);

    var scorer: Scorer = Scorer.init();
    var map: Map = try Map.init(&texture_loader, &sound_loader, &music_loader, &scorer);
    var player: Player = try Player.init(&texture_loader, &sound_loader, &scorer);
    var spawner: Spawner = Spawner.init(&map, &player, &difficulty, &scorer);

    while (rl.windowShouldClose() == false) {
        music_loader.process(rl.getFrameTime());
        switch (state) {
            .main_menu => main_menu_state(ui_drawer, &ui_sound_queue, &sound_loader, &state, &map, &difficulty),
            .game => game_state(ui_drawer, &sound_loader, &music_loader, &texture_loader, &font_loader, &player, &map, &spawner, &state, &scorer),
            .game_over => game_over_state(&font_loader, &player, &map, &state, &scorer),
        }
    }
}

fn main_menu_state(ui_drawer: UIDrawer, ui_sound_queue: *SoundQueue, sound_loader: *SoundLoader, state: *State, map: *Map, difficulty: *Difficulty) void {
    if (rl.isKeyPressed(.space)) {
        state.* = .game;
    }

    rl.beginDrawing();
    defer rl.endDrawing();
    ui_drawer.draw_main_menu_title((window_width / 2) - (475 / 2), (window_height / 2) - (475 / 2));
    ui_drawer.draw_main_menu_difficulty_select((window_width / 2) - (475 / 2), 530, difficulty.*);

    if (rl.isKeyPressed(.left)) {
        ui_sound_queue.clear();
        ui_sound_queue.add(sound_loader.get(.ui_switch_a)) catch unreachable;
        ui_sound_queue.add(sound_loader.get(.ui_switch_b)) catch unreachable;
        difficulty.* = switch (difficulty.*) {
            .easy => .easy,
            .medium => .easy,
            .hard => .medium,
        };
        map.set_difficulty(difficulty.*);
    } else if (rl.isKeyPressed(.right)) {
        ui_sound_queue.clear();
        ui_sound_queue.add(sound_loader.get(.ui_switch_a)) catch unreachable;
        ui_sound_queue.add(sound_loader.get(.ui_switch_b)) catch unreachable;
        difficulty.* = switch (difficulty.*) {
            .easy => .medium,
            .medium => .hard,
            .hard => .hard,
        };
        map.set_difficulty(difficulty.*);
    }

    ui_sound_queue.process();
}

fn game_over_state(font_loader: *FontLoader, player: *Player, map: *Map, state: *State, scorer: *Scorer) void {
    rl.beginDrawing();
    defer rl.endDrawing();

    var buffer: [32]u8 = undefined;
    const score_text = std.fmt.bufPrintZ(&buffer, "You scored {d}!", .{scorer.score}) catch unreachable;

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
        scorer.reset();
        state.* = .game;
    }
}

fn game_state(ui_drawer: UIDrawer, sound_loader: *SoundLoader, music_loader: *MusicLoader, texture_loader: *TextureLoader, font_loader: *FontLoader, player: *Player, map: *Map, spawner: *Spawner, state: *State, scorer: *Scorer) void {
    const delta = rl.getFrameTime();
    game_state_process(player, map, spawner, delta);
    game_state_draw(ui_drawer, font_loader, texture_loader, player, map, scorer);
    if (map.is_game_over()) {
        sound_loader.play(.game_over);
        sound_loader.play(.say_you_lose);
        music_loader.play(.game_over, 3.0, 15.0);
        game_over_type = .lose;
        state.* = .game_over;
    } else if (player.goals == 3) {
        sound_loader.play(.say_objective_achieved);
        music_loader.play(.game_over, 3.0, 15.0);
        game_over_type = .win;
        state.* = .game_over;
    }
}

fn game_state_process(player: *Player, map: *Map, spawner: *Spawner, delta: f32) void {
    spawner.process(delta);
    map.process(delta);
    player.process(map, delta);
    noise_time = noise_time + delta;
    if (noise_time >= noise_speed) {
        noise_time = 0.0;
        noise_state_previous = noise_state;
        noise_state = switch (noise_state) {
            .noise08 => .noise09,
            .noise09 => .noise10,
            .noise10 => .noise11,
            .noise11 => .noise08,
            else => .noise08,
        };
    }
}

fn game_state_draw(ui_drawer: UIDrawer, _: *FontLoader, texture_loader: *TextureLoader, player: *Player, map: *Map, scorer: *Scorer) void {
    rl.beginDrawing();
    defer rl.endDrawing();

    rl.beginMode2D(camera);
    rl.clearBackground(.black);
    draw_player_map(player, texture_loader);
    map.draw();
    player.draw();
    rl.endMode2D();

    ui_drawer.draw_game_goals(64 * 10, 32, player.goals);
    ui_drawer.draw_game_levelup(32, 32, map.level, scorer.score, scorer.get_score_to_levelup());
    ui_drawer.draw_game_powerups(64 * 10, 64 * 5, player.power_laser, player.power_large_laser);
    ui_drawer.draw_game_extra_score(32, 64 * 5, scorer.get_score_multiplier(), scorer.get_score_bonus(), scorer.get_score_per_gem());
}

fn draw_player_map(player: *Player, texture_loader: *TextureLoader) void {
    var color: rl.Color = switch (player.gem_color) {
        .red => .red,
        .green => .green,
        .blue => .blue,
    };

    const texture = texture_loader.get(.planet);
    const source: rl.Rectangle = .{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(texture.width),
        .height = @floatFromInt(texture.height),
    };
    const destination: rl.Rectangle = .{
        .x = window_height - (@as(f32, @floatFromInt(texture.width)) / 4.0),
        .y = window_width - (@as(f32, @floatFromInt(texture.height)) / 4.0),
        .width = @as(f32, @floatFromInt(texture.width)) / 2.0,
        .height = @as(f32, @floatFromInt(texture.height)) / 2.0,
    };
    texture_loader.get(.planet).drawPro(source, destination, .zero(), 0.0, .gray);

    const noise = texture_loader.get(noise_state);
    const noise_source: rl.Rectangle = .{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(noise.width),
        .height = @floatFromInt(noise.height),
    };
    const noise_destination: rl.Rectangle = .{
        .x = window_height - (@as(f32, @floatFromInt(noise.width)) / 4.0),
        .y = window_width - (@as(f32, @floatFromInt(noise.height)) / 4.0),
        .width = @as(f32, @floatFromInt(noise.width)) / 2.0,
        .height = @as(f32, @floatFromInt(noise.height)) / 2.0,
    };
    var noise_color: rl.Color = .gray;
    noise_color.a = @intFromFloat(255.0 * (noise_time / noise_speed));
    noise.drawPro(noise_source, noise_destination, .zero(), 0.0, noise_color);

    const noise_previous = texture_loader.get(noise_state_previous);
    const noise_previous_source: rl.Rectangle = .{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(noise.width),
        .height = @floatFromInt(noise.height),
    };
    const noise_previous_destination: rl.Rectangle = .{
        .x = window_height - (@as(f32, @floatFromInt(noise_previous.width)) / 4.0),
        .y = window_width - (@as(f32, @floatFromInt(noise_previous.height)) / 4.0),
        .width = @as(f32, @floatFromInt(noise_previous.width)) / 2.0,
        .height = @as(f32, @floatFromInt(noise_previous.height)) / 2.0,
    };
    noise_color.a = @intFromFloat(255.0 * (1.0 - (noise_time / noise_speed)));
    noise_previous.drawPro(noise_previous_source, noise_previous_destination, .zero(), 0.0, noise_color);

    for (0..16) |square| {
        const width = 4;
        const tx: i32 = @intCast(@mod(square, width));
        const ty: i32 = @intCast(@divFloor(square, width));
        const x: i32 = @intCast(tx * tile_size + tile_size * 14);
        const y: i32 = @intCast(ty * tile_size + tile_size * 14);
        // rl.drawRectangle(x, y, tile_size, tile_size, .gray);
        rl.drawCircle(x + 32, y + 32, tile_size * 0.1, .white);
    }

    for (0..14 * 4) |dot| {
        const _width = 14;
        const tx: i32 = @intCast(@mod(dot, _width));
        const ty: i32 = @intCast(@divFloor(dot, _width));
        const x: i32 = @intCast(tx * tile_size);
        const y: i32 = @intCast((ty * tile_size) + (tile_size * 14));

        const alpha = (@as(f32, @floatFromInt(tx)) / 13.0) * 255.0;
        color.a = @intFromFloat(@min(alpha, 255.0));

        rl.drawCircle(x + 32, y + 32, tile_size * 0.1, color);
    }

    for (0..14 * 4) |dot| {
        const _width = 4;
        const tx: i32 = @intCast(@mod(dot, _width));
        const ty: i32 = @intCast(@divFloor(dot, _width));
        const x: i32 = @intCast(tx * tile_size + tile_size * 14);
        const y: i32 = @intCast(ty * tile_size);

        const alpha = (@as(f32, @floatFromInt(ty)) / 13.0) * 255.0;
        color.a = @intFromFloat(@min(alpha, 255.0));

        rl.drawCircle(x + 32, y + 32, tile_size * 0.1, color);
    }

    for (0..14 * 4) |dot| {
        const _width = 14;
        const tx: i32 = @intCast(@mod(dot, _width));
        const ty: i32 = @intCast(@divFloor(dot, _width));
        const x: i32 = @intCast(tx * tile_size + tile_size * 18);
        const y: i32 = @intCast(ty * tile_size + tile_size * 14);

        const alpha = (@as(f32, @floatFromInt(13 - tx)) / 13.0) * 255.0;
        color.a = @intFromFloat(@min(alpha, 255.0));

        rl.drawCircle(x + 32, y + 32, tile_size * 0.1, color);
    }

    for (0..14 * 4) |dot| {
        const _width = 4;
        const tx: i32 = @intCast(@mod(dot, _width));
        const ty: i32 = @intCast(@divFloor(dot, _width));
        const x: i32 = @intCast(tx * tile_size + tile_size * 14);
        const y: i32 = @intCast(ty * tile_size + tile_size * 18);

        const alpha = (@as(f32, @floatFromInt(13 - ty)) / 13.0) * 255.0;
        color.a = @intFromFloat(@min(alpha, 255.0));

        rl.drawCircle(x + 32, y + 32, tile_size * 0.1, color);
    }
}
