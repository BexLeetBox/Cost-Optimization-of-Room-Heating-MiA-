function fetchEnergyPrices() {
    fetch('/energy-prices')
        .then(response => response.json())
        .then(data => {
            document.getElementById('energy-prices').textContent = JSON.stringify(data, null, 2);
        })
        .catch(error => console.error('Error fetching energy prices:', error));
}

function fetchWeather() {
    const lat = document.getElementById('latitude').value;
    const lon = document.getElementById('longitude').value;

    if (!lat || !lon) {
        alert('Please enter both latitude and longitude.');
        return;
    }

    fetch(`/weather?lat=${lat}&lon=${lon}`)
        .then(response => response.json())
        .then(data => {
            document.getElementById('weather-data').textContent = JSON.stringify(data, null, 2);
        })
        .catch(error => console.error('Error fetching weather data:', error));
}

function fetchEnergyPrices() {
    fetch('/energy-prices')
        .then(response => response.json())
        .then(data => {
            const display = document.getElementById('energy-prices');
            display.textContent = JSON.stringify(data, null, 2);
            display.style.display = 'block';  // Show the data by default
        })
        .catch(error => console.error('Error fetching energy prices:', error));
}

function fetchWeather() {
    const lat = document.getElementById('latitude').value;
    const lon = document.getElementById('longitude').value;

    if (!lat || !lon) {
        alert('Please enter both latitude and longitude.');
        return;
    }

    fetch(`/weather?lat=${lat}&lon=${lon}`)
        .then(response => response.json())
        .then(data => {
            const display = document.getElementById('weather-data');
            display.textContent = JSON.stringify(data, null, 2);
            display.style.display = 'block';  // Show the data by default
        })
        .catch(error => console.error('Error fetching weather data:', error));
}

function toggleDisplay(elementId) {
    const element = document.getElementById(elementId);
    if (element.style.display === 'none') {
        element.style.display = 'block';
    } else {
        element.style.display = 'none';
    }
}
