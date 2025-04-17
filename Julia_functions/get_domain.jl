function get_room(json_file)
    # Parse JSON-filen
    data = JSON3.read(json_file)
    
    # Hent ut høyde og bredde
    width = data["room"]["width"]
    height = data["room"]["height"]

    # Hent ut alle vindus- og dørkoordinater
    windows = []
    doors = []

    for boundary in data["boundaries"]
        for section in boundary["sections"]
            if section["type"] == "Window"
                if haskey(section, "x1") && haskey(section, "x2")
                    push!(windows, (section["x1"], section["x2"], boundary["name"]))
                end
                if haskey(section, "y1") && haskey(section, "y2")
                    push!(windows, (section["y1"], section["y2"], boundary["name"]))
                end
            elseif section["type"] == "Door"
                if haskey(section, "x1") && haskey(section, "x2")
                    push!(doors, (section["x1"], section["x2"], boundary["name"]))
                end
                if haskey(section, "y1") && haskey(section, "y2")
                    push!(doors, (section["y1"], section["y2"], boundary["name"]))
                end
            end
        end
    end

    # Hent oppvarmingselementer
    heating_elem = [[elem["x1"], elem["x2"], elem["y1"], elem["y2"]] for elem in data["heatingElements"]]

    return width, height, windows, doors, heating_elem
end


function mark_nodes(f,model::DiscreteModel)
    topo   = get_grid_topology(model)
    coords = get_vertex_coordinates(topo)
    mask = map(f,coords)
    return mask
  end
  function update_labels!(e::Integer,model::CartesianDiscreteModel,f_Γ::Function,name::String)
      mask = mark_nodes(f_Γ,model)
      _update_labels_locally!(e,model,mask,name)
      nothing
  end
  function _update_labels_locally!(e,model::CartesianDiscreteModel{2},mask,name)
    topo   = get_grid_topology(model)
    labels = get_face_labeling(model)
    cell_to_entity = labels.d_to_dface_to_entity[end]
    entity = maximum(cell_to_entity) + e
    # Vertices
    vtxs_Γ = findall(mask)
    vtx_edge_connectivity = Array(get_faces(topo,0,1)[vtxs_Γ])
    # Edges
    edge_entries = [findall(x->any(x .∈  vtx_edge_connectivity[1:end.!=j]),
      vtx_edge_connectivity[j]) for j = 1:length(vtx_edge_connectivity)]
    edge_Γ = unique(reduce(vcat,getindex.(vtx_edge_connectivity,edge_entries),init=[]))
    labels.d_to_dface_to_entity[1][vtxs_Γ] .= entity
    labels.d_to_dface_to_entity[2][edge_Γ] .= entity
    add_tag!(labels,name,[entity])
    return cell_to_entity
  end

  function generate_f_Γ(bound, width, height)
    return function (x)
        any(
            (b[3] == "Top"    && (b[1] ≤ x[1] ≤ b[2]) && (x[2] ≈ height)) ||
            (b[3] == "Bottom" && (b[1] ≤ x[1] ≤ b[2]) && (x[2] ≈ 0)) ||
            (b[3] == "Left"   && (b[1] ≤ x[2] ≤ b[2]) && (x[1] ≈ 0)) ||
            (b[3] == "Right"  && (b[1] ≤ x[2] ≤ b[2]) && (x[1] ≈ width))
            for b in bound
        )
    end
end

function heating_elements(heating_elem)
    return function (x) sum(χ(x[1], elem[1], elem[2]) * χ(x[2], elem[3], elem[4]) for elem in heating_elem) end
end