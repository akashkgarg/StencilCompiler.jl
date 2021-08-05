import MacroTools: flatten, isexpr

macro stencil(expr)
    __stencil(expr)
end

function __stencil(expr)
    rule_exprs = flatten(expr)
    for (i, expr) in enumerate(rule_exprs.args)
        if isexpr(expr) && expr.head == :(=)
            println("lhs = $(expr.args[1]), rhs = $(expr.args[2])")
        end
    end
    return MacroTools.block(rule_exprs)
end
