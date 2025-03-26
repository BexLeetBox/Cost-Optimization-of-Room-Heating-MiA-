using JSON3

function get_room(json_file)
    # Parse JSON-filen
    data = JSON3.read(json_file)
    
    # Hent ut høyde og bredde
    width = data["room"]["width"]
    height = data["room"]["height"]

    # Hent ut alle vinduskoordinater
    windows = []
    doors = []

    for boundary in data["boundaries"]
        for section in boundary["sections"]
            if section["type"] == "Window"
                push!(windows, (section["x1"], section["x2"], boundary["name"]))
            elseif section["type"] == "Door"
                push!(doors, (section["y1"], section["y2"], boundary["name"]))
            end
        end
    end

    return width, height, windows, doors
end
