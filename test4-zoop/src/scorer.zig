const std = @import("std");

pub const Scorer = struct {
    score: i32 = 0,
    pickup_speed_multiplier: i32 = 1,
    pickup_speed_multiplier_timer: f32 = 0.0,
    pickup_speed_multiplier_timer_reset: f32 = 1.0,

    pub fn init() @This() {
        return .{};
    }

    pub fn reset(self: *@This()) void {
        self.score = 0;
        self.pickup_speed_multiplier = 1;
        self.pickup_speed_multiplier_timer = 0.0;
        self.pickup_speed_multiplier_timer_reset = 1.0;
    }

    pub fn get_current_level(self: @This()) i32 {
        return switch (self.score) {
            0...99 => 1,
            100...299 => 2,
            300...599 => 3,
            600...1399 => 4,
            1400...2999 => 5,
            3000...6199 => 6,
            6200...12599 => 7,
            12600...25399 => 8,
            25400...50999 => 9,
            else => 10,
        };
    }

    pub fn get_score_to_levelup(self: @This()) i32 {
        return switch (self.get_current_level()) {
            1 => 100,
            2 => 300,
            3 => 600,
            4 => 1400,
            5 => 3000,
            6 => 6200,
            7 => 12600,
            8 => 25400,
            9 => 51000,
            else => 100000,
        };
    }

    pub fn increase_pickup_speed_multiplier(self: *@This()) void {
        self.pickup_speed_multiplier_timer = self.pickup_speed_multiplier_timer_reset;
        self.pickup_speed_multiplier = @min(self.pickup_speed_multiplier + 1, 5);
    }

    pub fn process_pickup_speed_muliplier_timer(self: *@This(), delta: f32) void {
        self.pickup_speed_multiplier_timer = @max(self.pickup_speed_multiplier_timer - delta, 0.0);
        if (self.pickup_speed_multiplier_timer <= 0) {
            self.pickup_speed_multiplier = @max(self.pickup_speed_multiplier - 1, 1);
            self.pickup_speed_multiplier_timer = self.pickup_speed_multiplier_timer_reset;
        }
    }

    pub fn get_score_bonus(self: @This()) i32 {
        return @divFloor(self.score, 1000);
    }

    pub fn get_score_multiplier(self: @This()) i32 {
        return self.pickup_speed_multiplier;
    }

    pub fn get_score_per_gem(self: @This()) i32 {
        return std.math.pow(i32, self.get_current_level(), 2);
    }

    pub fn calculate_score(self: @This(), gems: i32) i32 {
        return (gems * self.get_score_per_gem() * self.get_score_multiplier()) + self.get_score_bonus();
    }

    pub fn add_gem_score(self: *@This(), gems: i32) void {
        self.score = self.score + self.calculate_score(gems);
    }
};
