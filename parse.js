//
// Note that this hacky and incomplete (e.g., doesn't negative numbers).
//

function tokenize(string) {
    var tokens = [];
    // Ideally, this regex should be defined in parts, and only combined here...
    //   but JS regexes don't seem to support combining like that.
    // Nor do they support Perl's whitespace-insensitivity extension.
    // Grumble, grumble.
    var regex = /([a-zA-Z]+)|([0-9]+(\.[0-9]*)?)|\(|\)|,|\s+|\+|\*|\/|\^|-/g;
    var result;
    while ((result = regex.exec(string))) {
        var r = result[0];
        if (/^\s+$/.test(r)) {
            continue;
        }
        if (/^[+-]?[0-9]+(\.[0-9]*)?$/.test(r)) {
            r = Number.parseInt(r, 10);
        }
        tokens.push(r);
    }
    tokens.push(false); // to signify end-of-stream
    return tokens;
}

function parse(tokens) {
    var idx = 0;
    var tokenLength = tokens.length;

    function match(token) {
        if (tokens[idx] !== token) {
            throw "Unexpected token: " + tokens[idx] + " (expected " + token + ")";
        }
        idx++;
        return true;
    }

    function matchOne(options) {
        if (!options.find(function (x) { return x === tokens[idx]; })) {
            return false;
        }
        return tokens[idx++];
    }

    function power() {
        if (tokens[idx] === '(') {
            match("(");
            var r = expr();
            match(")");
            return r;
        }

        var op;
        op = matchOne(["+", "-"]);
        if (op) {
            return [op, power()];
        }

        var idOrNumber = tokens[idx++];
        if (idOrNumber === false) {
            throw "End-of-stream?";
        }
        if (tokens[idx] !== '(') {
            return idOrNumber;
        }

        match("(");
        var args = functionArgs();
        match(")");

        args.unshift(idOrNumber);
        return args;
    };

    function rightAssocBinop(operators, nextParser) {
        if (typeof(operators) === 'string') {
            operators = operators.split('');
        }

        function parser() {
            var left = nextParser();
            var op = matchOne(operators);
            if (op === false) {
                return left;
            }
            var right = parser();
            return [op, left, right];
        }

        return parser;
    }

    function leftAssocBinop(operators, nextParser) {
        if (typeof(operators) === 'string') {
            operators = operators.split('');
        }

        function parser() {
            var result = nextParser();
            var op;
            while ((op = matchOne(operators))) {
                var next = nextParser();
                result = [op, result, next];
            }
            return result;
        }

        return parser;
    }

    var factor = rightAssocBinop("^", power);
    var term = leftAssocBinop("*/", factor);
    var expr = leftAssocBinop("+-", term);

    var functionArgs = function () {
        var args = [];
        args.push(expr());
        while (tokens[idx] === ',') {
            match(',');
            args.push(expr());
        }
        return args;
    };

    return expr();
}

function parseString(string) {
    return parse(tokenize(string));
}

if (typeof module !== 'undefined' && typeof module.exports !== 'undefined') {
    exports.tokenize = tokenize;
    exports.parse = parse;
    exports.parseString = parseString;
}
