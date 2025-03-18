using Gridap
using Gridap.ReferenceFEs  # Required for QUAD, SEGMENT, VERTEX
using JSON3

# Define reference finite elements with correct constants
const QUAD4 = lagrangian(QUAD, 1)     # Quadrilateral (order 1)
const LINE2 = lagrangian(SEGMENT, 1)  # Line segment (order 1)
const VERTEX_FE = lagrangian(VERTEX, 0) # Vertex/point (order 0)

function load_gridap_json(filename)
    json_data = JSON3.read(read(filename, String))

    nodes = json_data["nodes"]
    elements = json_data["elements"]

    # Convert nodes to Gridap Point objects
    points = [Point(node...) for node in nodes]
    num_nodes = length(points)

    println("Loaded $(num_nodes) nodes.")

    # Validate elements (ensure 0-based JSON indices are valid)
    for elem in elements
        elem_nodes = elem["nodes"]
        for node_id in elem_nodes
            if node_id >= num_nodes
                error("Invalid node index $node_id (max is $(num_nodes-1)).")
            end
        end
    end
    println("All elements validated.")

    # Map JSON element types to Gridap reference FEs
    cell_types = Dict(
        "quad" => QUAD4,
        "line" => LINE2,
        "vertex" => VERTEX_FE
    )

    # Prepare cell data (convert to 1-based indices)
    cell_types_list = []
    cells = []
    for elem in elements
        elem_type = elem["type"]
        elem_nodes = elem["nodes"]
        
        if !haskey(cell_types, elem_type)
            error("Unsupported element type: $elem_type")
        end
        
        elem_indices = Tuple(n + 1 for n in elem_nodes)  # Julia uses 1-based indexing
        push!(cells, elem_indices)
        push!(cell_types_list, cell_types[elem_type])
    end

    # Build the discrete model
    model = DiscreteModel(points, cells, cell_types_list)
    return model
end

# Load and export
model = load_gridap_json("house_layout.json")
writevtk(model, "gridap_output")
println("VTK export successful.")