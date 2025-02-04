const std = @import("std");
const rl = @import("raylib");
const rlm = rl.math;
const drawLines = @import("drawing.zig").drawLines;
const Flare = @import("flare.zig").Flare;
const Ship = @import("ship.zig").Ship;

const SCREEN_WIDTH = 800 * 2;
const SCREEN_HEIGHT = 600 * 2;

const Asteroid = struct {
    pos: rl.Vector2,
    rot: f32 = 0,
    vel: rl.Vector2 = rl.Vector2.init(0, 0),
    radius: f32,
    seed: u64,

    fn draw(self: @This()) !void {
        var points = try std.BoundedArray(rl.Vector2, 16).init(0);
        var prng = std.rand.DefaultPrng.init(self.seed);
        const rand = prng.random();

        const n: u32 = rand.intRangeAtMost(u32, 8, 12);
        const step_radians = (std.math.tau / @as(f32, @floatFromInt(n)));

        for (0..n) |i| {
            const jitter = rand.float(f32);
            const angle = @as(f32, @floatFromInt(i)) * step_radians + (jitter * std.math.tau * 0.1);
            var radius: f32 = 1.0;
            if (jitter < 0.2) {
                radius -= 0.3;
            }
            try points.append(
                rlm.vector2Scale(
                    rl.Vector2.init(std.math.cos(angle), std.math.sin(angle)),
                    radius,
                ),
            );
        }

        drawLines(self.pos, 0.0, self.radius, points.slice());
    }
};

const State = struct {
    ship: Ship,
    dt: f32,
    asteroids: std.ArrayList(Asteroid),

    fn init(allocator: std.mem.Allocator) !State {
        const asteroids = std.ArrayList(Asteroid).init(allocator);

        const ship = try Ship.init();
        return State{
            .ship = ship,
            .dt = 0,
            .asteroids = asteroids,
        };
    }

    fn deinit(self: State) void {
        defer self.asteroids.deinit();
        defer self.ship.deinit();
    }

    fn draw(self: State) void {
        self.ship.draw();
    }
};

fn drawAsteroids(state: *State) !void {
    for (state.asteroids.items) |asteroid| {
        try asteroid.draw();
    }
}

fn addAsteroids(state: *State) !void {
    var seed: u64 = undefined;
    try std.posix.getrandom(std.mem.asBytes(&seed));

    var prng = std.rand.DefaultPrng.init(seed);
    const rand = prng.random();

    const ASTEROID_SPEED = 6000.0;

    for (0..10) |_| {
        const radius = (rand.float(f32) * 50.0) + 10.0;

        var asteroid_seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&asteroid_seed));

        try state.asteroids.append(.{
            .pos = rl.Vector2.init(
                rand.float(f32) * SCREEN_WIDTH - SCREEN_WIDTH / 2,
                rand.float(f32) * SCREEN_HEIGHT - SCREEN_HEIGHT / 2,
            ),
            .rot = 0,
            .vel = rl.Vector2.init(
                rand.float(f32) * 1 / radius * ASTEROID_SPEED,
                rand.float(f32) * 1 / radius * ASTEROID_SPEED,
            ),
            .radius = radius,
            .seed = asteroid_seed,
        });
    }
}

fn resetStage(state: *State) !void {
    state.ship.pos = rl.Vector2.init(0, 0);
    state.asteroids.clearRetainingCapacity();
    try addAsteroids(state);
}

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var state = try State.init(allocator);
    defer state.deinit();
    try addAsteroids(&state);

    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Asteroids");
    defer rl.closeWindow();

    var camera = rl.Camera2D{
        .target = state.ship.pos,
        .offset = rl.Vector2.init(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2),
        .rotation = 0,
        .zoom = 1,
    };

    rl.setTargetFPS(60);
    //--------------------------------------------------------------------------------------

    const ROT_SPEED = 2; // rotations per second
    const SHIP_SPEED = 20;

    // Main game loop
    while (!rl.windowShouldClose()) {
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
        state.ship.vel = rlm.vector2Scale(state.ship.vel, 0.98);
        state.ship.pos = rlm.vector2Add(state.ship.pos, state.ship.vel);
        state.ship.pos = rl.Vector2.init(
            @mod(state.ship.pos.x + camera.offset.x, SCREEN_WIDTH) - camera.offset.x,
            @mod(state.ship.pos.y + camera.offset.y, SCREEN_HEIGHT) - camera.offset.y,
        );

        for (state.asteroids.items) |*asteroid| {
            asteroid.pos = rlm.vector2Add(asteroid.pos, rlm.vector2Scale(asteroid.vel, state.dt));
            asteroid.pos = rl.Vector2.init(
                @mod(asteroid.pos.x + camera.offset.x, SCREEN_WIDTH) - camera.offset.x,
                @mod(asteroid.pos.y + camera.offset.y, SCREEN_HEIGHT) - camera.offset.y,
            );
        }

        // collision detection
        for (state.asteroids.items) |*asteroid| {
            const dist = rlm.vector2Distance(asteroid.pos, state.ship.pos);
            if (dist < state.ship.collision_size + asteroid.radius) {
                try resetStage(&state);
            }
        }

        try state.ship.flare.update(
            state.dt,
            state.ship.pos,
            state.ship.rot,
        );

        // Draw
        //----------------------------------------------------------------------------------
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
        state.draw();
        try drawAsteroids(&state);
        camera.end();
        //----------------------------------------------------------------------------------
    }
}
