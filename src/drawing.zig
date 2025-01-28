const rl = @import("raylib");
const rlm = rl.math;

pub fn drawLines(origin: rl.Vector2, angle: f32, scale: f32, points: []const rl.Vector2) void {
    for (0..points.len) |i| {
        rl.drawLineV(
            rlm.vector2Add(rlm.vector2Scale(rlm.vector2Rotate(points[i], angle), scale), origin),
            rlm.vector2Add(rlm.vector2Scale(rlm.vector2Rotate(points[(i + 1) % points.len], angle), scale), origin),
            rl.Color.white,
        );
    }
}
