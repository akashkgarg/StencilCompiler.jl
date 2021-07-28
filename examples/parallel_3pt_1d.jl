# 1D jacobi style stencil computation in an iterative stencil loop, parallel
# version with a halo/ghost cells

using TiledIteration

function iterate(dst::Array{T,1}, src::Array{T,1}, alpha::T, beta::T) where T
    tilesize = Threads.nthreads() - 1
    indices = TileIterator(axes(src), RelaxLastTile((tilesize,)))
    for i in indices
        for j in first(i)
            if j == 1 || j == length(src)
                dst[j] = src[j]
            else
                dst[j] = alpha*src[j] + beta*(dst[j-1] + dst[j+1])
            end
        end
    end
end

function compute(t::Int, N::Int)
    src_idx = Ref(1)
    dst_idx = Ref(2)
    data = [rand(N), zeros(N)]
    for t in 1:t
        iterate(data[dst_idx[]], data[src_idx[]], 1/3, 1/3)

        # swap
        tmp = dst_idx[]
        dst_idx[] = src_idx[]
        src_idx[] = tmp[]
    end
    return data[dst_idx[]]
end


# 3pt parallel stencil with time slicing with redundant computation on T timesteps. Barrier synchronziation
# happens at hte end of T timesteps until final desired T timesteps is reached.

stencil = [CartesianIndex(-1), CartesianIndex(0), CartesianIndex(1)]
coeffs = [1/3, 1/3, 1/3]

function stencilfunc!(dst, src, coord, stencil, coeffs)
    lower_bound = first(CartesianIndices(src))
    upper_bound = last(CartesianIndices(src))
    if coord == lower_bound || coord == upper_bound
        dst[coord] = src[coord]
        return nothing
    end

    val = 0
    for (s,c) in zip(stencil, coeffs)
        I = coord + s
        val += c * src[I]
    end
    dst[coord] = val
    return nothing
end

function compute(t::Int, N::Int)
    src_idx = Ref(1)
    dst_idx = Ref(2)
    data = [rand(N), zeros(N)]
    println(data[src_idx[]])
    for t in 1:t
        for I in CartesianIndices(data[src_idx[]])
            stencilfunc!(data[dst_idx[]], data[src_idx[]], I, stencil, coeffs)
        end
        # swap
        tmp = dst_idx[]
        dst_idx[] = src_idx[]
        src_idx[] = tmp[]
    end
    return data[dst_idx[]]
end
