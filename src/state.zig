const std = @import("std");
const rl = @import("raylib");
const rlm = rl.math;
const Ship = @import("ship.zig").Ship;
const Asteroid = @import("asteroid.zig").Asteroid;

var prng = std.rand.DefaultPrng.init(0);

pub const State = struct {
    ship: Ship,
    asteroids: std.ArrayList(Asteroid),

    pub fn init(allocator: std.mem.Allocator) !State {
        const asteroids = std.ArrayList(Asteroid).init(allocator);
        var state = State{
            .ship = try Ship.init(allocator),
            .asteroids = asteroids,
        };
        try state.addAsteroids();
        return state;
    }

    pub fn deinit(self: *State) void {
        self.asteroids.deinit();
        self.ship.deinit();
    }

    pub fn handleInput(self: *State, dt: f32) void {
        self.ship.handleInput(dt);
    }

    pub fn update(self: *State, dt: f32, camera: rl.Camera2D) void {
        self.ship.update(dt, camera);

        for (self.asteroids.items) |*asteroid| {
            asteroid.update(dt, camera);
        }
    }

    pub fn handleCollisions(self: *State) !void {
        for (self.asteroids.items) |*asteroid| {
            const dist = rlm.vector2Distance(asteroid.pos, self.ship.pos);
            if (dist < self.ship.collision_size + asteroid.radius) {
                try self.resetStage();
            }
        }
    }

    pub fn draw(self: *State) !void {
        self.ship.draw();
        try self.drawAsteroids();
    }

    fn drawAsteroids(self: *State) !void {
        for (self.asteroids.items) |asteroid| {
            try asteroid.draw();
        }
    }

    fn addAsteroids(self: *State) !void {
        const rand = prng.random();

        for (0..10) |_| {
            const radius = (rand.float(f32) * 50.0) + 10.0;
            const asteroid_seed: u64 = rand.int(u64);
            try self.asteroids.append(try Asteroid.init(radius, asteroid_seed));
        }
    }

    pub fn resetStage(self: *State) !void {
        self.ship.resetPosition();
        self.asteroids.clearRetainingCapacity();
        try addAsteroids(self);
    }
};
