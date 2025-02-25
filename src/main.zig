const std = @import("std");
const rl = @import("raylib");
const rlm = rl.math;
const drawLines = @import("drawing.zig").drawLines;
const Flare = @import("flare.zig").Flare;
const Ship = @import("ship.zig").Ship;
const State = @import("state.zig").State;
const Asteroid = @import("asteroid.zig").Asteroid;
const constants = @import("constants.zig");

var prng = std.rand.DefaultPrng.init(0);

fn add_asteroids(state: *State) !void {
    const rand = prng.random();

    for (0..10) |_| {
        const radius = (rand.float(f32) * 50.0) + 10.0;
        const asteroid_seed: u64 = rand.int(u64);
        try state.asteroids.append(try Asteroid.init(radius, asteroid_seed));
    }
}

fn resetStage(state: *State) !void {
    state.ship.pos = rl.Vector2.init(0, 0);
    state.asteroids.clearRetainingCapacity();
    try add_asteroids(state);
}

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("TEST FAIL");
    }
    const allocator = gpa.allocator();

    var state = try State.init(allocator);
    defer state.deinit();
    try add_asteroids(&state);

    rl.initWindow(constants.SCREEN_WIDTH, constants.SCREEN_HEIGHT, "Asteroids");
    defer rl.closeWindow();

    var camera = rl.Camera2D{
        .target = state.ship.pos,
        .offset = rl.Vector2.init(constants.SCREEN_WIDTH / 2, constants.SCREEN_HEIGHT / 2),
        .rotation = 0,
        .zoom = 1,
    };

    rl.setTargetFPS(60);
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) {
        const dt = rl.getFrameTime();

        state.handle_input(dt);
        state.update(dt, camera);

        for (state.asteroids.items) |*asteroid| {
            asteroid.pos = rlm.vector2Add(asteroid.pos, rlm.vector2Scale(asteroid.vel, dt));
            asteroid.pos = rl.Vector2.init(
                @mod(asteroid.pos.x + camera.offset.x, constants.SCREEN_WIDTH) - camera.offset.x,
                @mod(asteroid.pos.y + camera.offset.y, constants.SCREEN_HEIGHT) - camera.offset.y,
            );
        }

        // collision detection
        for (state.asteroids.items) |*asteroid| {
            const dist = rlm.vector2Distance(asteroid.pos, state.ship.pos);
            if (dist < state.ship.collision_size + asteroid.radius) {
                try resetStage(&state);
            }
        }

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        camera.begin();
        try state.draw();
        camera.end();
    }
}
