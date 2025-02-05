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
