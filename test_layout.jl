using Gridap
using Gridap.Geometry
using GridapGmsh

msh_file = "outputs/layout.msh"
model = GmshDiscreteModel(msh_file)


# 1) Load the mesh into a Gridap model
model = DiscreteModelFromFile(msh_file)

# 2) Check basic info
cells = num_cells(model)
faces = num_faces(model)
println("Number of cells = $cells")
println("Number of faces = $faces")

Ω = Triangulation(model)
Γ = BoundaryTriangulation(model)

println("Built domain triangulation and boundary triangulation successfully!")

