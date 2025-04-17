function fetchEnergyPrices() {
  // Get the selected region code from the dropdown
  const regionSelect = document.getElementById("region-select");
  const regionCode = regionSelect.value;

  
  // Fetch energy prices with the selected region code
  fetch(`/energy-prices?region_code=${regionCode}`)
    .then((response) => response.json())
    .then((data) => {
      const display = document.getElementById("energy-prices");
      display.textContent = JSON.stringify(data, null, 2);
      display.style.display = "block";
    })
    .catch((error) => console.error("Error fetching energy prices:", error));
}

function fetchWeather() {
  const lat = document.getElementById("latitude").value;
  const lon = document.getElementById("longitude").value;

  if (!lat || !lon) {
    alert("Please enter both latitude and longitude.");
    return;
  }

  fetch(`/weather?lat=${lat}&lon=${lon}`)
    .then((response) => response.json())
    .then((data) => {
      const display = document.getElementById("weather-data");
      display.textContent = JSON.stringify(data, null, 2);
      display.style.display = "block";
    })
    .catch((error) => console.error("Error fetching weather data:", error));
}

function fetchMergedData() {
  const lat = document.getElementById("merged-latitude").value;
  const lon = document.getElementById("merged-longitude").value;
  const regionSelect = document.getElementById("region-select");
  const regionCode = regionSelect.value;

  console.log(regionCode)

  if (!lat || !lon) {
    alert("Please enter both latitude and longitude.");
    return;
  }

  fetch(`/merged-data?lat=${lat}&lon=${lon}&region_code=${regionCode}`)
    .then((response) => response.json())
    .then((data) => {
  const display = document.getElementById("merged-data");
  display.innerHTML = ""; // Clear previous content
  window.weatherEnergyData = data;
  data.forEach((entry) => {
    const card = document.createElement("div");
    card.className = "data-card";
    card.innerHTML = `
      <div><strong>Time:</strong> ${new Date(entry.time_start).toLocaleString()}</div>
      <div><strong>Temperature:</strong> ${entry.air_temperature.toFixed(2)} K</div>
      <div><strong>EUR/kWh:</strong> €${entry.EUR_per_kWh.toFixed(4)}</div>
      <div><strong>NOK/kWh:</strong> ${entry.NOK_per_kWh.toFixed(4)} kr</div>
    `;
    display.appendChild(card);
  });

  display.style.display = "block";
})

    .catch((error) => console.error("Error fetching merged data:", error));
}

function toggleDisplay(id) {
  const section = document.getElementById(id);
  const button = document.getElementById("toggleArrow");

  if (section.style.display === "none" || section.style.display === "") {
    section.style.display = "block";
    button.innerHTML = "▲ Hide Data";
  } else {
    section.style.display = "none";
    button.innerHTML = "▼ Show Data";
  }
}


function runSimulation() {
    document.getElementById("simulation-status").textContent = "Running simulation...";
    const boundaryData = exportToJson();

    fetch("/run-simulation", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            boundary: boundaryData,
            weatherEnergy: window.weatherEnergyData || null
        })
            })
    .then(res => res.json())
    .then(data => {
        if (data.status === "success") {
            document.getElementById("simulation-status").textContent = "Simulation complete. Result file: " + data.output;
        } else {
            document.getElementById("simulation-status").textContent = "Error: " + data.error;
        }
    })
    .catch(err => {
        document.getElementById("simulation-status").textContent = "Unexpected error: " + err;
    });
}

/**
 
//--------------------------------------------- Konva ------------------------------------------




 */

const container = document.getElementById('container');
const width = container.clientWidth;
const height = container.clientHeight-.15*container.clientHeight;
console.log(width, height)

const stage = new Konva.Stage({
    container: 'container',
    width: width,
    height: height,
});


const layer = new Konva.Layer();
stage.add(layer);

let mode = 'Wall';
let sectionStart = null;
let roomScale = 100;
let room;
let boundaries = [];
let heatingElements = [];
let heatingPreview = null;
let drawingHeating = false;
// Minimal pixel distance to create a section
const minSectionSize = 5;

function setMode(newMode) {
    mode = newMode;
    sectionStart = null;
}

function defineRoom() {
    let widthMeters = parseFloat(document.getElementById('roomWidth').value);
    let heightMeters = parseFloat(document.getElementById('roomHeight').value);
    let scaledWidth = widthMeters * roomScale;
    let scaledHeight = heightMeters * roomScale;
    const roomWidth = parseFloat(document.getElementById('roomWidth').value);
    const roomHeight = parseFloat(document.getElementById('roomHeight').value);


    stage.width(roomWidth * 100 + 100);
    stage.height(roomHeight * 100 + 100);
    stage.draw();

    console.log(roomWidth)



    layer.destroyChildren();

    room = new Konva.Rect({
        x: 50,
        y: 50,
        width: scaledWidth,
        height: scaledHeight,
        stroke: 'black',
        strokeWidth: 0,
        draggable: false,
    });
    layer.add(room);

    boundaries = [
        { name: 'Top', x: 50, y: 50, width: scaledWidth, height: 10, sections: [] },
        { name: 'Bottom', x: 50, y: 50 + scaledHeight - 10, width: scaledWidth, height: 10, sections: [] },
        { name: 'Left', x: 50, y: 50, width: 10, height: scaledHeight, sections: [] },
        { name: 'Right', x: 50 + scaledWidth - 10, y: 50, width: 10, height: scaledHeight, sections: [] }
    ];

    boundaries.forEach((b) => {
        let boundary = new Konva.Rect({
            x: b.x,
            y: b.y,
            width: b.width,
            height: b.height,
            fill: '#454547',
            name: b.name,
            draggable: false,
        });
        layer.add(boundary);

        boundary.on('click', (e) => {
            if (mode === 'Window' || mode === 'Door') {
                if (!sectionStart || sectionStart.boundary !== b.name) {
                    sectionStart = { boundary: b.name, pos: e.target.getRelativePointerPosition() };
                } else {
                    let sectionEnd = e.target.getRelativePointerPosition();
                    if (b.name === 'Top' || b.name === 'Bottom') {
                        let startX = Math.min(sectionStart.pos.x, sectionEnd.x);
                        let width = Math.abs(sectionEnd.x - sectionStart.pos.x);
                        // Only create a section if the drawn segment is big enough.
                        if (width < minSectionSize) {
                            sectionStart = null;
                            return;
                        }
                        let section = new Konva.Rect({
                            x: b.x + startX,
                            y: b.y,
                            width: width,
                            height: b.height,
                            fill: mode === 'Window' ? '#75afe9' : '#BE5E2B',
                        });
                        section.isSection = true;
                        section.boundary = b.name;
                        layer.add(section);
                        let sectionData = { type: mode, x: section.x(), y: section.y(), width: section.width(), height: section.height() };
                        b.sections.push(sectionData);
                        section.sectionData = sectionData;
                        sectionStart = null;
                        layer.draw();
                    } else if (b.name === "Left" || b.name === "Right") {
                        let startY = Math.min(sectionStart.pos.y, sectionEnd.y);
                        let height = Math.abs(sectionEnd.y - sectionStart.pos.y);
                        // Only create a section if the drawn segment is big enough.
                        if (height < minSectionSize) {
                            sectionStart = null;
                            return;
                        }
                        let section = new Konva.Rect({
                            y: b.y + startY,
                            x: b.x,
                            width: b.width,
                            height: height,
                            fill: mode === 'Window' ? '#75afe9' : '#BE5E2B',
                        });
                        section.isSection = true;
                        section.boundary = b.name;
                        layer.add(section);
                        let sectionData = { type: mode, x: section.x(), y: section.y(), width: section.width(), height: section.height() };
                        b.sections.push(sectionData);
                        section.sectionData = sectionData;
                        sectionStart = null;
                        layer.draw();
                    }
                }
            }
        });
    });

    layer.draw();
}

// Heating element drawing inside the room.
stage.on('mousedown', (e) => {
    if (mode === 'Heating' && room) {
        let target = e.target;

        // Prevent drawing if clicking on an existing heating element
        if (target.isHeating) {
            return;
        }

        let pos = stage.getPointerPosition();
        // Allow drawing only if click is inside the room boundaries
        if (pos.x >= room.x() && pos.x <= room.x() + room.width() &&
            pos.y >= room.y() && pos.y <= room.y() + room.height()) {
            heatingPreview = new Konva.Rect({
                x: pos.x,
                y: pos.y,
                width: 1,
                height: 1,
                fill: '#D61A3C',
                opacity: 0.5,
            });
            layer.add(heatingPreview);
            drawingHeating = true;
        }
    }
});

stage.on('mousemove', (e) => {
    if (drawingHeating && heatingPreview) {
        let pos = stage.getPointerPosition();
        let startX = heatingPreview.x();
        let startY = heatingPreview.y();
        heatingPreview.width(pos.x - startX);
        heatingPreview.height(pos.y - startY);
        layer.draw();
    }
});

stage.on('mouseup', () => {
    if (drawingHeating && heatingPreview) {
        heatingPreview.opacity(1);
        heatingPreview.draggable(true);
        heatingPreview.isHeating = true;
        heatingElements.push(heatingPreview);
        heatingPreview = null;
        drawingHeating = false;
        layer.draw();
    }
});

// Global stage click handler for Delete mode.
stage.on('click', (e) => {
    if (mode === 'Delete') {
        let target = e.target;
        // Do nothing if clicking on stage, room or walls.
        const boundaryNames = ['Top', 'Bottom', 'Left', 'Right'];
        if (target === stage || target === room || boundaryNames.includes(target.getAttr('name'))) {
            return;
        }
        // If it is a window/door section, update the corresponding boundary's sections.
        if (target.isSection) {
            let boundary = boundaries.find(b => b.name === target.boundary);
            if (boundary) {
                boundary.sections = boundary.sections.filter(s => {
                    return !(s.x === target.sectionData.x && s.y === target.sectionData.y && s.width === target.sectionData.width && s.height === target.sectionData.height && s.type === target.sectionData.type);
                });
            }
        }
        // If it's a heating element, remove it from the heatingElements array.
        if (target.isHeating) {
            heatingElements = heatingElements.filter(h => h !== target);
        }
        target.destroy();
        layer.draw();
    }
});

function exportToJson() {
    const roomWidth = parseFloat(document.getElementById('roomWidth').value);
    const roomHeight = parseFloat(document.getElementById('roomHeight').value);
    const tempStart = parseFloat(document.getElementById('startTemp').value);
    const tempTarget = parseFloat(document.getElementById('targetTemp').value);
    const heaterPower = parseFloat(document.getElementById('heaterPower').value);

    const roomData = {
        room: {
            width: roomWidth*100,
            height: roomHeight*100,
            tempStart: tempStart+273.15,
            tempTarget: tempTarget+273.15,
            heaterPower: heaterPower
        },
        boundaries: boundaries.map((b) => ({
            name: b.name,
            sections: b.sections.map((s) => {
                if (b.name === 'Top' || b.name === 'Bottom') {
                    return {
                        type: s.type,
                        x1: (s.x-50)/100,
                        x2: ((s.x + s.width)-50)/100,
                    };
                } else {
                    return {
                        type: s.type,
                        y1: (-(s.y + s.height-50)+roomHeight*100)/100,
                        y2: (-(s.y-50)+roomHeight*100)/100,
                    };
                }
            })
        })),
        heatingElements: heatingElements.map((h) => ({
            x1: Math.min((h.x()-50),(h.x() + h.width()-50))/100,
            x2: Math.max((h.x()-50),(h.x() + h.width()-50))/100,
            y1: Math.min((-(h.y() + h.height()-50)+roomHeight*100),(-(h.y()-50)+roomHeight*100))/100,
            y2: Math.max((-(h.y() + h.height()-50)+roomHeight*100),(-(h.y()-50)+roomHeight*100))/100
        }))
    };

    console.log(JSON.stringify(roomData, null, 2));
    return roomData;
}




const radioButtons = document.querySelectorAll('input[name="mode"]');

radioButtons.forEach((radio) => {
  radio.addEventListener('change', (event) => {
    mode = event.target.value;
    if (event.target.checked) {
      console.log('Selected option:', event.target.value);
      setMode(mode)
    }
  });
});