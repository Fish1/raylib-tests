const std = @import("std");
const rl = @import("raylib");

const TextureLoader = @import("texture_loader.zig").TextureLoader;
const FontLoader = @import("font_loader.zig").FontLoader;

pub const UIDrawer = struct {
    texture_loader: *TextureLoader,
    font_loader: *FontLoader,

    buffer: *[512]u8 = undefined,

    pub fn init(text_buffer: *[512]u8, texture_loader: *TextureLoader, font_loader: *FontLoader) @This() {
        return .{
            .texture_loader = texture_loader,
            .font_loader = font_loader,
            .buffer = text_buffer,
        };
    }

    pub fn draw_main_menu_box(self: @This(), x: f32, y: f32) void {
        self.draw_box(x, y, 475, 475);
        self.draw_text("Zoop!", .{}, x + 32, y + 32, 64, .black) catch unreachable;
        self.draw_text("Press Space to Play!", .{}, x + 32, y + 32 * 4, 32, .black) catch unreachable;
    }

    pub fn draw_game_powerups(self: @This(), x: f32, y: f32, power_laser: i32, power_large_laser: i32) void {
        self.draw_box(x, y, 332, 332);
        self.draw_text("Laz - {d}/3", .{power_laser}, x + 16, y + 32, 32, .black) catch unreachable;
        self.draw_text("Large Laz - {d}/3", .{power_large_laser}, x + 16, y + 64, 32, .black) catch unreachable;
    }

    pub fn draw_game_score(self: @This(), x: f32, y: f32, score: i32) void {
        self.draw_text("{d}", .{score}, x, y, 64, .white) catch unreachable;
    }

    pub fn draw_game_levelup(self: @This(), x: f32, y: f32, level: i32, current_score: i32, needed_score: i32) void {
        self.draw_text("Level {d}\n{d}\nof\n{d}", .{ level, current_score, needed_score }, x, y, 42, .white) catch unreachable;
    }

    fn draw_text(self: @This(), comptime format: []const u8, args: anytype, x: f32, y: f32, size: f32, color: rl.Color) !void {
        const text = try std.fmt.bufPrintZ(self.buffer, format, args);
        const font = self.font_loader.get(.kenney_future_narrow);
        const position: rl.Vector2 = .init(x, y);
        const origin: rl.Vector2 = .zero();
        const rotation: f32 = 0.0;
        const fontSize: f32 = size;
        const spacing: f32 = 0.0;
        rl.drawTextPro(font.*, text, position, origin, rotation, fontSize, spacing, color);
    }

    fn draw_box(self: @This(), x: f32, y: f32, width: f32, height: f32) void {
        const box = self.texture_loader.get(.ui_button_square_gradient);
        const texture_width: f32 = @floatFromInt(box.width);
        const texture_height: f32 = @floatFromInt(box.height);
        const source: rl.Rectangle = .init(0, 0, texture_width, texture_height);
        const destination: rl.Rectangle = .init(x, y, width, height);
        const origin: rl.Vector2 = .zero();
        const rotation: f32 = 0.0;
        rl.drawTexturePro(box.*, source, destination, origin, rotation, .white);
    }
};
