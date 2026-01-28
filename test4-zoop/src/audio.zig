const std = @import("std");
const rl = @import("raylib");

pub const SoundID = enum(usize) {
    game_over,
    score,
    swap,
    jump,
    powerup,
    laser,

    say_you_lose,
    say_power_up,
    say_hurry_up,
    say_level,
    say_one,
    say_two,
    say_three,
    say_four,
    say_five,
    say_six,
    say_seven,
    say_eight,
    say_nine,
    say_ten,

    ui_switch_a,
    ui_switch_b,
};

pub const SoundLoader = struct {
    sounds: [22]rl.Sound,

    pub fn init() !@This() {
        return .{
            .sounds = .{
                try rl.loadSound("./assets/sounds/effects/gameover.wav"),
                try rl.loadSound("./assets/sounds/effects/score.wav"),
                try rl.loadSound("./assets/sounds/effects/swap.wav"),
                try rl.loadSound("./assets/sounds/effects/jump.wav"),
                try rl.loadSound("./assets/sounds/effects/powerup.wav"),
                try rl.loadSound("./assets/sounds/effects/laser.wav"),

                try rl.loadSound("./assets/sounds/voice/you_lose.ogg"),
                try rl.loadSound("./assets/sounds/voice/power_up.ogg"),
                try rl.loadSound("./assets/sounds/voice/hurry_up.ogg"),
                try rl.loadSound("./assets/sounds/voice/level.ogg"),
                try rl.loadSound("./assets/sounds/voice/1.ogg"),
                try rl.loadSound("./assets/sounds/voice/2.ogg"),
                try rl.loadSound("./assets/sounds/voice/3.ogg"),
                try rl.loadSound("./assets/sounds/voice/4.ogg"),
                try rl.loadSound("./assets/sounds/voice/5.ogg"),
                try rl.loadSound("./assets/sounds/voice/6.ogg"),
                try rl.loadSound("./assets/sounds/voice/7.ogg"),
                try rl.loadSound("./assets/sounds/voice/8.ogg"),
                try rl.loadSound("./assets/sounds/voice/9.ogg"),
                try rl.loadSound("./assets/sounds/voice/10.ogg"),

                try rl.loadSound("./assets/sounds/ui/switch-a.ogg"),
                try rl.loadSound("./assets/sounds/ui/switch-b.ogg"),
            },
        };
    }

    pub fn deinit(self: *@This()) void {
        for (self.sounds) |sound| {
            sound.unload();
        }
    }

    pub fn play(self: *@This(), sound_id: SoundID) void {
        const sound = self.get(sound_id);
        rl.playSound(sound.*);
    }

    pub fn is_playing(self: *@This(), sound_id: SoundID) bool {
        const sound = self.get(sound_id);
        return rl.isSoundPlaying(sound.*);
    }

    pub fn get(self: *@This(), sound_id: SoundID) *rl.Sound {
        return &self.sounds[@intFromEnum(sound_id)];
    }
};

pub const SoundQueue = struct {
    queue: [10]?*rl.Sound = std.mem.zeroes([10]?*rl.Sound),
    current: usize = 0,
    end: usize = 0,

    pub fn add(self: *@This(), sound: *rl.Sound) bool {
        if (self.is_full()) {
            return false;
        }

        self.queue[self.end] = sound;
        if (self.current == self.end) {
            const _current_sound = self.queue[self.current];
            if (_current_sound) |current_sound| {
                rl.playSound(current_sound.*);
            }
        }
        self.increment_end();
        return true;
    }

    pub fn process(self: *@This()) void {
        if (self.current == self.end) {
            return;
        }

        const current_sound = self.queue[self.current] orelse return;
        if (rl.isSoundPlaying(current_sound.*) == false) {
            self.increment_current();
            if (self.current != self.end) {
                const new_sound = self.queue[self.current] orelse return;
                rl.playSound(new_sound.*);
            }
        }
    }

    pub fn clear(self: *@This()) void {
        const current_sound = self.queue[self.current] orelse return;
        rl.stopSound(current_sound.*);
        self.queue = std.mem.zeroes([10]?*rl.Sound);
        self.current = 0;
        self.end = 0;
    }

    fn is_full(self: @This()) bool {
        return (self.current > 0 and self.end == self.current - 1) or
            (self.current == 0 and self.end == 9);
    }

    fn increment_current(self: *@This()) void {
        self.current = @mod(self.current + 1, 10);
    }

    fn increment_end(self: *@This()) void {
        self.end = @mod(self.end + 1, 10);
    }
};

pub const MusicID = enum(usize) {
    example,
};

pub const MusicLoader = struct {
    music: [1]rl.Music,

    pub fn init() !@This() {
        return .{
            .music = .{try rl.loadMusicStream("./assets/sounds/music/song.wav")},
        };
    }

    pub fn deinit(self: *@This()) void {
        for (self.music) |music| {
            music.unload();
        }
    }

    pub fn play(self: *@This(), music_id: MusicID) void {
        const music = self.get(music_id);
        rl.playMusicStream(music.*);
    }

    pub fn stop(self: *@This(), music_id: MusicID) void {
        const music = self.get(music_id);
        rl.stopMusicStream(music.*);
    }

    pub fn update(self: *@This()) void {
        for (&self.music) |*music| {
            if (rl.isMusicStreamPlaying(music.*) == true) {
                rl.updateMusicStream(music.*);
            }
        }
    }

    fn get(self: *@This(), music_id: MusicID) *rl.Music {
        return &self.music[@intFromEnum(music_id)];
    }
};
