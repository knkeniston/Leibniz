#!/usr/bin/env node
// -*- mode: Javascript; mode: js2; tab-width: 8; -*-

// Shut up the intermediate output. TODO: Do something with the intermediate output
console.log = function (x) { return x; };

var parse = require("../parse.js");
var leibniz = require("../leibniz.js");
var tap = require("tap");

function deepCompare(A, B) {
    return A === B ||
	((A instanceof Array) &&
	 (B instanceof Array) &&
	 (A.length === B.length) &&
	 A.every(function(elem, index) {
	     return deepCompare(elem, B[index]);
	 }));
}

tap.Test.prototype.addAssert('oneOf', 2, function (found, expecteds, message, extra) {
    message = message || "should be something like";
    if (expecteds.some(function(elem) { return deepCompare(elem, found); })) {
	return this.pass(message, extra);
    }

    extra.found = found;
    extra.wanted = expecteds[0];
    extra.compare = "deepCompare";
    return this.fail(message, extra);
});

// smatch
tap.test('smatch', function(tap) {
    tap.ok(leibniz.smatch(42, 42), "42, 42 match"); 
    tap.notOk(leibniz.smatch(42, 40), "42, 40 do not match"); 
    tap.ok(leibniz.smatch("Gilligan", "Gilligan"), "'Gilligan', 'Gilligan' match"); 
    tap.notOk(leibniz.smatch("Gilligan", "Skipper"), "'Gilligan', 'Skipper' do not match"); 
    tap.ok(leibniz.smatch(["MaryAnn", 8], ["MaryAnn", 8]), "['MaryAnn', 8], ['MaryAnn', 8] match"); 
    tap.notOk(leibniz.smatch(["MaryAnn", 8], ["Ginger", 8]), "['MaryAnn', 8], ['Ginger', 8] do not match"); 
    tap.notOk(leibniz.smatch([8], 8), "[8], 8 do not match"); 
    tap.ok(leibniz.smatch([54, ['Mr Howell', 12, ['Lovey', 'Money'], 22], 'SS Minnow'],
			  [54, ['Mr Howell', 12, ['Lovey', 'Money'], 22], 'SS Minnow']),
	   "[54, ['Mr Howell', 12, ['Lovey', 'Money'], 22], 'SS Minnow'] matches with itself");
    tap.notOk(leibniz.smatch([54, ['Mr Howell', 12, ['Lovey', 'Money'], 22], 'SS Minnow'],
			     [54, ['Mr Howell', 12, ['Lovey', 'Money'], 44], 'SS Minnow']),
	   "[54, ['Mr Howell', 12, ['Lovey', 'Money'], 44], 'SS Minnow'] does not match where 22 -> 44");

    tap.ok((function() {
	var table = leibniz.smatch('foo?', 42);
	return table !=- null && table.foo && table.foo === 42;
    })(), "('foo?', 42) match, and table.foo = 42");
    tap.ok((function() {
	var table = leibniz.smatch('foo?', 'Professor');
	return table !=- null && table.foo && table.foo === 'Professor';
    })(), "('foo?', 'Professor') match, and table.foo = 'Professor'");
    tap.notOk(leibniz.smatch(['foo?'], 'Professor'), "(['foo?'], 'Professor') do not match");
    tap.ok((function() {
	var table = leibniz.smatch(['foo', 'foo?', 'bar'],
				   ['foo', [1, 2, 3], 'bar']);
	return table !=- null && table.foo && deepCompare(table.foo, [1, 2, 3]);
    })(), "(['foo', 'foo?', 'bar'], ['foo', [1, 2, 3], 'bar']) match, and table.foo is [1, 2, 3]");

    tap.ok((function() {
	var table = leibniz.smatch(['foo', 'foo?', 'bar'],
				   ['foo', 'banana', 'bar']);
	return table !=- null && table.foo && table.foo === 'banana';
    })(), "(['foo', 'foo?', 'bar'], ['foo', 'banana', 'bar']) match, and table.foo = 'banana'");
    tap.notOk(leibniz.smatch(['foo', 'foo?', 'bar'],
			     ['fub', 'banana', 'bar']),
	      "(['foo', 'foo?', 'bar'], ['fub', 'banana', 'bar']) do not match");
    tap.ok((function() {
	var table = leibniz.smatch(['X?', ['Y?', 4, "S", [4, 'Z?'], 9], 'W?'],
				   [3,    ['Q',  4, "S", [4,  7],   9], 'C']);
	return table != null && 
	    table.X && table.X === 3 &&
	    table.Y && table.Y === 'Q' &&
	    table.Z && table.Z === 7 &&
	    table.W && table.W === 'C';
    })(), "(['X?',['Y?',4,'S',[4,'Z?'],9],'W?'], [3,['Q',4,'S',[4, 7],9],'C']) match, X,Y,Z,W=3,Q,7,C");
	   

    tap.end();
});

// tryRule

tap.test('diffPowerRule', function (tap) {
    var expr = ['DERIV', ['^', 'X', 3], 'X'];
    var A = 3;
    var B = ['^', 'X', 2];
    var C = ['DERIV', 'X', 'X'];
    var result = leibniz.tryRule(leibniz.diffPowerRule, expr);
    var truths = [
	['*', ['*', A, B], C],
	['*', ['*', B, A], C],
	['*', C, ['*', A, B]],
	['*', C, ['*', B, A]],

	['*', ['*', A, C], B],
	['*', ['*', C, A], B],
	['*', B, ['*', A, C]],
	['*', B, ['*', C, A]],

	['*', ['*', B, C], A],
	['*', ['*', C, B], A],
	['*', A, ['*', B, C]],
	['*', A, ['*', C, B]]
    ];
    tap.oneOf(result, truths, "DERIV(X^3, X)");
    tap.notOk(leibniz.tryRule(leibniz.diffPowerRule, ['DERIV', ['^', 'X', 'Y'], 'X']), "DERIV(X^Y, X)");
    tap.notOk(leibniz.tryRule(leibniz.diffPowerRule, ['^', 'X', 3]), "X^3");
    tap.end();
});

tap.test('diffXRule', function (tap) {
    tap.equals(leibniz.tryRule(leibniz.diffXRule, ['DERIV','X','X']), 1, "DERIV(X, X)");
    tap.equals(leibniz.tryRule(leibniz.diffXRule, ['DERIV','X','Y']), null, "DERIV(X, Y)");
    tap.end();
});

tap.test('diffSumRule', function (tap) {
    var expr = ['DERIV', ['+', 'X', ['*', 2, 'X']], 'X'];
    var result = leibniz.tryRule(leibniz.diffSumRule, expr);
    var truths = [
	['+', ['DERIV', 'X', 'X'], ['DERIV', ['*', 2, 'X'], 'X']],
	['+', ['DERIV', ['*', 2, 'X'], 'X'], ['DERIV', 'X', 'X']]
    ];
    tap.oneOf(result, truths, "DERIV(X+2*X, X)");
    tap.notOk(leibniz.tryRule(leibniz.diffSumRule, ['+', 'X', ['*', 2, 'X']]), "X+2*X");
    tap.end();
});


tap.test('diffConstRule', function (tap) {
    tap.equals(leibniz.tryRule(leibniz.diffConstRule, ['DERIV', 5,'X']), 0, "DERIV(5, X)");
    tap.equals(leibniz.tryRule(leibniz.diffConstRule, ['DERIV','Y','X']), 0, "DERIV(Y, X)");
    tap.equals(leibniz.tryRule(leibniz.diffConstRule, ['DERIV', ['+', 'Y', 'Z'] ,'X']), 0, 
	       "DERIV(Y+Z, X)");
    tap.equals(leibniz.tryRule(leibniz.diffConstRule, ['DERIV', ['+', 'Y', 'X'] ,'X']), null, 
	       "DERIV(Y+X, X)");
    tap.equals(leibniz.tryRule(leibniz.diffConstRule, ['+', 'X', 2]), null, "X+2");
    tap.end();
});

tap.test('diffProductRule', function (tap) {
    var expr = ['DERIV', ['*', 'Y', 'Z'], 'X'];
    var DZDX = ['DERIV', 'Z', 'X'];
    var DYDX = ['DERIV', 'Y', 'X'];
    var truths = [
	['+', ['*', 'Y', DZDX], ['*', 'Z', DYDX]],
	['+', ['*', 'Z', DYDX], ['*', 'Y', DZDX]],
	['+', ['*', DZDX, 'Y'], ['*', 'Z', DYDX]],
	['+', ['*', 'Z', DYDX], ['*', DZDX, 'Y']],

	['+', ['*', 'Y', DZDX], ['*', DYDX, 'Z']],
	['+', ['*', DYDX, 'Z'], ['*', 'Y', DZDX]],
	['+', ['*', DZDX, 'Y'], ['*', DYDX, 'Z']],
	['+', ['*', DYDX, 'Z'], ['*', DZDX, 'Y']]
    ];
    var result = leibniz.tryRule(leibniz.diffProductRule, expr);
    tap.oneOf(result, truths, "DERIV(Y*Z, X)");
    tap.notOk(leibniz.tryRule(leibniz.diffProductRule, ['*', 'Y', 'Z']), 
	      "Y*Z");
    tap.end();
});


tap.test('foldBinopRule', function (tap) {
    tap.equals(leibniz.tryRule(leibniz.foldBinopRule, ['+', 5, 2]), 7, "5 + 2");
    tap.equals(leibniz.tryRule(leibniz.foldBinopRule, ['+', 5, 'X']), null, "5 + X");
    tap.equals(leibniz.tryRule(leibniz.foldBinopRule, ['+', 3, -3]), 0, "3 + -3");
    tap.equals(leibniz.tryRule(leibniz.foldBinopRule, ['*', 3, 3]), 9, "3 * 3");
    tap.equals(leibniz.tryRule(leibniz.foldBinopRule, ['/', 9, 3]), 3, "9 / 3");
    tap.equals(leibniz.tryRule(leibniz.foldBinopRule, ['^', 3, 3]), 27, "3 ^ 3");
    tap.end();
});


tap.test('expt0Rule', function (tap) {
    tap.equals(leibniz.tryRule(leibniz.expt0Rule, ['^', 'X', 0]), 1, "X^0");
    tap.equals(leibniz.tryRule(leibniz.expt0Rule, ['^', ['+', 'X', 1], 0]), 1, "(X+1)^0");
    tap.equals(leibniz.tryRule(leibniz.expt0Rule, ['^', 'X', 1]), null, "X^1");
    tap.end();
});


tap.test('expt1Rule', function (tap) {
    tap.equals(leibniz.tryRule(leibniz.expt1Rule, ['^', 'X', 1]), 'X', "X^1");
    tap.deepEquals(leibniz.tryRule(leibniz.expt1Rule, ['^', ['+', 'X', 1], 1]), ['+', 'X', 1], 
		   "(X+1)^1");
    tap.equals(leibniz.tryRule(leibniz.expt1Rule, ['^', 'X', 0]), null, "X^0");
    tap.end();
});


tap.test('unityRule', function (tap) {
    tap.equals(leibniz.tryRule(leibniz.unityRule, ['*', 'X', 1]), 'X', "X*1");
    tap.equals(leibniz.tryRule(leibniz.unityRule, ['*', 1, 'X']), 'X', "1*X");
    tap.equals(leibniz.tryRule(leibniz.unityRule, ['+', 'X', 0]), 'X', "X+0");
    tap.equals(leibniz.tryRule(leibniz.unityRule, ['+', 0, 'X']), 'X', "0+x");
    tap.deepEquals(leibniz.tryRule(leibniz.unityRule, ['*', ['+', 'X', 1], 1]), ['+', 'X', 1], 
		   "(X+1)*1");
    tap.deepEquals(leibniz.tryRule(leibniz.unityRule, ['+', ['+', 'X', 1], 0]), ['+', 'X', 1], 
		   "(X+1)+0");
    tap.equals(leibniz.tryRule(leibniz.unityRule, ['*', 'X', 0]), null, "X*0");
    tap.equals(leibniz.tryRule(leibniz.unityRule, ['+', 'X', 1]), null, "X+1");
    tap.end();
});


tap.test('times0Rule', function (tap) {
    tap.equals(leibniz.tryRule(leibniz.times0Rule, ['*', 'X', 0]), 0, "X*0");
    tap.equals(leibniz.tryRule(leibniz.times0Rule, ['*', ['+', 'X', 1], 0]), 0, 
	       "(X+1)*0");
    tap.end();
});

tap.test('foldCoeff1Rule', function (tap) {
    var result = leibniz.tryRule(leibniz.foldCoeff1Rule, ['*', 3, ['*', 4, 'X']]);
    var truths = [
	['*', 12, 'X'],
	['*', 'X', 12]
    ];
    tap.oneOf(result, truths, "3*(4*X)");
    tap.equals(leibniz.tryRule(leibniz.foldCoeff1Rule, ['*', 3, ['*', 'Y', 'X']]), null, 
	       "3*(Y*X)");
    tap.end();
});


tap.test('tryAllRules', function (tap) {
    var expr = [ 'DERIV', [ '+', [ '^', 'x', 2 ], [ '*', 2, 'x' ] ], 'x' ];
    var result = leibniz.reduceExpr(expr);
    var truths = [
	['+', ['*', 2, 'x'], 2],
	['+', 2, ['*', 2, 'x']],
	['+', ['*', 'x', 2], 2],
	['+', 2, ['*', 'x', 2]],
    ];
    tap.oneOf(result, truths, "(x^2) + (2*x)");
    tap.end();
});
