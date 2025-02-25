const std = @import("std");
const Ship = @import("ship.zig").Ship;
const rl = @import("raylib");
const rlm = rl.math;
const constants = @import("constants.zig");
const drawLines = @import("drawing.zig").drawLines;

var prng = std.rand.DefaultPrng.init(0);

pub const Asteroid = struct {
    pos: rl.Vector2,
    rot: f32 = 0,
    vel: rl.Vector2 = rl.Vector2.init(0, 0),
    radius: f32,
    seed: u64,
    points: std.BoundedArray(rl.Vector2, 16),

    pub fn init(radius: f32, seed: u64) !Asteroid {
        var points = try std.BoundedArray(rl.Vector2, 16).init(0);
        const rand = prng.random();

        const n: u32 = rand.intRangeAtMost(u32, 8, 12);
        const step_radians = (std.math.tau / @as(f32, @floatFromInt(n)));

        for (0..n) |i| {
            const jitter = rand.float(f32);
            const angle = @as(f32, @floatFromInt(i)) * step_radians + (jitter * std.math.tau * 0.1);
            var rad: f32 = 1.0;
            if (jitter < 0.2) {
                rad -= 0.3;
            }
            try points.append(
                rlm.vector2Scale(
                    rl.Vector2.init(std.math.cos(angle), std.math.sin(angle)),
                    rad,
                ),
            );
        }
        const pos = rl.Vector2.init(
            rand.float(f32) * constants.SCREEN_WIDTH - constants.SCREEN_WIDTH / 2,
            rand.float(f32) * constants.SCREEN_HEIGHT - constants.SCREEN_HEIGHT / 2,
        );
        const vel = rl.Vector2.init(
            rand.float(f32) * 1 / radius * constants.ASTEROID_SPEED,
            rand.float(f32) * 1 / radius * constants.ASTEROID_SPEED,
        );
        return Asteroid{
            .pos = pos,
            .rot = 0,
            .vel = vel,
            .radius = radius,
            .seed = seed,
            .points = points,
        };
    }

    pub fn draw(self: Asteroid) !void {
        drawLines(self.pos, 0.0, self.radius, self.points.slice());
    }
};
