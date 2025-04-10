let polygonMode = false;
let polygonPoints = [];
let tempCircles = [];  // to visualize clicked points
let firstPoint = null;
let windowMode = false;

const gridSize = 50;         // Size of the grid cells
let hoverCircle = null;      // Circle for the hover highlight
let snapToGrid = true;

const canvas = new fabric.Canvas('canvas', {
  width: 800,
  height: 600,
  backgroundColor: '#f0f0f0'
});



function addWindowMode() {
  // Switch into "Add Window" mode
  windowMode = true;
  console.log("Window mode enabled. Click a polygon corner to place a window.");
}

function findNearestPolygonCorner(x, y, threshold = 20) {
  let minDist = Infinity;
  let bestCorner = null;

  canvas.forEachObject(obj => {
    if (obj.type === "polygon") {
      let corners = getPolygonCorners(obj);
      for (let c of corners) {
        let dist = distance(x, y, c.x, c.y);
        if (dist < minDist) {
          minDist = dist;
          bestCorner = c;
        }
      }
    }
  });

  // If closest corner is within threshold, return it
  if (bestCorner && minDist < threshold) {
    return bestCorner;
  } else {
    return null;
  }
}

// Euclidean distance
function distance(x1, y1, x2, y2) {
  return Math.sqrt((x1 - x2)**2 + (y1 - y2)**2);
}

canvas.on('mouse:down', function (event) {
  if (!windowMode) return;  // Only do this if user is placing a window

  let pointer = canvas.getPointer(event.e);
  let mx = pointer.x, my = pointer.y;

  console.log(mx, my)

  // Find a polygon corner within 20px
  let corner = findNearestPolygonCorner(mx, my, 20);
  if (corner) {
    // Place a small "window" rect
    let windowRect = new fabric.Rect({
      left: corner.x - 25,   // center the window if you want
      top: corner.y - 10,
      width: 50,
      height: 20,
      fill: 'blue'
    });
    canvas.add(windowRect);
    // Turn off window mode if you only want one
    windowMode = false;
    console.log("Placed window at corner:", corner);
  } else {
    console.log("No nearby corner found.");
  }
});


function getPolygonCorners(polygon) {
  // Get the transform matrix for this object
  let matrix = polygon.calcTransformMatrix();
  let corners = [];

  for (let pt of polygon.points) {
    // 'pt' is local coords
    let localPoint = new fabric.Point(pt.x, pt.y);
    // transform to absolute
    let absPoint = fabric.util.transformPoint(localPoint, matrix);
    corners.push({ x: absPoint.x, y: absPoint.y });
  }
  
  console.log("Transformed corners =>", corners);
  return corners;
}


function toggleSnap() {
      snapToGrid = !snapToGrid;
    }






canvas.on('mouse:move', function(event) {
      let pointer = canvas.getPointer(event.e);
      let x = pointer.x;
      let y = pointer.y;

      // If snapping is enabled, round to nearest grid intersection
      if (snapToGrid) {
        x = Math.round(x / gridSize) * gridSize;
        y = Math.round(y / gridSize) * gridSize;
      }

      // If we haven't created the hover circle yet, create it now
      if (!hoverCircle) {
        hoverCircle = new fabric.Circle({
          left: x - 5,
          top: y - 5,
          radius: 5,
          fill: 'rgba(255, 0, 0, 0.5)',
          selectable: false,
          evented: false
        });
        canvas.add(hoverCircle);
      } else {
        // Move the existing circle
        hoverCircle.set({ left: x - 5, top: y - 5 });
      }

      hoverCircle.setCoords();
      canvas.renderAll();
    });



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
    fill: 'transparent',
    stroke: 'black',
    strokeWidth: 2,
    selectable: true,
    objectCaching: false
  });
    polygon.set('name', 'Wall');
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
  // Data structures for storing unique geometry
  let nodes = [];
  let nodeMap = new Map(); // Maps "x,y" -> pointID
  let lines = [];
  let lineLoops = [];
  let nodeCounter = 1;  // Unique ID for "Point()"
  let lineCounter = 1;  // Unique ID for "Line()"

  // Iterate over all objects in the Fabric.js canvas
  canvas.forEachObject(obj => {

    // ======================
    // 1) RECTANGLE EXPORT
    // ======================
    if (obj.type === "rect") {
      const left = Math.round(obj.left / gridSize);
      const top = Math.round(obj.top / gridSize);
      const right = left + Math.round(obj.width / gridSize);
      const bottom = top + Math.round(obj.height / gridSize);

      // Four corners
      let corners = [
        [left, top],
        [right, top],
        [right, bottom],
        [left, bottom]
      ];

      // Convert each corner to a unique point ID
      let cornerIndices = [];
      corners.forEach(([x, y]) => {
        let key = `${x},${y}`;
        if (!nodeMap.has(key)) {
          nodeMap.set(key, nodeCounter);
          nodes.push(`Point(${nodeCounter}) = {${x}, ${y}, 0, 1.0};`);
          cornerIndices.push(nodeCounter);
          nodeCounter++;
        } else {
          cornerIndices.push(nodeMap.get(key));
        }
      });

      // Create 4 lines for the rectangle edges
      lines.push(`Line(${lineCounter}) = {${cornerIndices[0]}, ${cornerIndices[1]}};`);
      lines.push(`Line(${lineCounter + 1}) = {${cornerIndices[1]}, ${cornerIndices[2]}};`);
      lines.push(`Line(${lineCounter + 2}) = {${cornerIndices[2]}, ${cornerIndices[3]}};`);
      lines.push(`Line(${lineCounter + 3}) = {${cornerIndices[3]}, ${cornerIndices[0]}};`);

      // Make a line loop + plane surface
      let loopIndex = lineCounter + 4;
      lineLoops.push(`Line Loop(${loopIndex}) = {${lineCounter}, ${lineCounter + 1}, ${lineCounter + 2}, ${lineCounter + 3}};`);
      let surfaceIndex = loopIndex + 1;
      lineLoops.push(`Plane Surface(${surfaceIndex}) = {${loopIndex}};`);

      // Increment lineCounter to avoid ID collisions
      lineCounter += 5;
    }

    // =====================
    // 2) POLYGON EXPORT
    // =====================
    else if (obj.type === "polygon") {
      // We'll assume no rotation or scaling
      // If your polygons are transformed, use obj.calcTransformMatrix() or other transformations.

      // Fabric polygon points are local coords, top-left is (obj.left, obj.top)
      // We'll shift them to canvas coords and then snap to the grid.
      let offsetX = Math.round(obj.left);
      let offsetY = Math.round(obj.top);

      let poly = obj; // a fabric.Polygon
      let absPoints = [];

      // Convert from local polygon coords to absolute canvas coords
      for (const pt of poly.points) {
        let x = Math.round((pt.x + offsetX) / gridSize) * gridSize;
        let y = Math.round((pt.y + offsetY) / gridSize) * gridSize;
        absPoints.push({ x, y });
      }

      // Assign unique IDs to the polygon corners
      let cornerIndices = [];
      for (let { x, y } of absPoints) {
        let key = `${x},${y}`;
        if (!nodeMap.has(key)) {
          nodeMap.set(key, nodeCounter);
          nodes.push(`Point(${nodeCounter}) = {${x}, ${y}, 0, 1.0};`);
          cornerIndices.push(nodeCounter);
          nodeCounter++;
        } else {
          cornerIndices.push(nodeMap.get(key));
        }
      }

      // Create Lines between consecutive points + close the loop
      let localLineIds = [];
      for (let i = 0; i < cornerIndices.length; i++) {
        let start = cornerIndices[i];
        let end = cornerIndices[(i + 1) % cornerIndices.length]; // wrap to first
        // Ensure we don't create degenerate lines (start != end)
        if (start === end) continue;

        lines.push(`Line(${lineCounter}) = {${start}, ${end}};`);
        localLineIds.push(lineCounter);
        lineCounter++;
      }

      // If we have at least 3 edges, create a line loop + plane surface
      if (localLineIds.length >= 3) {
        let loopIndex = lineCounter;
        lineLoops.push(`Line Loop(${loopIndex}) = {${localLineIds.join(", ")}};`);
        let surfaceIndex = loopIndex + 1;
        lineLoops.push(`Plane Surface(${surfaceIndex}) = {${loopIndex}};`);
        lineCounter += 2;
      }
    }

    // You could else-if other shapes (circles, etc.)
  });

  // ===========================
  // 3) Construct .geo File
  // ===========================
  let gmshGeoContent =
    `// Auto-generated Gmsh geometry file\n`
    + nodes.join("\n") + "\n"
    + lines.join("\n") + "\n"
    + lineLoops.join("\n");

  // ===========================
  // 4) Send to Flask
  // ===========================
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
        // Download the .msh file automatically
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
