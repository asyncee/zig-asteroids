const std = @import("std");
const rl = @import("raylib");
const rlm = rl.math;
const Flare = @import("flare.zig").Flare;
const drawLines = @import("drawing.zig").drawLines;
const constants = @import("constants.zig");

const SCALE = 50;

pub const Ship = struct {
    pos: rl.Vector2,
    rot: f32 = 0,
    vel: rl.Vector2 = rl.Vector2.init(0, 0),
    collision_size: f32 = 27.0,
    flare: Flare,

    pub fn init(allocator: std.mem.Allocator) !Ship {
        const flare = try Flare.init(allocator, 150);
        return Ship{
            .pos = rl.Vector2.init(0, 0),
            .flare = flare,
        };
    }

    pub fn deinit(self: *Ship) void {
        self.flare.deinit();
    }

    pub fn update(self: *Ship, dt: f32, camera: rl.Camera2D) void {
        try self.flare.update(dt, self.pos, self.rot);

        self.vel = rlm.vector2Scale(self.vel, 0.98);
        self.pos = rlm.vector2Add(self.pos, self.vel);
        self.pos = rl.Vector2.init(
            @mod(self.pos.x + camera.offset.x, constants.SCREEN_WIDTH) - camera.offset.x,
            @mod(self.pos.y + camera.offset.y, constants.SCREEN_HEIGHT) - camera.offset.y,
        );
    }

    pub fn draw(self: *Ship) void {
        self.drawShipBody();
        self.flare.draw();
    }

    fn drawShipBody(self: *Ship) void {
        drawLines(
            self.pos,
            self.rot,
            SCALE,
            &.{
                rl.Vector2.init(-0.4, 0.5),
                rl.Vector2.init(0, -0.5),
                rl.Vector2.init(0.4, 0.5),
                rl.Vector2.init(0.2, 0.4),
                rl.Vector2.init(-0.2, 0.4),
            },
        );
    }
};
