const std = @import("std");
const Ship = @import("ship.zig").Ship;
const Asteroid = @import("asteroid.zig").Asteroid;
const rl = @import("raylib");

pub const State = struct {
    ship: Ship,
    asteroids: std.ArrayList(Asteroid),

    pub fn init(allocator: std.mem.Allocator) !State {
        const asteroids = std.ArrayList(Asteroid).init(allocator);

        return State{
            .ship = try Ship.init(allocator),
            .asteroids = asteroids,
        };
    }

    pub fn deinit(self: *State) void {
        self.asteroids.deinit();
        self.ship.deinit();
    }

    pub fn handle_input(self: *State, dt: f32) void {
        self.ship.handle_input(dt);
    }

    pub fn update(self: *State, dt: f32, camera: rl.Camera2D) void {
        self.ship.update(dt, camera);
    }

    pub fn draw(self: *State) !void {
        self.ship.draw();
        try self.draw_asteroids();
    }

    fn draw_asteroids(self: *State) !void {
        for (self.asteroids.items) |asteroid| {
            try asteroid.draw();
        }
    }
};
