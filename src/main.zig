const std = @import("std");
const rl = @import("raylib");
const rlm = rl.math;
const State = @import("state.zig").State;
const constants = @import("constants.zig");

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("TEST FAIL");
    }
    const allocator = gpa.allocator();

    rl.initWindow(constants.SCREEN_WIDTH, constants.SCREEN_HEIGHT, "Asteroids");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var state = try State.init(allocator);
    defer state.deinit();

    var camera = rl.Camera2D{
        .target = state.ship.pos,
        .offset = rl.Vector2.init(constants.SCREEN_WIDTH / 2, constants.SCREEN_HEIGHT / 2),
        .rotation = 0,
        .zoom = 1,
    };

    while (!rl.windowShouldClose()) {
        const dt = rl.getFrameTime();

        state.handleInput(dt);
        state.update(dt, camera);
        try state.handleCollisions();

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        camera.begin();
        try state.draw();
        camera.end();
    }
}
