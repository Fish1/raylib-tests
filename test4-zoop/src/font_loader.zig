const rl = @import("raylib");

pub const FontID = enum(usize) {
    kenney_future,
};

pub const FontLoader = struct {
    fonts: [1]rl.Font,

    pub fn init() !@This() {
        return .{
            .fonts = .{
                try rl.loadFont("./assets/fonts/kenney_future.ttf"),
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
