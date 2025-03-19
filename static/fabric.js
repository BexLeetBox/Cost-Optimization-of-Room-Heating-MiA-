let polygonMode = false;
let polygonPoints = [];
let tempCircles = [];  // to visualize clicked points
let firstPoint = null;

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



function startPolygonMode() {
  polygonMode = true;
  polygonPoints = [];
  tempCircles.forEach(c => canvas.remove(c));
  tempCircles = [];
  firstPoint = null;
}

function finishPolygon() {
  if (polygonPoints.length < 3) {
    alert("Need at least 3 points to form a polygon!");
    return;
  }

  polygonMode = false;

  // Convert array [ {x: number, y: number}, ... ] to polygon
  // Make a 'wall' style polygon (black fill, or black stroke)
  let polygon = new fabric.Polygon(polygonPoints, {
    fill: 'black',
    selectable: true,
    objectCaching: false  // optional
  });

  canvas.add(polygon);

  // Clear temp data
  polygonPoints = [];
  tempCircles.forEach(c => canvas.remove(c));
  tempCircles = [];
  firstPoint = null;

  canvas.renderAll();
}

canvas.on('mouse:down', function (opt) {
  if (!polygonMode) return;  // Only do this if we're drawing a polygon

  let pointer = canvas.getPointer(opt.e);
  // Snap to grid if desired
  let x = Math.round(pointer.x / gridSize) * gridSize;
  let y = Math.round(pointer.y / gridSize) * gridSize;

  // If no first point yet, define it
  if (!firstPoint) {
    firstPoint = { x, y };
    polygonPoints.push(firstPoint);
    drawTempCircle(x, y);
    return;
  }

  // Check if we are close to the first point -> close polygon
  let dist = distance(x, y, firstPoint.x, firstPoint.y);
  let threshold = 10; // px threshold to snap/close
  if (dist < threshold && polygonPoints.length > 2) {
    // automatically finish polygon
    finishPolygon();
  } else {
    // Otherwise add new point
    let newPoint = { x, y };
    polygonPoints.push(newPoint);
    drawTempCircle(x, y);
  }
});


function drawTempCircle(x, y) {
  let circle = new fabric.Circle({
    left: x - 3,
    top: y - 3,
    radius: 3,
    fill: 'red',
    selectable: false,
    evented: false
  });
  tempCircles.push(circle);
  canvas.add(circle);
}

function distance(x1, y1, x2, y2) {
  return Math.sqrt((x1 - x2)**2 + (y1 - y2)**2);
}

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
    let nodeMap = new Map(); // Store unique points
    let lines = [];
    let lineLoops = [];
    let nodeCounter = 1;
    let lineCounter = 1;

    canvas.forEachObject(obj => {
        if (obj.type === "rect") {
            const left = Math.round(obj.left / gridSize);
            const top = Math.round(obj.top / gridSize);
            const right = left + Math.round(obj.width / gridSize);
            const bottom = top + Math.round(obj.height / gridSize);

            let corners = [
                [left, top], [right, top],
                [right, bottom], [left, bottom]
            ];

            let cornerIndices = [];

            // Assign unique IDs to points
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

            // Ensure valid lines and unique IDs
            lines.push(`Line(${lineCounter}) = {${cornerIndices[0]}, ${cornerIndices[1]}};`);
            lines.push(`Line(${lineCounter + 1}) = {${cornerIndices[1]}, ${cornerIndices[2]}};`);
            lines.push(`Line(${lineCounter + 2}) = {${cornerIndices[2]}, ${cornerIndices[3]}};`);
            lines.push(`Line(${lineCounter + 3}) = {${cornerIndices[3]}, ${cornerIndices[0]}};`);

            let loopIndex = lineCounter + 4;
            lineLoops.push(`Line Loop(${loopIndex}) = {${lineCounter}, ${lineCounter + 1}, ${lineCounter + 2}, ${lineCounter + 3}};`);
            let surfaceIndex = loopIndex + 1;
            lineLoops.push(`Plane Surface(${surfaceIndex}) = {${loopIndex}};`);

            lineCounter += 5;
        }
    });

    let gmshGeoContent = `// Auto-generated Gmsh geometry file\n` + nodes.join("\n") + "\n" + lines.join("\n") + "\n" + lineLoops.join("\n");

    // Send the .geo content to Flask
    fetch("http://127.0.0.1:5000/convert-to-msh", {
        method: "POST",
        body: JSON.stringify({ geoContent: gmshGeoContent, geoFile: "layout.geo" }),
        headers: { "Content-Type": "application/json" }
    })
    .then(response => response.json())
    .then(data => {
        if (data.error) {
            console.error("❌ Error:", data.error);
        } else {
            let mshLink = document.createElement("a");
            mshLink.href = "http://127.0.0.1:5000/download-msh";
            mshLink.download = "layout.msh";
            document.body.appendChild(mshLink);
            mshLink.click();
            document.body.removeChild(mshLink);
        }
    })
    .catch(error => console.error("❌ Fetch Error:", error));
}
