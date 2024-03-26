const std = @import("std");
const stdout = std.io.getStdOut().writer();
const fs = std.fs;
const print = std.debug.print;

fn printStation(station: []const u8) !void {
    try stdout.print("hello station: {s}.\n", .{station});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file = try fs.cwd().openFile("./measurements.txt", .{});
    defer file.close();

    // Wrap the file reader in a buffered reader.
    // Since it's usually faster to read a bunch of bytes at once.
    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    var line = std.ArrayList(u8).init(allocator);
    defer line.deinit();

    const writer = line.writer();
    var line_no: usize = 1;
    var max_value: f16 = 0.0;
    while (reader.streamUntilDelimiter(writer, '\n', null)) : (line_no += 1) {
        // Clear the line so we can reuse it.
        defer line.clearRetainingCapacity();

        var splitted_line = std.mem.split(u8, line.items, ";");
        _ = splitted_line.next();
        var value = splitted_line.next();
        max_value = @max(max_value, try std.fmt.parseFloat(f16, value.?));

        // print("{?s} value: {?s}\n", .{ name, value });
        //if (line_no == 5) {
        //    break;
        //}
    } else |err| switch (err) {
        error.EndOfStream => {}, // Continue on
        else => return err, // Propagate error
    }

    print("max value: {d}", .{max_value});
}