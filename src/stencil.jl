import MacroTools: flatten, isexpr

struct Stencil{T}
    coords::CartesianIndices
    coeffs::Array{T, 1}
end

struct StencilRules{T}
    grid::Grid

    boundaries::Dict{UnitRange, Stencil{T}}

    # a stencil is is a tuple of index offsets and corresponding coefficients.
    stencil::Stencil{T}
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

# computes and returns the index for an expression like i+1, replacing i with 0
function get_index_from_symbolic_ref(expr)
    if expr isa Symbol
        return 0
    elseif expr isa Number
        return expr
    elseif isexpr(expr) && expr.head == :call
        op = expr.args[1]
        lhs = get_index_from_symbolic_ref(expr.args[2])
        rhs = get_index_from_symbolic_ref(expr.args[3])
        return eval(Expr(:call, op, lhs, rhs))
    end
end

function get_stencils(expr)
end

function __stencil(expr)
    rule_exprs = filter(isexpr, flatten(expr).args)
    grid_sym = get_grid_symbol(rule_exprs)
    for (i, expr) in enumerate(rule_exprs)
        if expr.head == :(=)
            println("lhs = $(expr.args[1]), rhs = $(expr.args[2])")
        end
    end
    return StencilRules{Float64}(grid_sym)
end


S = @stencil begin
       G[1] = G[i]
       G[end] = G[i]
       otherwise = 1/3 * (G[i-1] + G[i] + G[i+1])
       end
