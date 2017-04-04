var parse=require("./parse.js");
var leibniz=require("./leibniz.js");
var unparse=require("./unparse.js");


// var expr = ['DERIV', ['+', ['^', ['+', ['*',7,'X'], 5], 3], ['*', 2, 'X']], 'X'];
//var expr = ['DERIV', ['+', ['^', ['+','X', 5], 3], ['*', 2, 'X']], 'X'];
// XXX var expr = parse.parseString("DERIV((X + 5)^3 + 2*X, X)");

// var expr = parse.parseString("DERIV((X + 5)^3 + 2*X, X)");
// console.log(unparse.unparse(expr));
// //console.log(expr);
// var newExpr = leibniz.reduceExpr(expr);
// console.log(unparse.unparse(newExpr));

var testExprs = [
    "DERIV(x^3 + 3,x)",
    "DERIV(X^4,X)",
    "DERIV(X^2 + 2*X,X)",
    "DERIV(27,X)",
    "DERIV(X*(X+1),X)",
    "(5 + X)^0",
    "(5 + X)^1",
    "(5 + X)*0",
    "0*(5 + X)",
    "2 + 3",
    "2 * 3",
    "2 - 3",
    "2 ^ 3",
    "DERIV(3*X^3 + 2*X^2 + 7,X)",
    "DERIV(x^2 + 2*x,x)", //  ['+', ['^', 'x', 2], ['*', 2, 'x']]
//    "DERIV(3*X^3 - 2*X^2 + 7,X)",
//    "DERIV((X-3)/X^2,X)"
];

testExprs.forEach(function(expr) {
    console.log("===============");
    var infix = parse.parseString(expr);
    console.log(infix);
    console.log("> " + expr);
    var newExpr = leibniz.reduceExpr(infix);
    console.log(unparse.unparse(newExpr));
});
    
