# Stencil DSL

There are two main components we need to define for Stencil computations: 
1. the grid/domain that we will be performing the computation on
2. the shape of the stencil operations on that grid

## Proposed Syntax

For a 1D example, we might want something like this: 
```julia
G = @grid 1:10, 64 
@stencil begin 
    1 = G[0]
    end = G[0]
    [2:end-1] = 1/3 * (G[-1] + G[0] + G[1])
end
```
@grid will define the spatial extents and temporal extents for the
computation. 

```julia
G = @grid (1:10,1:10), 64
@stencil (1,:) = G[1]
@stencil 10 
```
