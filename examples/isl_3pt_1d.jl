# 1D jacobi style stencil computation in an iterative stencil loop

function iterate(dst::Array{T,1}, src::Array{T,1}, alpha::T, beta::T) where T
    dst[1] = src[1]
    dst[end] = src[end]
    for i in 2:length(dst)-1
        dst[i] = alpha*src[i] + beta*(dst[i-1] + dst[i+1])
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
