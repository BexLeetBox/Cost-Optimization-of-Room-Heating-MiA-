function fetchEnergyPrices() {
  fetch("/energy-prices")
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

  if (!lat || !lon) {
    alert("Please enter both latitude and longitude.");
    return;
  }

  fetch(`/merged-data?lat=${lat}&lon=${lon}`)
    .then((response) => response.json())
    .then((data) => {
      const display = document.getElementById("merged-data");
      display.textContent = JSON.stringify(data, null, 2);
      display.style.display = "block";
    })
    .catch((error) => console.error("Error fetching merged data:", error));
}

function toggleDisplay(elementId) {
  const element = document.getElementById(elementId);
  if (element.style.display === "none") {
    element.style.display = "block";
  } else {
    element.style.display = "none";
  }
}

function runSimulation() {
    const statusElement = document.getElementById('status');
    const spinner = document.getElementById('loading-spinner');

    // Show loading text and spinner
    statusElement.innerText = "Running simulation... Please wait.";
    statusElement.style.color = "blue";
    spinner.style.display = "block";

    fetch('/run-simulation')
        .then(response => response.json())
        .then(data => {
            statusElement.innerText = data.message;
            statusElement.style.color = "green";
            spinner.style.display = "none"; // Hide spinner
        })
        .catch(error => {
            console.error('Error running simulation:', error);
            statusElement.innerText = "Error: Simulation failed.";
            statusElement.style.color = "red";
            spinner.style.display = "none"; // Hide spinner
        });
}



/**
 
//--------------------------------------------- Konva ------------------------------------------




 */

