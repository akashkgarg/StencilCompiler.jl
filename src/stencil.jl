import MacroTools: flatten, isexpr

struct StencilRules
    grid::Grid

    boundaries::Dict{UnitRange, Function}

    # a stencil is is a tuple of index offsets and corresponding coefficients.
    stencil::Tuple{CartesianIndices, Array{Float64, 1}}
end

macro stencil(expr)
    __stencil(expr)
end

function get_grid_symbol(exprs)
    for (i, expr) in enumerate(exprs)
        if expr.head == :(=)
            lhs = expr.args[1]
            if lhs.head == :ref
                return lhs.args[1]
            end
        end
    end
    return nothing
end

function __stencil(expr)
    rule_exprs = filter(isexpr, flatten(expr).args)
    grid_sym = get_grid_symbol(rule_exprs)
    for (i, expr) in enumerate(rule_exprs)
        if expr.head == :(=)
            println("lhs = $(expr.args[1]), rhs = $(expr.args[2])")
        end
    end
    return StencilRules(grid_sym, {}, {})
end


S = @stencil begin
       G[1] = G[i]
       G[end] = G[i]
       otherwise = 1/3 * (G[i-1] + G[i] + G[i+1])
       end
