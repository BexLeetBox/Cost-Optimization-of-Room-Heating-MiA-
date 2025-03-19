const canvas = new fabric.Canvas('canvas', {
    width: 800,
    height: 600,
    backgroundColor: '#f0f0f0'
});

// Define grid size for discretization
const gridSize = 50;

// Snap objects to grid when moved
canvas.on('object:moving', function(e) {
    let obj = e.target;
    obj.set({
        left: Math.round(obj.left / gridSize) * gridSize,
        top: Math.round(obj.top / gridSize) * gridSize
    });
});

// Function to add walls (black rectangles)
function addWall() {
    let wall = new fabric.Rect({
        left: 100, top: 100, width: 200, height: 20,
        fill: 'black', selectable: true
    });
    canvas.add(wall);
}

// Function to add windows (blue rectangles)
function addWindow() {
    let window = new fabric.Rect({
        left: 150, top: 150, width: 50, height: 20,
        fill: 'blue', selectable: true
    });
    canvas.add(window);
}

// Function to add heater oven (red circle)
function addOven() {
    let oven = new fabric.Circle({
        left: 200, top: 200, radius: 20,
        fill: 'red', selectable: true
    });
    canvas.add(oven);
}

// Function to export layout as JSON
function exportLayout() {
    let json = JSON.stringify(canvas.toJSON());
    console.log(json); // You can save this to a file later
}


function exportGridapJSON() {
    let nodes = [];
    let elements = [];
    
    canvas.forEachObject(obj => {
        if (obj.type === "rect") {
            // Extract all four corners of the rectangle
            const left = Math.round(obj.left / gridSize);
            const top = Math.round(obj.top / gridSize);
            const right = left + Math.round(obj.width / gridSize);
            const bottom = top + Math.round(obj.height / gridSize);
            
            // Add all four corners to nodes array
            const nodeIndices = [];
            nodeIndices.push(nodes.push([left, top]) - 1); // Top-left
            nodeIndices.push(nodes.push([right, top]) - 1); // Top-right
            nodeIndices.push(nodes.push([right, bottom]) - 1); // Bottom-right
            nodeIndices.push(nodes.push([left, bottom]) - 1); // Bottom-left
            
            if (obj.fill === "black") {
                elements.push({
                    "type": "quad",
                    "nodes": nodeIndices,
                    "label": "wall"
                });
            }
        }
        // Handle other object types (line, circle) similarly...
    });
    console.log(JSON.stringify({ nodes, elements }, null, 2))
    return JSON.stringify({ nodes, elements }, null, 2);
}


function exportGmsh() {
    let nodes = [];
    let elements = [];
    let nodeCounter = 1;
    let nodeMap = new Map(); // Store unique nodes and indices

    canvas.forEachObject(obj => {
        if (obj.type === "rect") {
            // Define four corners of the rectangle
            const left = Math.round(obj.left / gridSize);
            const top = Math.round(obj.top / gridSize);
            const right = left + Math.round(obj.width / gridSize);
            const bottom = top + Math.round(obj.height / gridSize);

            let corners = [
                [left, top],     // Top-left
                [right, top],    // Top-right
                [right, bottom], // Bottom-right
                [left, bottom]   // Bottom-left
            ];

            let cornerIndices = [];

            corners.forEach(corner => {
                let key = `${corner[0]},${corner[1]}`;
                if (!nodeMap.has(key)) {
                    nodeMap.set(key, nodeCounter);
                    nodes.push(`Point(${nodeCounter}) = {${corner[0]}, ${corner[1]}, 0, 1.0};`);
                    cornerIndices.push(nodeCounter);
                    nodeCounter++;
                } else {
                    cornerIndices.push(nodeMap.get(key));
                }
            });

            if (obj.fill === "black") {
                elements.push(`Line(${cornerIndices[0]}) = {${cornerIndices[0]}, ${cornerIndices[1]}};`);
                elements.push(`Line(${cornerIndices[1]}) = {${cornerIndices[1]}, ${cornerIndices[2]}};`);
                elements.push(`Line(${cornerIndices[2]}) = {${cornerIndices[2]}, ${cornerIndices[3]}};`);
                elements.push(`Line(${cornerIndices[3]}) = {${cornerIndices[3]}, ${cornerIndices[0]}};`);

                let lineLoopIndex = nodeCounter;
                elements.push(`Line Loop(${lineLoopIndex}) = {${cornerIndices[0]}, ${cornerIndices[1]}, ${cornerIndices[2]}, ${cornerIndices[3]}};`);
                nodeCounter++;

                let surfaceIndex = nodeCounter;
                elements.push(`Plane Surface(${surfaceIndex}) = {${lineLoopIndex}};`);
                nodeCounter++;
            }
        }
    });

    let gmshGeoContent = `// Auto-generated Gmsh geometry file\n` + nodes.join("\n") + "\n" + elements.join("\n");

    // Create the .geo file
    let geoBlob = new Blob([gmshGeoContent], { type: "text/plain" });
    let geoFileName = "layout.geo";
    let geoLink = document.createElement("a");
    geoLink.href = URL.createObjectURL(geoBlob);
    geoLink.download = geoFileName;
    document.body.appendChild(geoLink);
    geoLink.click();
    document.body.removeChild(geoLink);

    // (Optional) If running in an environment with Gmsh CLI installed, trigger conversion to .msh
   fetch('http://127.0.0.1:5000/convert-to-msh', {  // Ensure port 5000
    method: 'POST',
    body: JSON.stringify({ geoFile: "layout.geo" }),
    headers: { 'Content-Type': 'application/json' }
})
.then(response => response.json())
.then(data => {
    let mshLink = document.createElement("a");
    mshLink.href = "http://127.0.0.1:5000/download-msh";  // Correct port
    mshLink.download = "layout.msh";
    document.body.appendChild(mshLink);
    mshLink.click();
    document.body.removeChild(mshLink);
})
.catch(error => console.error("Error:", error));
}
