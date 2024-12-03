const std = @import("std");
const ascii = std.ascii;
const io = std.io;
const assert = std.debug.assert;

const stdout = io.getStdOut().writer();

pub fn part1(file_reader: io.AnyReader) !i32 {
    var parser = Parser.from(file_reader);

    var answer: i32 = 0;

    while (true) {
        const instruction = parser.next_instruction() orelse return answer;

        // try stdout.print("mul({d},{d})\n", .{ instruction.multiply[0], instruction.multiply[1] });
        switch (instruction) {
            .multiply => |operands| answer += operands[0] * operands[1],
            else => {},
        }
    }

    unreachable;
}

test "part 1 example" {
    const example = "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))";

    var stream = std.io.fixedBufferStream(example);
    const reader = stream.reader().any();
    const answer = try part1(reader);
    try std.testing.expectEqual(161, answer);
}

pub fn part2(file_reader: io.AnyReader) !i32 {
    var parser = Parser.from(file_reader);

    var answer: i32 = 0;
    var multiplication_enabled = true;

    while (true) {
        const instruction = parser.next_instruction() orelse return answer;

        switch (instruction) {
            .multiply => |operands| {
                if (multiplication_enabled) {
                    // try stdout.print("[enabled]  ", .{});
                    answer += operands[0] * operands[1];
                } else {
                    // try stdout.print("[disabled] ", .{});
                }

                // try stdout.print("mul({d},{d})\n", .{ instruction.multiply[0], instruction.multiply[1] });
            },
            .do => {
                // try stdout.print("[do]\n", .{});
                multiplication_enabled = true;
            },
            .dont => {
                // try stdout.print("[don't]\n", .{});
                multiplication_enabled = false;
            },
        }
    }

    unreachable;
}

test "part 2 example" {
    const example = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))";

    var stream = std.io.fixedBufferStream(example);
    const reader = stream.reader().any();
    const answer = try part2(reader);
    try std.testing.expectEqual(48, answer);
}

const ByteIterator = struct {
    const Self = @This();

    reader: io.AnyReader,
    current: u8,
    done: bool,

    fn from(reader: io.AnyReader) Self {
        return .{ .reader = reader, .done = false, .current = 0 };
    }

    fn value(self: *Self) ?u8 {
        assert(self.current != 0);
        return if (self.done) null else self.current;
    }

    fn advance(self: *Self) void {
        assert(!self.done);

        if (self.reader.readByte()) |char| {
            self.current = char;
        } else |err| {
            assert(err == error.EndOfStream);
            self.done = true;
        }
    }
};

test "byte iterator" {
    var stream = std.io.fixedBufferStream("abcde");
    const reader = stream.reader().any();

    var bytes = ByteIterator.from(reader);

    for ("abcde") |char| {
        bytes.advance();
        try std.testing.expectEqual(char, bytes.value());
        try std.testing.expect(!bytes.done);
    }

    bytes.advance();
    try std.testing.expectEqual(null, bytes.value());
    try std.testing.expect(bytes.done);
}

const Operator = enum { multiply, do, dont };

const Token = union(enum) { operator: Operator, number: i32, open_parenthesis, close_parenthesis, comma, garbage };

const Tokenizer = struct {
    const Self = @This();

    bytes: ByteIterator,

    fn from(file_reader: io.AnyReader) Self {
        var bytes = ByteIterator.from(file_reader);
        _ = bytes.advance();
        return .{ .bytes = bytes };
    }

    fn next(self: *Self) ?Token {
        const token = self._next();
        // stdout.print("{any}\n", .{token}) catch unreachable;
        return token;
    }

    fn _next(self: *Self) ?Token {

        // starts with the current

        while (!self.bytes.done) {
            const current = self.bytes.current;

            // TODO: switch
            return switch (current) {
                'm', 'd' => Token{ .operator = self.operator() orelse continue },
                '0'...'9' => Token{ .number = self.number() orelse continue },
                ',' => {
                    self.bytes.advance();
                    return Token.comma;
                },
                ')' => {
                    self.bytes.advance();
                    return Token.close_parenthesis;
                },

                '(' => {
                    self.bytes.advance();
                    return Token.open_parenthesis;
                },
                else => {
                    self.bytes.advance();
                    return Token.garbage;
                },
            };
        }

        return null;
    }

    fn number(self: *Self) ?i32 {
        var digit_count: i32 = 0;
        var value: i32 = 0;
        while (ascii.isDigit(self.bytes.current)) {
            digit_count += 1;
            value = value * 10 + self.bytes.current - '0';
            self.bytes.advance();
        }
        if (digit_count > 3) return null;
        return value;
    }

    fn operator(self: *Self) ?Operator {
        assert(self.bytes.current == 'm' or self.bytes.current == 'd');

        if (self.bytes.current == 'm') {
            self.bytes.advance();
            const second = self.bytes.value() orelse return null;
            if (second != 'u') {
                return null;
            }

            self.bytes.advance();
            const third = self.bytes.value() orelse return null;

            if (third != 'l') {
                return null;
            }
            self.bytes.advance();

            return .multiply;
        } else {
            self.bytes.advance();
            const second = self.bytes.value() orelse return null;
            if (second != 'o') {
                return null;
            }

            self.bytes.advance();
            const third = self.bytes.value() orelse return null;
            if (third != 'n') {
                return .do;
            }

            self.bytes.advance();
            const fourth = self.bytes.value() orelse return null;
            if (fourth != '\'') return null;

            self.bytes.advance();
            const fifth = self.bytes.value() orelse return null;
            if (fifth != 't') return null;
            self.bytes.advance();

            return .dont;
        }
    }
};

test "tokenize number" {
    var stream = std.io.fixedBufferStream("123abc");
    const reader = stream.reader().any();
    var tokens = Tokenizer.from(reader);

    try std.testing.expectEqual(tokens.next(), Token{ .number = 123 });
}

test "tokenize" {
    var stream = std.io.fixedBufferStream("123mul)(9,8)");
    const reader = stream.reader().any();
    var tokens = Tokenizer.from(reader);

    try std.testing.expectEqual(tokens.next(), Token{ .number = 123 });
    try std.testing.expectEqual(tokens.next(), Token{ .operator = Operator.multiply });
    try std.testing.expectEqual(tokens.next(), Token.close_parenthesis);
    try std.testing.expectEqual(tokens.next(), Token.open_parenthesis);
    try std.testing.expectEqual(tokens.next(), Token{ .number = 9 });
    try std.testing.expectEqual(tokens.next(), Token.comma);
    try std.testing.expectEqual(tokens.next(), Token{ .number = 8 });
    try std.testing.expectEqual(tokens.next(), Token.close_parenthesis);
    try std.testing.expectEqual(tokens.next(), null);
}

const Instruction = union(Operator) {
    const Self = @This();
    multiply: [2]i32,
    do,
    dont,
};

const Parser = struct {
    const Self = @This();

    tokens: Tokenizer,

    fn from(file_reader: io.AnyReader) Self {
        return .{
            .tokens = Tokenizer.from(file_reader),
        };
    }

    fn next_instruction(self: *Self) ?Instruction {
        var token = self.tokens.next() orelse return null;

        while (true) {
            while (token != Token.operator) {
                token = self.tokens.next() orelse return null;
            }

            const operator = token.operator;

            token = self.tokens.next() orelse return null;
            if (token != Token.open_parenthesis) continue;

            if (operator != .multiply) {
                token = self.tokens.next() orelse return null;
                if (token != Token.close_parenthesis) continue;
                return switch (operator) {
                    .do => Instruction.do,
                    .dont => Instruction.dont,
                    .multiply => unreachable,
                };
            }

            token = self.tokens.next() orelse return null;
            const left = switch (token) {
                Token.number => |value| value,
                else => continue,
            };

            token = self.tokens.next() orelse return null;
            if (token != Token.comma) continue;

            token = self.tokens.next() orelse return null;
            const right = switch (token) {
                Token.number => |value| value,
                else => continue,
            };

            token = self.tokens.next() orelse return null;
            if (token != Token.close_parenthesis) continue;

            return Instruction{ .multiply = .{ left, right } };
        }
    }
};

test "parse single operation" {
    var stream = std.io.fixedBufferStream("123abcmul(9,8)3");
    const reader = stream.reader().any();
    var parser = Parser.from(reader);

    const instruction = parser.next_instruction().?;
    try std.testing.expectEqual(Instruction{ .multiply = .{ 9, 8 } }, instruction);
}
