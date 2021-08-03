# Performance

A few notes on computational efficiency when working with stencil computations:

## Simple Single Threaded Loop

The naive simplest form of a stencil computation over a regular grid domain is
implemented in a single loop with two buffers, a source buffer and destination
buffer. The source is used for reading values and the destination is written to.
At the end of the iteration, the roles of the source/destination buffers are
swapped avoiding un-necessary copies between timesteps and allocating new
buffers. Here is a simple implementation of such a scheme in Julia

```julia
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
```

## Parallel Execution

For large problems, it becomes important to utilize as much parallelization as
we can in order to increase performance. This is a well studied problem and
approaches typically lie in tiling the domain in space or in space-time. Ideally
we would compute each tile independently of one another, but the
complications arise near boundaries of the tiles since they introduce
dependencies among one another. Minimizing this synchronization is where most of
the benefit comes from when considering a parallel algorithm for stencil
computation.

### Space Tiling

A simple parallelization method of a stencil computation is to simply split the
domain spatially into tiles, where each tile can operate independently. A few
crucial points need to be addressed when tiling computations like this: 
1. What to do at tile boundaries? Stencils at the boundaries will overlap with
   adjacent tiles. We can add synchronization between tiles, but that reduces
   throughput. A popular approach is to "copy" the necessary data from
   neighboring tiles, called "ghost cells", such that each tile can operate
   truly indepdently of others.
2. How big do we make tiles? This is an involved question that depends on
   various factors. Some recent literature suggests that stencil operations are
   most affected by cache misses. The tile sizes should be to minimize such
   cache misses. Cache-Oblivious Algorithms are useful here. 
   
Once you have tiling in the spatial domain, computation still needs to be
synchronized at the end of the current timestep. This sort of barrier
synchronization at the end of each time-step can reduce throughput. Alternative
approaches involve tiling in both space and time. 

### Space-Time Tiling

It is generally impossible to remove some sort of synhronization between tiles,
but we can attempt to maximize throughput and minimize cache misses for each
tile. In general, we can assume that cache-misses and communicating data between
tiles are the things that slow us down. Instead of tiling through space alone,
there exist several known algorithms that operate over both space and time. 

A well known algorithm uses trapezoids in space-time for distributing workload.
Consider the 1D case below: 
```
x1 x2 x3 x4 x5
```

For a 3pt stencil, the computation for x3 depends on x2 and x4 at the beginning
of the timestep. After one timestep, we can compute new values for x2, x3 and x4.
```
   x2'x3'x4'
x1 x2 x3 x4 x5
```

Iterating another timestep, we can compute values for x3", but not for x2" and
x4" since they would depend on x1' and x5'.
```
      x3"
   x2'x3'x4'
x1 x2 x3 x4 x5
```

The trapezoidal shape of space-time computation performed here gives the
algorithms its name. We can split up the rest of the domain and each set of
space-time tiles can be scheduled in parallel. For example we x1-x5 and x6-x10
can be used to compute x3" and x8". 
```
      x3"            x8"
   x2'x3'x4'      x7'x8'x9'
x1 x2 x3 x4 x5 x6 x7 x8 x9 x10
```

As a second step, we can compute the remaining values by looking at the inverted
"trapezoids" and compute values for x1" x2" x4" x5" x6" x7" x9" and x10"; each
of these inverted trapezoids will reuse values already computed in the first
step. 

## Cache Oblivious Algorithms

## GPU Considerations

Certain backend stencil operations, e.g., when performing tiling on the GPU,
it's more efficient to have redundant computation to avoid copying values, which
requires a barrier synchronization. 
