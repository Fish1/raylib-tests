const Enemy = @import("enemy.zig").Enemy;

pub const RedEnemy = Enemy.init(0, 0, 0, .red);
pub const GreenEnemy = Enemy.init(0, 0, 1, .green);
pub const BlueEnemy = Enemy.init(0, 0, 2, .blue);
