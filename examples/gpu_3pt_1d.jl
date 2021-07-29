using KernelAbstractions

@kernel function stencilfunc!(dst, src, radius, alpha, beta)
    i = @index(Global, NTuple)

    N = length(src)
    if i > radius && i < radius - N
        val = alpha * src[i]
        for r in 1:radius
            val = val + beta * (src[i - r] + src[i + r])
        end
        dst[i] = val
    end
end

src = CUDA.rand(10)
dst = copy(src)

stencilcompute = stencilfunc!(CPU(), Threads.nthreads())
stencilcompute = stencilfunc!(CUDADevice(), 256)

stencilcompute(dst, src, 3, 1/3, 1/3, ndrange=size(dst))
