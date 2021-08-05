# Stencil DSL

There are two main components we need to define for Stencil computations: 
1. the grid/domain that we will be performing the computation on
2. the shape of the stencil operations on that grid

## Proposed Syntax

For a 1D example, we might want something like this: 
```julia
G = Grid(1:10, 64)
S = @stencil begin 
    G[1] = G[i]
    G[end] = G[i]
    otherwise = 1/3 * (G[i-1] + G[i] + G[i+1])
end
```
`Grid` will define the spatial extents and temporal extents for the
computation. The `@stencil` macro defines the computational expressions
for each element in the Grid. The LHS of the stencil expressions define the
exact coordinates in the grid and the RHS defines the actual computational rule
for that coordinate. Note that the RHS can use aux variables like `i` as an
indicator of current location in the stencil. The `otherwise` keyword can be
used to define a stencil rule for all coordinates not explicitly defined by any
other stencil rules. The `otherwise` statement must come last. In this example we have 
constant boundaries and a 3-point stencil with weights 1/3 each. 

Multi-dimensional grids can be defined similarly:
```julia
G = Grid(1:10,1:10), 64
S = @stencil begin
    G[:, 1] = 0
    G[:, end] = 0
    G[1, :] = 0
    G[end, :] = 0
    G[5,5] = 10
    otherwise = -4*G[i,j] + 1*(G[i+1,j] + G[i-1,j] + G[i,j+1] + G[i, j-1])
end
```
Here we have defined a 2-dimensional 10x10 grid with constant boundary
conditions and a Laplacian stencil. We also have a "source" in the middle of the
grid. 

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
