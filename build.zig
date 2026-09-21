const std = @import("std");

const Action = enum {
    build, // zig build       -> build to install prefix
    clean, // zig build clean -> remove install prefix
    clear, // zig build clear -> remove install prefix and cached imports
};

const RepoImport = struct {
    name: []const u8, // any name
    url: []const u8, // git repo url
    commit: []const u8, // commit hash
    prefix: []const u8, // repository prefix, omitted from install prefix
    paths: []const []const u8, // relative or prefix-qualified filepaths
};

const dependencies = [_]RepoImport{
    .{
        .name = "pretty-file",
        .url = "https://github.com/urbit/urbit",
        .commit = "0f94550b941dfe046d9dff4a541330bd084e8cd1",
        .prefix = "pkg/arvo",
        .paths = &.{
            "lib/pretty-file.hoon",
        },
    },
    .{
        .name = "test-agent",
        .url = "https://github.com/tloncorp/tlon-apps",
        .commit = "9f0c94771e4773567a2f55a727ffa31b0f6e8e9f",
        .prefix = "desk",
        .paths = &.{
            "lib/test-agent.hoon",
        },
    },
    .{
        .name = "base-dev",
        .url = "https://github.com/urbit/urbit",
        .commit = "0f94550b941dfe046d9dff4a541330bd084e8cd1",
        .prefix = "pkg/base-dev",
        .paths = &.{
            "lib/dbug.hoon",
            "lib/default-agent.hoon",
            "lib/server.hoon",
            "lib/skeleton.hoon",
            "lib/sole.hoon",
            "lib/strand.hoon",
            "lib/strandio.hoon",
            "lib/test.hoon",
            "lib/verb.hoon",
            "mar/bill.hoon",
            "mar/hoon.hoon",
            "mar/json.hoon",
            "mar/kelvin.hoon",
            "mar/mime.hoon",
            "mar/noun.hoon",
            "mar/ship.hoon",
            "mar/sole/action.hoon",
            "mar/sole/effect.hoon",
            "mar/txt.hoon",
            "sur/sole.hoon",
            "sur/aquarium.hoon",
            "sur/spider.hoon",
            "sur/verb.hoon",
        },
    },
};

const dependency_cache_dir = "desk-deps";
const minimum_git_version = GitVersion{ .major = 2, .minor = 25, .patch = 0 };

const GitVersion = struct {
    major: u32,
    minor: u32,
    patch: u32,

    fn order(a: GitVersion, b: GitVersion) std.math.Order {
        if (a.major != b.major) return std.math.order(a.major, b.major);
        if (a.minor != b.minor) return std.math.order(a.minor, b.minor);
        return std.math.order(a.patch, b.patch);
    }
};

const DeskStep = struct {
    step: std.Build.Step,
    action: Action,
    install_path: []const u8,
    copy_target: ?[]const u8,

    fn create(b: *std.Build, name: []const u8, action: Action, copy_target: ?[]const u8) *DeskStep {
        const self = b.allocator.create(DeskStep) catch @panic("OOM");
        self.* = .{
            .step = std.Build.Step.init(.{
                .id = .custom,
                .name = name,
                .owner = b,
                .makeFn = make,
            }),
            .action = action,
            .install_path = b.install_path,
            .copy_target = copy_target,
        };
        return self;
    }

    fn make(step: *std.Build.Step, options: std.Build.Step.MakeOptions) !void {
        _ = options;
        const self: *DeskStep = @fieldParentPtr("step", step);
        const allocator = step.owner.allocator;

        switch (self.action) {
            .build => try buildDesk(step, allocator, self.install_path, self.copy_target),
            .clean => try clean(self.install_path),
            .clear => try clear(step),
        }
    }
};

pub fn build(b: *std.Build) void {
    const default_optimize: std.builtin.OptimizeMode = switch (b.release_mode) {
        .off, .any, .fast => .ReleaseFast,
        .safe => .ReleaseSafe,
        .small => .ReleaseSmall,
    };
    const optimize = b.option(
        std.builtin.OptimizeMode,
        "optimize",
        "Prioritize performance, safety, or binary size",
    ) orelse default_optimize;
    _ = optimize;

    const desk = b.option([]const u8, "desk", "After building, replace the desk at this path with install prefix contents");

    const build_step = DeskStep.create(b, "build desk", .build, desk);
    b.default_step.dependOn(&build_step.step);

    const named_build = b.step("build", "Build install prefix from /desk and dependencies");
    named_build.dependOn(&build_step.step);

    const clean_step = DeskStep.create(b, "clean", .clean, null);
    const named_clean = b.step("clean", "Remove install prefix");
    named_clean.dependOn(&clean_step.step);

    const clear_step = DeskStep.create(b, "clear", .clear, null);
    const named_clear = b.step("clear", "Remove install prefix and cached dependencies");
    named_clear.dependOn(&clear_step.step);
}

fn buildDesk(step: *std.Build.Step, allocator: std.mem.Allocator, install_path: []const u8, copy_target: ?[]const u8) !void {
    try requireGitVersion(step);

    if (!pathExists("desk") and !pathExists("desk-dev")) {
        return step.fail("neither /desk nor /desk-dev directory found", .{});
    }

    std.debug.print("Creating install prefix at {s}...\n", .{install_path});
    try recreateDir(install_path);

    if (pathExists("desk")) {
        std.debug.print("Copying /desk to install prefix...\n", .{});
        try copyDirContents(allocator, "desk", install_path);
    }

    var import_copies = std.ArrayList(ImportCopy){};
    var fetches = std.ArrayList(RepoFetch){};
    for (dependencies) |dep| {
        try collectDependencyImports(step, allocator, dep, install_path, &import_copies, &fetches);
    }

    try fetchMissingImports(step, allocator, fetches.items);

    for (import_copies.items) |copy| {
        try copyFilePath(copy.cache_path, copy.dest_path);
    }

    std.debug.print("Built!\n", .{});

    if (copy_target) |target| {
        const target_path = try expandHomePath(allocator, step, target);
        try copyInstallPrefixToTarget(allocator, step, install_path, target_path);
    }
}

fn clean(install_path: []const u8) !void {
    try deleteTreeIfExists(install_path);
}

fn clear(step: *std.Build.Step) !void {
    const self: *DeskStep = @fieldParentPtr("step", step);
    try clean(self.install_path);
    try deleteTreeIfExists(try dependencyCacheRootPath(step));
}

const ImportCopy = struct {
    cache_path: []const u8,
    dest_path: []const u8,
};

const MissingImport = struct {
    import_path: []const u8,
    cache_path: []const u8,
};

const RepoFetch = struct {
    repo_path: []const u8,
    name: []const u8,
    url: []const u8,
    commit: []const u8,
    imports: std.ArrayList(MissingImport),
};

const ImportFetchTask = struct {
    repo_path: []const u8,
    name: []const u8,
    url: []const u8,
    commit: []const u8,
    imports: []const MissingImport,
    err: ?anyerror = null,
};

fn collectDependencyImports(
    step: *std.Build.Step,
    allocator: std.mem.Allocator,
    dep: RepoImport,
    install_path: []const u8,
    import_copies: *std.ArrayList(ImportCopy),
    fetches: *std.ArrayList(RepoFetch),
) !void {
    const repo_path = try repoCachePath(step, dep);

    for (dep.paths) |path| {
        const import_path = try prefixedPath(allocator, dep.prefix, path);
        const rel = strippedPath(dep.prefix, path);
        const cache_path = try fileImportCachePath(step, dep, import_path);
        const dest_path = try std.fs.path.join(allocator, &.{ install_path, rel });
        try import_copies.append(allocator, .{
            .cache_path = cache_path,
            .dest_path = dest_path,
        });

        if (!pathExists(cache_path)) {
            try addMissingImport(allocator, fetches, dep, repo_path, import_path, cache_path);
        }
    }
}

fn addMissingImport(
    allocator: std.mem.Allocator,
    fetches: *std.ArrayList(RepoFetch),
    dep: RepoImport,
    repo_path: []const u8,
    import_path: []const u8,
    cache_path: []const u8,
) !void {
    for (fetches.items) |*fetch| {
        if (std.mem.eql(u8, fetch.repo_path, repo_path)) {
            try fetch.imports.append(allocator, .{
                .import_path = import_path,
                .cache_path = cache_path,
            });
            return;
        }
    }

    var imports = std.ArrayList(MissingImport){};
    try imports.append(allocator, .{
        .import_path = import_path,
        .cache_path = cache_path,
    });
    try fetches.append(allocator, .{
        .repo_path = repo_path,
        .name = dep.name,
        .url = dep.url,
        .commit = dep.commit,
        .imports = imports,
    });
}

fn fetchMissingImports(
    step: *std.Build.Step,
    allocator: std.mem.Allocator,
    fetches: []const RepoFetch,
) !void {
    if (fetches.len == 0) return;

    var tasks = try allocator.alloc(ImportFetchTask, fetches.len);
    var threads = try allocator.alloc(std.Thread, fetches.len);
    var spawned: usize = 0;

    for (fetches, 0..) |fetch, i| {
        tasks[i] = .{
            .repo_path = fetch.repo_path,
            .name = fetch.name,
            .url = fetch.url,
            .commit = fetch.commit,
            .imports = fetch.imports.items,
        };
        threads[i] = std.Thread.spawn(.{}, fetchMissingImportsThread, .{&tasks[i]}) catch |err| {
            for (threads[0..spawned]) |thread| {
                thread.join();
            }
            return step.fail("failed to spawn import fetch thread: {s}", .{@errorName(err)});
        };
        spawned += 1;
    }

    for (threads[0..spawned]) |thread| {
        thread.join();
    }

    for (tasks) |task| {
        if (task.err) |err| {
            return step.fail("failed to import {s}: {s}", .{ task.name, @errorName(err) });
        }
    }
}

fn fetchMissingImportsThread(task: *ImportFetchTask) void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    fetchMissingImportsThreadInner(arena.allocator(), task) catch |err| {
        task.err = err;
    };
}

fn fetchMissingImportsThreadInner(
    allocator: std.mem.Allocator,
    task: *ImportFetchTask,
) !void {
    var paths = std.ArrayList([]const u8){};
    for (task.imports) |import| {
        try paths.append(allocator, import.import_path);
    }

    try ensureRepoImport(allocator, task.repo_path, task.name, task.url, task.commit, paths.items);

    for (task.imports) |import| {
        const repo_file_path = try std.fs.path.join(allocator, &.{ task.repo_path, import.import_path });
        try copyFilePath(repo_file_path, import.cache_path);
    }
}

fn ensureRepoImport(
    allocator: std.mem.Allocator,
    repo_path: []const u8,
    name: []const u8,
    url: []const u8,
    commit: []const u8,
    paths: []const []const u8,
) !void {
    const git_dir = try std.fs.path.join(allocator, &.{ repo_path, ".git" });
    if (!pathExists(git_dir)) {
        if (std.fs.path.dirname(repo_path)) |parent| {
            try std.fs.cwd().makePath(parent);
        }
        try std.fs.cwd().makePath(repo_path);
        std.debug.print("Importing {s}...\n", .{name});
        try run(allocator, &.{ "git", "-C", repo_path, "init" });
        try run(allocator, &.{ "git", "-C", repo_path, "remote", "add", "origin", url });
        try run(allocator, &.{ "git", "-C", repo_path, "sparse-checkout", "init", "--no-cone" });
    }

    try setSparseCheckout(allocator, repo_path, paths);

    if (!gitHasCommit(allocator, repo_path, commit)) {
        try run(allocator, &.{ "git", "-C", repo_path, "fetch", "--depth", "1", "--filter=blob:none", "origin", commit });
    }

    try run(allocator, &.{ "git", "-C", repo_path, "checkout", "--detach", "--force", commit });
}

fn dependencyCacheRootPath(step: *std.Build.Step) ![]const u8 {
    return step.owner.graph.global_cache_root.join(step.owner.allocator, &.{dependency_cache_dir});
}

fn repoCachePath(step: *std.Build.Step, dep: RepoImport) ![]const u8 {
    const key = try repoCacheKey(step.owner.allocator, dep);
    return step.owner.graph.global_cache_root.join(step.owner.allocator, &.{ dependency_cache_dir, "repos", key });
}

fn fileImportCachePath(step: *std.Build.Step, dep: RepoImport, import_path: []const u8) ![]const u8 {
    const key = try fileImportCacheKey(step.owner.allocator, dep, import_path);
    return step.owner.graph.global_cache_root.join(step.owner.allocator, &.{ dependency_cache_dir, "files", key });
}

fn repoCacheKey(allocator: std.mem.Allocator, dep: RepoImport) ![]const u8 {
    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    hashBytes(&hasher, dep.url);
    hashBytes(&hasher, dep.commit);
    return finishCacheKey(allocator, &hasher);
}

fn fileImportCacheKey(allocator: std.mem.Allocator, dep: RepoImport, import_path: []const u8) ![]const u8 {
    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    hashBytes(&hasher, dep.url);
    hashBytes(&hasher, dep.commit);
    hashBytes(&hasher, import_path);
    return finishCacheKey(allocator, &hasher);
}

fn finishCacheKey(allocator: std.mem.Allocator, hasher: *std.crypto.hash.sha2.Sha256) ![]const u8 {
    var digest: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
    hasher.final(&digest);

    const hex = std.fmt.bytesToHex(digest, .lower);
    return allocator.dupe(u8, &hex);
}

fn hashBytes(hasher: *std.crypto.hash.sha2.Sha256, bytes: []const u8) void {
    const len = bytes.len;
    hasher.update(std.mem.asBytes(&len));
    hasher.update(bytes);
}

fn requireGitVersion(step: *std.Build.Step) !void {
    const result = std.process.Child.run(.{
        .allocator = step.owner.allocator,
        .argv = &.{ "git", "--version" },
        .max_output_bytes = 16 * 1024,
    }) catch |err| {
        return step.fail("failed to run git --version: {s}", .{@errorName(err)});
    };

    switch (result.term) {
        .Exited => |code| {
            if (code != 0) {
                if (result.stderr.len > 0) {
                    std.debug.print("{s}", .{result.stderr});
                }
                return step.fail("git --version exited with code {d}", .{code});
            }
        },
        else => return step.fail("git --version failed", .{}),
    }

    const version = parseGitVersion(result.stdout) orelse {
        return step.fail("could not parse git version from: {s}", .{std.mem.trim(u8, result.stdout, " \t\r\n")});
    };

    if (version.order(minimum_git_version) == .lt) {
        return step.fail(
            "git {d}.{d}.{d} or newer is required; found {s}",
            .{
                minimum_git_version.major,
                minimum_git_version.minor,
                minimum_git_version.patch,
                std.mem.trim(u8, result.stdout, " \t\r\n"),
            },
        );
    }
}

fn parseGitVersion(output: []const u8) ?GitVersion {
    const prefix = "git version ";
    const trimmed = std.mem.trim(u8, output, " \t\r\n");
    if (!std.mem.startsWith(u8, trimmed, prefix)) return null;

    const rest = trimmed[prefix.len..];
    const version_text = rest[0 .. std.mem.indexOfScalar(u8, rest, ' ') orelse rest.len];

    var parts = std.mem.splitScalar(u8, version_text, '.');
    const major_text = parts.next() orelse return null;
    const minor_text = parts.next() orelse return null;
    const patch_text = parts.next() orelse return null;

    const patch_end = for (patch_text, 0..) |char, i| {
        if (!std.ascii.isDigit(char)) break i;
    } else patch_text.len;
    if (patch_end == 0) return null;

    return .{
        .major = std.fmt.parseInt(u32, major_text, 10) catch return null,
        .minor = std.fmt.parseInt(u32, minor_text, 10) catch return null,
        .patch = std.fmt.parseInt(u32, patch_text[0..patch_end], 10) catch return null,
    };
}

fn setSparseCheckout(allocator: std.mem.Allocator, repo_path: []const u8, paths: []const []const u8) !void {
    var argv = std.ArrayList([]const u8){};
    try argv.append(allocator, "git");
    try argv.append(allocator, "-C");
    try argv.append(allocator, repo_path);
    try argv.append(allocator, "sparse-checkout");
    try argv.append(allocator, "set");
    try argv.append(allocator, "--no-cone");
    for (paths) |path| {
        try argv.append(allocator, path);
    }
    try run(allocator, argv.items);
}

fn gitHasCommit(allocator: std.mem.Allocator, repo_path: []const u8, commit: []const u8) bool {
    const commit_ref = std.fmt.allocPrint(allocator, "{s}^{{commit}}", .{commit}) catch return false;
    return runAllowFail(allocator, &.{ "git", "-C", repo_path, "cat-file", "-e", commit_ref });
}

fn run(allocator: std.mem.Allocator, argv: []const []const u8) !void {
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = argv,
        .max_output_bytes = 256 * 1024,
    }) catch |err| return err;

    switch (result.term) {
        .Exited => |code| {
            if (code == 0) return;
            if (result.stderr.len > 0) {
                std.debug.print("{s}", .{result.stderr});
            }
            std.debug.print("command exited with code {d}: {s}\n", .{ code, argv[0] });
            return error.CommandFailed;
        },
        else => {
            if (result.stderr.len > 0) {
                std.debug.print("{s}", .{result.stderr});
            }
            std.debug.print("command failed: {s}\n", .{argv[0]});
            return error.CommandFailed;
        },
    }
}

fn runAllowFail(allocator: std.mem.Allocator, argv: []const []const u8) bool {
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = argv,
        .max_output_bytes = 256 * 1024,
    }) catch return false;

    return switch (result.term) {
        .Exited => |code| code == 0,
        else => false,
    };
}

fn prefixedPath(allocator: std.mem.Allocator, prefix: []const u8, path: []const u8) ![]const u8 {
    if (prefix.len == 0 or hasPathPrefix(prefix, path)) return path;
    return std.fs.path.join(allocator, &.{ prefix, path });
}

fn strippedPath(prefix: []const u8, path: []const u8) []const u8 {
    if (!hasPathPrefix(prefix, path)) return path;
    if (path.len == prefix.len) return path[path.len..];
    return path[prefix.len + 1 ..];
}

fn hasPathPrefix(prefix: []const u8, path: []const u8) bool {
    if (prefix.len == 0 or !std.mem.startsWith(u8, path, prefix)) return false;
    return path.len == prefix.len or path[prefix.len] == '/';
}

test "dependency paths may include or omit their prefix" {
    const added = try prefixedPath(std.testing.allocator, "desk", "mar/example.hoon");
    defer std.testing.allocator.free(added);

    try std.testing.expectEqualStrings("desk/mar/example.hoon", added);
    try std.testing.expectEqualStrings("desk/mar/example.hoon", try prefixedPath(std.testing.allocator, "desk", "desk/mar/example.hoon"));
    try std.testing.expectEqualStrings("mar/example.hoon", strippedPath("desk", "desk/mar/example.hoon"));
    try std.testing.expectEqualStrings("mar/example.hoon", strippedPath("desk", "mar/example.hoon"));
    try std.testing.expectEqualStrings("desk-tools/example.hoon", strippedPath("desk", "desk-tools/example.hoon"));
}

test "git version output is parsed" {
    try std.testing.expectEqual(GitVersion{ .major = 2, .minor = 50, .patch = 1 }, parseGitVersion("git version 2.50.1 (Apple Git-155)\n").?);
    try std.testing.expectEqual(GitVersion{ .major = 2, .minor = 25, .patch = 0 }, parseGitVersion("git version 2.25.0\n").?);
    try std.testing.expectEqual(GitVersion{ .major = 2, .minor = 39, .patch = 5 }, parseGitVersion("git version 2.39.5.windows.1\n").?);
    try std.testing.expect(parseGitVersion("not git 2.50.1") == null);
}

test "git version ordering" {
    try std.testing.expect((GitVersion{ .major = 2, .minor = 24, .patch = 9 }).order(minimum_git_version) == .lt);
    try std.testing.expect((GitVersion{ .major = 2, .minor = 25, .patch = 0 }).order(minimum_git_version) == .eq);
    try std.testing.expect((GitVersion{ .major = 2, .minor = 50, .patch = 1 }).order(minimum_git_version) == .gt);
}

fn expandHomePath(allocator: std.mem.Allocator, step: *std.Build.Step, path: []const u8) ![]const u8 {
    if (std.mem.eql(u8, path, "~")) {
        return std.process.getEnvVarOwned(allocator, "HOME") catch |err| {
            return step.fail("could not expand '~': HOME is unavailable: {s}", .{@errorName(err)});
        };
    }

    if (std.mem.startsWith(u8, path, "~/")) {
        const home = std.process.getEnvVarOwned(allocator, "HOME") catch |err| {
            return step.fail("could not expand '~': HOME is unavailable: {s}", .{@errorName(err)});
        };
        return std.fs.path.join(allocator, &.{ home, path[2..] });
    }

    return path;
}

fn copyInstallPrefixToTarget(allocator: std.mem.Allocator, step: *std.Build.Step, install_path: []const u8, target_path: []const u8) !void {
    if (!pathExists(install_path)) {
        return step.fail("install prefix '{s}' not found. Run build first", .{install_path});
    }
    if (!pathExists(target_path)) {
        return step.fail("target path '{s}' does not exist", .{target_path});
    }

    std.debug.print("Clearing destination desk...\n", .{});
    try clearDirContents(allocator, target_path);

    std.debug.print("Copying install prefix to destination desk...\n", .{});
    try copyDirContents(allocator, install_path, target_path);

    std.debug.print("Copied!\n", .{});
}

fn copyDirContents(allocator: std.mem.Allocator, source_path: []const u8, dest_path: []const u8) !void {
    var source_dir = try std.fs.cwd().openDir(source_path, .{ .iterate = true });
    defer source_dir.close();

    try std.fs.cwd().makePath(dest_path);
    var it = source_dir.iterate();
    while (try it.next()) |entry| {
        const src = try std.fs.path.join(allocator, &.{ source_path, entry.name });
        const dst = try std.fs.path.join(allocator, &.{ dest_path, entry.name });

        switch (entry.kind) {
            .directory => try copyDirContents(allocator, src, dst),
            .file => try copyFilePath(src, dst),
            else => {},
        }
    }
}

fn copyFilePath(source_path: []const u8, dest_path: []const u8) !void {
    if (std.fs.path.dirname(dest_path)) |parent| {
        try std.fs.cwd().makePath(parent);
    }
    try std.fs.cwd().copyFile(source_path, std.fs.cwd(), dest_path, .{});
}

fn clearDirContents(allocator: std.mem.Allocator, dir_path: []const u8) !void {
    {
        var dir = try std.fs.cwd().openDir(dir_path, .{ .iterate = true });
        defer dir.close();

        var it = dir.iterate();
        while (try it.next()) |entry| {
            if (entry.kind == .file or entry.kind == .sym_link) {
                const child_path = try std.fs.path.join(allocator, &.{ dir_path, entry.name });
                try std.fs.cwd().deleteFile(child_path);
            }
        }
    }

    {
        var dir = try std.fs.cwd().openDir(dir_path, .{ .iterate = true });
        defer dir.close();

        var it = dir.iterate();
        while (try it.next()) |entry| {
            if (entry.kind == .directory) {
                const child_path = try std.fs.path.join(allocator, &.{ dir_path, entry.name });
                try clearDirContents(allocator, child_path);
                try std.fs.cwd().deleteDir(child_path);
            }
        }
    }
}

fn recreateDir(path: []const u8) !void {
    try deleteTreeIfExists(path);
    try std.fs.cwd().makePath(path);
}

fn deleteTreeIfExists(path: []const u8) !void {
    if (pathExists(path)) {
        try std.fs.cwd().deleteTree(path);
    }
}

fn pathExists(path: []const u8) bool {
    std.fs.cwd().access(path, .{}) catch return false;
    return true;
}
