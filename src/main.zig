const std = @import("std");
const rl = @import("raylib");
const rlm = rl.math;
const drawLines = @import("drawing.zig").drawLines;
const Flare = @import("flare.zig").Flare;
const Ship = @import("ship.zig").Ship;
const constants = @import("constants.zig");

var prng = std.rand.DefaultPrng.init(0);

const Asteroid = struct {
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

    fn draw(self: Asteroid) !void {
        drawLines(self.pos, 0.0, self.radius, self.points.slice());
    }
};

const State = struct {
    ship: Ship,
    dt: f32,
    asteroids: std.ArrayList(Asteroid),

    fn init(allocator: std.mem.Allocator) !State {
        const asteroids = std.ArrayList(Asteroid).init(allocator);

        return State{
            .ship = try Ship.init(allocator),
            .dt = 0,
            .asteroids = asteroids,
        };
    }

    fn deinit(self: *State) void {
        self.asteroids.deinit();
        self.ship.deinit();
    }

    pub fn update(self: *State, camera: rl.Camera2D) void {
        self.ship.update(self.dt, camera);
    }

    fn draw(self: *State) !void {
        self.ship.draw();
        try self.draw_asteroids();
    }

    fn draw_asteroids(self: *State) !void {
        for (self.asteroids.items) |asteroid| {
            try asteroid.draw();
        }
    }
};

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

    const ROT_SPEED = 2; // rotations per second
    const SHIP_SPEED = 20;

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        state.dt = rl.getFrameTime();

        const shipAngle = state.ship.rot - std.math.pi * 0.5;
        const shipDir = rl.Vector2.init(
            std.math.cos(shipAngle),
            std.math.sin(shipAngle),
        );

        // Input
        if (rl.isKeyDown(.a)) {
            state.ship.rot -= state.dt * std.math.tau * ROT_SPEED;
        } else if (rl.isKeyDown(.d)) {
            state.ship.rot += state.dt * std.math.tau * ROT_SPEED;
        }
        if (rl.isKeyDown(.w)) {
            state.ship.vel = rlm.vector2Add(
                state.ship.vel,
                rlm.vector2Scale(shipDir, state.dt * SHIP_SPEED),
            );
        }

        // update
        state.update(camera);

        for (state.asteroids.items) |*asteroid| {
            asteroid.pos = rlm.vector2Add(asteroid.pos, rlm.vector2Scale(asteroid.vel, state.dt));
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

        rl.drawText(
            rl.textFormat("pos: x=%f, y=%f", .{ state.ship.pos.x, state.ship.pos.y }),
            20,
            20,
            30,
            rl.Color.white,
        );
        camera.begin();
        try state.draw();
        camera.end();
    }
}
