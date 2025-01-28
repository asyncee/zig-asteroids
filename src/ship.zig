const std = @import("std");
const rl = @import("raylib");
const rlm = rl.math;
const Flare = @import("flare.zig").Flare;
const drawLines = @import("drawing.zig").drawLines;

const SCALE = 50;

pub const Ship = struct {
    pos: rl.Vector2,
    rot: f32 = 0,
    vel: rl.Vector2 = rl.Vector2.init(0, 0),
    collision_size: f32 = 27.0,
    flare: Flare,

    pub fn init() !Ship {
        const flare = try Flare.init(150);
        return Ship{
            .pos = rl.Vector2.init(0, 0),
            .flare = flare,
        };
    }

    pub fn deinit(self: Ship) void {
        defer self.flare.deinit();
    }

    pub fn draw(self: Ship) void {
        self.drawShipBody();
        self.flare.draw();
    }

    fn drawShipBody(self: Ship) void {
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
