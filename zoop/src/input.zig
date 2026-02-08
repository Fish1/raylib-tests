const std = @import("std");
const rl = @import("raylib");

pub const Action = enum(usize) {
    move_left,
    move_right,
    move_up,
    move_down,

    attack_left,
    attack_right,
    attack_up,
    attack_down,

    start_game,

    ui_left,
    ui_right,
    ui_up,
    ui_down,
};

pub const Input = struct {
    keys: [13]rl.KeyboardKey,

    buttons: [13]rl.GamepadButton,

    pub fn init() @This() {
        return .{
            .keys = .{
                .left,
                .right,
                .up,
                .down,
                .a,
                .d,
                .w,
                .s,
                .space,

                .left,
                .right,
                .up,
                .down,
            },
            .buttons = .{
                .right_face_up,
                .right_face_up,
                .right_face_up,
                .right_face_up,

                .right_face_up,
                .right_face_up,
                .right_face_up,
                .right_face_up,

                .right_trigger_1,

                .right_face_up,
                .right_face_up,
                .right_face_up,
                .right_face_up,
            },
        };
    }

    fn action_to_key(self: @This(), action: Action) rl.KeyboardKey {
        return self.keys[@intFromEnum(action)];
    }

    fn action_to_button(self: @This(), action: Action) rl.GamepadButton {
        return self.buttons[@intFromEnum(action)];
    }

    pub fn is_action_pressed(self: @This(), action: Action) bool {
        if (rl.isGamepadAvailable(0)) {
            const name = rl.getGamepadName(0);
            const button = rl.getGamepadButtonPressed();
            std.log.info("gp name = {s}", .{name});
            std.log.info("button = {any}", .{button});
            if (rl.isGamepadButtonPressed(0, .unknown)) {
                std.log.info("unknown", .{});
            }
            if (rl.isGamepadButtonPressed(0, .right_face_up)) {
                std.log.info("unknown", .{});
            }
            return rl.isGamepadButtonPressed(0, self.action_to_button(action));
        } else {
            return rl.isKeyPressed(self.action_to_key(action));
        }
    }
};
