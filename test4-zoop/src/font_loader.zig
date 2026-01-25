const rl = @import("raylib");

pub const FontID = enum(usize) {
    kenney_future,
    kenney_future_narrow,
};

pub const FontLoader = struct {
    fonts: [2]rl.Font,

    pub fn init() !@This() {
        return .{
            .fonts = .{
                try rl.loadFont("./assets/fonts/kenney_future.ttf"),
                try rl.loadFont("./assets/fonts/kenney_future_narrow.ttf"),
            },
        };
    }

    pub fn deinit(self: *@This()) void {
        for (self.fonts) |font| {
            font.unload();
        }
    }

    pub fn get(self: *@This(), font_id: FontID) *rl.Font {
        return &self.fonts[@intFromEnum(font_id)];
    }
};
