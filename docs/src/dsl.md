# Stencil DSL

There are two main components we need to define for Stencil computations: 
1. the grid/domain that we will be performing the computation on
2. the shape of the stencil operations on that grid

## Proposed Syntax

For a 1D example, we might want something like this: 
```julia
G = @grid 1:10, 64 
S = @stencil begin 
    1 = G[0]
    end = G[end]
    [2:end-1] = 1/3 * (G[-1] + G[0] + G[1])
end
```
`@grid` will define the spatial extents and temporal extents for the
computation. The `@stencil` macro defines the computational expressions
for each element in the Grid. Note that references to Grid are relative
to offset `0`, which indicates the current grid cell; this offsetting can 
be used to define stencils and coefficients. In this example we have 
constant boundaries and a 3-point stencil with weights 1/3 each. 

Multi-dimensional grids can be defined similarly:
```julia
G = @grid (1:10,1:10), 64
S = @stencil begin
    [:, 1] = 0
    [:, end] = 0
    [1, :] = 0
    [end, :] = 0
    [2:end-1, 2:end-1] = -4*G[0,0] + 1*(G[1,0] + G[-1,0] + G[0,1] + G[0, -1])
end
```
Here we have defined a 2-dimensional 10x10 grid with constant boundary
conditions and a Laplacian stencil.

Once the grid and stencil are defined, we can generate a native julia function
that performs the stencil computation: 
```julia
compute = generate_function(G, S, MultiThreadedCPU)
```

The `generate_function` accepts the grid, the stencil rules, and a strategy to
optimize the resulting function. Some options might include: 
```
None - No code transformations are done.
CPU - optimize for single-threaded CPU 
MultiThreadedCPU - optimize for multi-threaded CPU
GPU - optimize for GPU
MultiGPU - optimize for multi-threaded GPU
```
