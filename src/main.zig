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
    // var max_value: f16 = 0.0;
    // var stationsMaxMap = std.StringArrayHashMapUnmanaged(f16){};
    var stationsMaxMap = std.StringHashMap(f16).init(std.heap.page_allocator);
    defer stationsMaxMap.deinit();
    while (reader.streamUntilDelimiter(writer, '\n', null)) : (line_no += 1) {
        // Clear the line so we can reuse it.
        defer line.clearRetainingCapacity();

        var splitted_line = std.mem.tokenize(u8, line.items, ";");
        const station = splitted_line.next().?;
        const value = try std.fmt.parseFloat(f16, splitted_line.rest());

        if (stationsMaxMap.get(station)) |currentValue| {
            try stationsMaxMap.put(station, @max(currentValue, value));
        } else {
            // std.debug.print("hello here {s}\n", .{station});
            const clonedStation = try std.mem.Allocator.dupe(std.heap.page_allocator, u8, station);
            try stationsMaxMap.put(clonedStation, value);
        }



        // max_value = @max(max_value, try std.fmt.parseFloat(f16, value.?));

        // print("{?s} value: {?s}\n", .{ name, value });
        // if (line_no == 5) {
        //    break;
        // }
    } else |err| switch (err) {
        error.EndOfStream => {}, // Continue on
        else => return err, // Propagate error
    }

    var iter = stationsMaxMap.iterator();
    while (iter.next()) |entry| {
        const key = entry.key_ptr.*;
        const value = entry.value_ptr.*;

        print("Station: {s}, max value: {d}\n",.{key, value});
    }
    // print("max value: {d}", .{max_value});
}