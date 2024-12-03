const std = @import("std");
const ascii = std.ascii;
const io = std.io;
const assert = std.debug.assert;

const stdout = io.getStdOut().writer();

pub fn part1(file_reader: io.AnyReader) !i32 {
    var parser = Parser.from(file_reader);

    var answer: i32 = 0;

    var count: i32 = 0;

    while (true) {
        const instruction = parser.next_instruction() orelse return answer;
        count += 1;
        try stdout.print("mul({d},{d})\n", .{ instruction.multiply[0], instruction.multiply[1] });
        answer += instruction.evaluate();
    }

    unreachable;
}

test "part 1 example" {
    var stream = std.io.fixedBufferStream(example);
    const reader = stream.reader();
    const answer = try part1(reader);
    try std.testing.expectEqual(161, answer);
}

pub fn part2(file_reader: io.AnyReader) !u64 {
    _ = file_reader;
    // var instructions = try Input().instructions(file_reader);
    // const first_instruction = try instructions.next_instruction();

    // std.debug.print("{any}\n", .{});

    return 0;
}

test "part 2 example" {

    // var stream = std.io.fixedBufferStream(example);
    // const reader = stream.reader();
    // const answer = try part2(reader);
    // try std.testing.expectEqual(undefined, answer);

    return error.SkipZigTest;
}

const example =
    \\xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))
;

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
    const reader = stream.reader();

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

const Operator = enum {
    multiply,
};

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
        stdout.print("{any}\n", .{token}) catch unreachable;
        return token;
    }
    fn _next(self: *Self) ?Token {

        // starts with the current

        while (!self.bytes.done) {
            const current = self.bytes.current;

            // TODO: switch
            if (ascii.isDigit(current)) {
                return Token{ .number = self.number() orelse continue };
            } else if (current == ',') {
                self.bytes.advance();
                return Token.comma;
            } else if (current == '(') {
                self.bytes.advance();
                return Token.open_parenthesis;
            } else if (current == ')') {
                self.bytes.advance();
                return Token.close_parenthesis;
            } else if (current == 'm') {
                return Token{ .operator = self.operator() orelse continue };
            } else {
                self.bytes.advance();
                return Token.garbage;
            }
        }

        return null;
    }

    // TODO: I can already see a bug happening when the number goes to eof
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
        assert(self.bytes.current == 'm');

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

        return Operator.multiply;
    }
};

test "tokenize number" {
    var stream = std.io.fixedBufferStream("123abc");
    const reader = stream.reader();
    var tokens = Tokenizer.from(reader);

    try std.testing.expectEqual(tokens.next(), Token{ .number = 123 });
}

test "tokenize" {
    var stream = std.io.fixedBufferStream("123abcmul)(9,8)");
    const reader = stream.reader();
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

    fn evaluate(self: Self) i32 {
        return switch (self) {
            .multiply => |operands| operands[0] * operands[1],
        };
    }
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

            token = self.tokens.next() orelse return null;
            if (token != Token.open_parenthesis) continue;

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
    const reader = stream.reader();
    var parser = Parser.from(reader);

    const instruction = parser.next_instruction().?;
    try std.testing.expectEqual(Instruction{ .multiply = .{ 9, 8 } }, instruction);
}
