```julia
using TestImages
import KernelAbstractions

img1 = testimage("woman_blonde.tif")
floatimg = float.(img1)

outimg = similar(floatimg)
Δ = [0 1 0; 1 -4 1; 0 1 0;]

KernelAbstractions.@kernel function corr_kernel(out, inp, kern, offsets)
    x_idx, y_idx = KernelAbstractions.@index(Global, NTuple)

    out_T = eltype(out)

    if (1 <= x_idx <= size(out,1)) && (1 <= y_idx <= size(out,2))
        x_toff, y_toff = offsets

        # create our accumulator
        acc = zero(out_T)

        # iterate in column-major order for efficiency
        for y_off in -y_toff:1:y_toff, x_off in -x_toff:1:x_toff
            y_inpidx, x_inpidx = y_idx+y_off, x_idx+x_off
            if (1 <= y_inpidx <= size(inp,2)) && (1 <= x_inpidx <= size(inp,1))
                y_kernidx, x_kernidx = y_off+y_toff+1, x_off+x_toff+1
                acc += inp[x_inpidx, y_inpidx] * kern[x_kernidx, y_kernidx]
            end
        end
        out[x_idx, y_idx] = acc
    end
end

wait(corr_kernel(KernelAbstractions.CPU())(outimg, floatimg, Δ, (1,1); ndrange=size(floatimg), workgroupsize=(2,2)))
```julia
