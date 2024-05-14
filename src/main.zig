const std = @import("std");
const stdout = std.io.getStdOut().writer();
const fs = std.fs;
const print = std.debug.print;
const ArrayList = std.ArrayList;
const ARR_SIZE = 8;

const StationValues = struct {
    maxValue: f32,
    minValue: f32,
    sumValue: f32,
    count: usize,
    total: usize,
    elements: @Vector(ARR_SIZE, f32),

    pub fn init(value: f32) StationValues {
        var elements = std.mem.zeroes(@Vector(ARR_SIZE, f32));
        elements[0] = value;

        return StationValues{
            .maxValue = value,
            .minValue = value,
            .sumValue = 0.0,
            .count = 1,
            .total = 1,
            .elements = elements, 
        };
    }

    pub fn addValue(self: *StationValues, value: f16) void {
        const valueAsFloat = @as(f32, value);
        self.elements[self.count] = valueAsFloat;
        self.count += 1;
        // self.sumValue += valueAsFloat;

        if(self.count == ARR_SIZE) {
            self.calculate();
        }
    }

    pub fn calculate(self: *StationValues) void {
        if (self.count == 0) {
            return;
        }
        
        self.sumValue += @reduce(.Add, self.elements);
        self.minValue = @min(self.minValue, @reduce(.Min, self.elements));
        self.maxValue = @max(self.maxValue, @reduce(.Max, self.elements));
        self.total += self.count;
        self.count = 0;
    }
};

const StationCalculator = struct {
    mapCalculator: std.StringArrayHashMap(*StationValues),

    pub fn create() StationCalculator {
        return StationCalculator{
            .mapCalculator = std.StringArrayHashMap(*StationValues).init(std.heap.page_allocator),
        };
    }

    pub fn addToMap(self: *StationCalculator, station: []const u8, value: f16) !void {
        
        if (self.mapCalculator.get(station)) |currentValue| {
            currentValue.addValue(value);
        } else {
            // std.debug.print("hello here {s}\n", .{station});
            const clonedStation = try std.mem.Allocator.dupe(std.heap.page_allocator, u8, station);
            const stationValues = try std.heap.page_allocator.create(StationValues);
            stationValues.* = StationValues.init(value);
            try self.mapCalculator.put(clonedStation, stationValues);
        }
    }

    pub fn calculateRemainingElements(self: StationCalculator) void {
        var iter = self.mapCalculator.iterator();
        while (iter.next()) |entry| {
            entry.value_ptr.*.calculate();
        }
    }
};

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
    var stationsMaxMap = StationCalculator.create();
    // defer stationsMaxMap.deinit();
    while (reader.streamUntilDelimiter(writer, '\n', null)) : (line_no += 1) {
        // Clear the line so we can reuse it.
        defer line.clearRetainingCapacity();

        var splitted_line = std.mem.tokenize(u8, line.items, ";");
        const station = splitted_line.next().?;
        const value = try std.fmt.parseFloat(f16, splitted_line.rest());
        try stationsMaxMap.addToMap(station, value);
        // print("{?s} value: {?s}\n", .{ name, value });
        // if (line_no == 5) {
        //    break;
        // }
    } else |err| switch (err) {
        error.EndOfStream => {}, // Continue on
        else => return err, // Propagate error
    }

    stationsMaxMap.calculateRemainingElements();

    const compareStrings = struct {
        keys: [][]const u8,

        pub fn lessThan(ctx: @This(), a_index: usize, b_index: usize) bool {
            return std.mem.lessThan(u8, ctx.keys[a_index], ctx.keys[b_index]);
        }
    };

    stationsMaxMap.mapCalculator.sort(compareStrings{.keys = stationsMaxMap.mapCalculator.keys()});
    var iter = stationsMaxMap.mapCalculator.iterator();
    // var keys = try stationsMaxMap.mapCalculator.keys();

    while (iter.next()) |entry| {
        const key = entry.key_ptr.*;
        const stationValue = entry.value_ptr.*;
        const maxValue = stationValue.maxValue;
        const minValue = stationValue.minValue;
        const meanValue = stationValue.sumValue / @as(f32, @floatFromInt(stationValue.total));
        const total = stationValue.total;

        print("Station: {s}, max value: {d}, min value: {d}, mean value: {d} total: {d}\n",.{key, maxValue, minValue, meanValue, total});
    }
    // print("max value: {d}", .{max_value});
}