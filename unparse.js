function unparse(expr) {
    function binaryPrecedenceCompare(op1, op2) { // compares precedecnce of binary infix operators
        var prec = {
            '+' : 0, '-' : 0,
            '*' : 1, '/' : 1,
            '^' : 2,
        };
        return prec[op1] - prec[op2];
    }
    
    function unaryPrecedenceCompare(op1, op2) {  // compares prededence of unary infox operators
        var prec = {
            '+' : 0, '-' : 0,
        };
        return prec[op1] - prec[op2];
    }
    
    function leftAssoc(op) {return op !== '^';}   // is binary operator left associative?
    function rightAssoc(op) {return op === '^';}  // is binary operator right associative?

    function binaryOpToString(op) {
        return (op === '-' || op === '+') ? (" " + op + " ") : op;
    }

    function toString(expr) {
        if (expr instanceof Array) {
            var op = expr[0];
            if (op === 'DERIV') {
                return 'DERIV(' + toString(expr[1]) + ', ' + toString(expr[2]) + ')';
            } else {
                var numArgs = expr.length - 1;
                if (numArgs === 1) {       // unary op
                    var arg = expr[1];
                    var useParentheses = 
                        arg instanceof Array &&
                        unaryPrecedenceCompare(op, arg[0]) < 0;
                    return op + (useParentheses ? "(" : "") +
                        toString(arg) + 
                        (useParentheses ? "(" : "");
                } else if (numArgs == 2) { // binary op
                    var leftExpr = expr[1];
                    var leftParenthesis = 
                        leftExpr instanceof Array &&
                        (binaryPrecedenceCompare(op, leftExpr[0]) > 0 ||
                         binaryPrecedenceCompare(op, leftExpr[0]) === 0 && rightAssoc(op));
                    var rightExpr = expr[2];
                    var rightParenthesis =
                        rightExpr instanceof Array &&
                        (binaryPrecedenceCompare(op, rightExpr[0]) > 0 ||
                         binaryPrecedenceCompare(op, rightExpr[0]) === 0 && leftAssoc(op));
                    return (leftParenthesis ? "(" : "") +
                        toString(leftExpr) + (leftParenthesis ? ")" : "") + binaryOpToString(op) +
                        (rightParenthesis ? "(" : "") +
                        toString(rightExpr) + (rightParenthesis ? ")" : "");
                } 
            }
        } else {
            return expr + "";
        }
    }

    return toString(expr);
}

if (typeof module !== 'undefined' && typeof module.exports !== 'undefined') {
    exports.unparse = unparse;
}
