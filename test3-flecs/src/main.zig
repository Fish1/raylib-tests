const std = @import("std");
const ecs = @import("zflecs");

const Position = struct { x: f32, y: f32 };
const Apples = struct {};

fn move_system(positions: []Position) void {
    for (positions) |*p| {
        p.x += 0.25;
        p.y += 0.25;
    }
}

pub fn main() void {
    const world = ecs.init();
    defer _ = ecs.fini(world);

    ecs.COMPONENT(world, Position);

    ecs.TAG(world, Apples);

    _ = ecs.ADD_SYSTEM(world, "move system", ecs.OnUpdate, move_system);

    const bob = ecs.new_entity(world, "bob");
    _ = ecs.set(world, bob, Position, .{ .x = 0, .y = 0 });

    _ = ecs.progress(world, 0);
    _ = ecs.progress(world, 0);
    _ = ecs.progress(world, 0);

    const p = ecs.get(world, bob, Position).?;
    std.debug.print("Bobs position = {any}\n", .{p});
}
