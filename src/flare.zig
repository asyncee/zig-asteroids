const std = @import("std");
const rl = @import("raylib");
const rlm = rl.math;

var prng = std.rand.DefaultPrng.init(0);

const Particle = struct {
    pos: rl.Vector2,
    rot: f32,
    vel: rl.Vector2 = rl.Vector2.init(0, 0),
    size: f32,
    life: f32,
};

pub const Flare = struct {
    particles: std.ArrayList(Particle),

    pub fn init(allocator: std.mem.Allocator, particles_count: usize) !Flare {
        var particles = std.ArrayList(Particle).init(allocator);

        const rand = prng.random();

        for (0..particles_count) |_| {
            try particles.append(.{
                .pos = rl.Vector2.init(0, 0),
                .rot = 0,
                .vel = rl.Vector2.init(0, 0),
                .size = 1.0 + 4.0 * rand.float(f32),
                .life = 0,
            });
        }

        return Flare{
            .particles = particles,
        };
    }

    pub fn deinit(self: *Flare) void {
        self.particles.deinit();
    }

    pub fn update(
        self: *Flare,
        dt: f32,
        ship_pos: rl.Vector2,
        ship_angle: f32,
    ) !void {
        const rand = prng.random();

        for (self.particles.items) |*particle| {
            particle.pos = rlm.vector2Add(particle.pos, particle.vel);
            particle.life -= dt * rand.float(f32) * 4.0;

            if (particle.life <= 0) {
                self.resetDeadParticle(particle, dt, ship_pos, ship_angle);
            }
        }
    }

    fn resetDeadParticle(
        _: *Flare,
        particle: *Particle,
        dt: f32,
        ship_pos: rl.Vector2,
        ship_angle: f32,
    ) void {
        const rand = prng.random();

        particle.pos = rlm.vector2Add(
            ship_pos,
            rlm.vector2Rotate(rl.Vector2.init((10 * rand.float(f32)) - 5.0, 20.0), ship_angle),
        );
        particle.rot = ship_angle;
        particle.vel = rlm.vector2Rotate(
            rl.Vector2.init(
                (30.0 * rand.float(f32) - 15.0) * dt * 2.0,
                100.0 * dt * 2.0,
            ),
            ship_angle,
        );
        particle.life = rand.float(f32);
    }

    pub fn draw(self: *Flare) void {
        for (self.particles.items) |p| {
            var color: rl.Color = undefined;

            if (p.life >= 0.8 and p.life <= 1.0) {
                color = rl.Color.red;
            } else if (p.life >= 0.4 and p.life <= 0.8) {
                color = rl.Color.yellow;
            } else if (p.life >= 0.1 and p.life <= 0.4) {
                color = rl.Color.orange;
            } else if (p.life >= 0 and p.life <= 0.1) {
                color = rl.Color.white;
            }

            rl.drawRectangleV(p.pos, rl.Vector2.init(p.size, p.size), color);
        }
    }
};
