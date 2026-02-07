const rl = @import("raylib");

const Map = @import("map.zig").Map;
const Player = @import("player.zig").Player;

const GemPower = @import("types.zig").GemPower;
const Difficulty = @import("types.zig").Difficulty;
const Direction = @import("types.zig").Direction;

const Scorer = @import("scorer.zig").Scorer;

pub const Spawner = struct {
    spawn_time: f32 = 0.0,
    time: f32 = 0.0,

    map: *Map,
    player: *Player,
    difficulty: *Difficulty,

    scorer: *Scorer,

    pub fn init(map: *Map, player: *Player, difficulty: *Difficulty, scorer: *Scorer) @This() {
        return .{
            .map = map,
            .player = player,
            .difficulty = difficulty,
            .scorer = scorer,
        };
    }

    pub fn process(self: *@This(), delta: f32) void {
        self.time = self.time + delta;
        if (self.time >= self.get_spawn_time() and self.player.state == .player_control) {
            self.time = 0.0;

            const wall: Direction = @enumFromInt(rl.getRandomValue(0, 3));
            const part: i32 = rl.getRandomValue(0, 3);
            self.spawn(wall, part);
        }
    }

    pub fn get_spawn_time(self: @This()) f32 {
        const level = self.scorer.get_current_level();
        return switch (self.difficulty.*) {
            .easy => (-1.0 / 12.0) * @as(f32, @floatFromInt(level)) + 1.25,
            .medium => (-1.0 / 10.0) * @as(f32, @floatFromInt(level)) + 1.25,
            .hard => (-1.0 / 9.0) * @as(f32, @floatFromInt(level)) + 1.25,
        };
    }

    pub fn spawn(self: *@This(), wall: Direction, part: i32) void {
        if (part < 0 or part >= 4) {
            return;
        }

        if (wall == .left) {
            const y = 14 + part;
            for (&self.map.enemies) |*_check_enemy| {
                if (_check_enemy.*) |*check_enemy| {
                    if (check_enemy.y != y or check_enemy.x > 14) {
                        continue;
                    }
                    check_enemy.move(.right);
                }
            }
            self.spawn_at_location(0, y, -1, y);
        } else if (wall == .up) {
            const x = 14 + part;
            for (&self.map.enemies) |*_check_enemy| {
                if (_check_enemy.*) |*check_enemy| {
                    if (check_enemy.x != x or check_enemy.y > 14) {
                        continue;
                    }
                    check_enemy.move(.down);
                }
            }
            self.spawn_at_location(x, 0, x, -1);
        } else if (wall == .right) {
            const y = 14 + part;
            for (&self.map.enemies) |*_check_enemy| {
                if (_check_enemy.*) |*check_enemy| {
                    if (check_enemy.y != y or check_enemy.x < 14) {
                        continue;
                    }
                    check_enemy.move(.left);
                }
            }
            self.spawn_at_location(31, y, 32, y);
        } else if (wall == .down) {
            const x = 14 + part;
            for (&self.map.enemies) |*_check_enemy| {
                if (_check_enemy.*) |*check_enemy| {
                    if (check_enemy.x != x or check_enemy.y < 14) {
                        continue;
                    }
                    check_enemy.move(.up);
                }
            }
            self.spawn_at_location(x, 31, x, 32);
        }
    }

    fn spawn_at_location(self: *@This(), x: i32, y: i32, px: i32, py: i32) void {
        var new_enemy = self.map.enemy_prototype.copy_to(x, y, px, py);
        const gem_type = rl.getRandomValue(0, 99);
        if (gem_type >= 0 and gem_type <= 4 and self.scorer.get_current_level() == 10) {
            new_enemy.set_goal(true);
        } else if (gem_type >= 89 and gem_type <= 99) {
            var power: ?GemPower = null;
            if (self.scorer.get_current_level() <= 8) {
                power = .laser;
            } else {
                power = .large_laser;
            }
            new_enemy.set_power(power);
        }
        new_enemy.update_texture();
        self.map.add_enemy(new_enemy);
    }
};
