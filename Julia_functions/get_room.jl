# TODO: Lage domene for alle rom

function get_room(Nx, Ny)
    h = (2π)/Nx
    print("Mesh size = $h")
    𝒯 = CartesianDiscreteModel((0,2π,0,2π),(Nx,Ny)) |> simplexify
    writevtk(𝒯,"model")
end