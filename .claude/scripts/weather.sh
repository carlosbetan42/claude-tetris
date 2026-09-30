#!/bin/bash

# Weather skill script using Open-Meteo free API
# Usage: weather.sh [latitude] [longitude] OR weather.sh [city] [state/country]
# Default: San Francisco (37.7749, -122.4194)

# Function to geocode city names to coordinates
geocode_city() {
  local city="$1"
  local region="$2"
  local query="$city"

  if [ -n "$region" ]; then
    query="$city, $region"
  fi

  # Use Nominatim (OpenStreetMap) for geocoding
  local geo_response=$(curl -s "https://nominatim.openstreetmap.org/search?q=$(echo "$query" | sed 's/ /%20/g')&format=json&limit=1")

  # Extract latitude and longitude
  local lat=$(echo "$geo_response" | grep -o '"lat":"[^"]*' | cut -d'"' -f4 | head -1)
  local lon=$(echo "$geo_response" | grep -o '"lon":"[^"]*' | cut -d'"' -f4 | head -1)

  if [ -z "$lat" ] || [ -z "$lon" ]; then
    echo "Error: City '$query' not found" >&2
    return 1
  fi

  echo "$lat $lon"
}

# Parse arguments
if [ $# -eq 0 ]; then
  # Default location
  LAT="37.7749"
  LON="-122.4194"
  LOCATION_NAME="San Francisco"
elif [ $# -eq 1 ]; then
  # Check if it's a number (coordinate) or city name
  if [[ "$1" =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
    echo "Error: Single coordinate provided. Use: weather.sh lat lon OR weather.sh 'City' 'State/Country'" >&2
    exit 1
  else
    # Assume it's a city name
    result=$(geocode_city "$1" "")
    if [ $? -ne 0 ]; then
      exit 1
    fi
    LAT=$(echo "$result" | cut -d' ' -f1)
    LON=$(echo "$result" | cut -d' ' -f2)
    LOCATION_NAME="$1"
  fi
elif [ $# -ge 2 ]; then
  # Check if both are numbers (coordinates)
  if [[ "$1" =~ ^-?[0-9]+\.?[0-9]*$ ]] && [[ "$2" =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
    LAT="$1"
    LON="$2"
    LOCATION_NAME="($LAT, $LON)"
  else
    # Assume city and state/country
    result=$(geocode_city "$1" "$2")
    if [ $? -ne 0 ]; then
      exit 1
    fi
    LAT=$(echo "$result" | cut -d' ' -f1)
    LON=$(echo "$result" | cut -d' ' -f2)
    LOCATION_NAME="$1, $2"
  fi
fi

# Fetch weather data
RESPONSE=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=$LAT&longitude=$LON&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,precipitation&temperature_unit=celsius&wind_speed_unit=kmh")

# Parse JSON with jq if available, fallback to grep
if command -v jq &> /dev/null; then
  TEMP=$(echo "$RESPONSE" | jq '.current.temperature_2m')
  HUMIDITY=$(echo "$RESPONSE" | jq '.current.relative_humidity_2m')
  WEATHER=$(echo "$RESPONSE" | jq '.current.weather_code')
  WIND=$(echo "$RESPONSE" | jq '.current.wind_speed_10m')
  PRECIP=$(echo "$RESPONSE" | jq '.current.precipitation')
else
  TEMP=$(echo "$RESPONSE" | grep -o '"temperature_2m":[0-9.-]*' | cut -d':' -f2)
  HUMIDITY=$(echo "$RESPONSE" | grep -o '"relative_humidity_2m":[0-9]*' | cut -d':' -f2)
  WEATHER=$(echo "$RESPONSE" | grep -o '"weather_code":[0-9]*' | cut -d':' -f2)
  WIND=$(echo "$RESPONSE" | grep -o '"wind_speed_10m":[0-9.-]*' | cut -d':' -f2)
  PRECIP=$(echo "$RESPONSE" | grep -o '"precipitation":[0-9.-]*' | cut -d':' -f2)
fi

# Map weather codes to descriptions
case "$WEATHER" in
  0) DESC="Clear sky ☀️" ;;
  1|2) DESC="Partly cloudy ⛅" ;;
  3) DESC="Overcast ☁️" ;;
  45|48) DESC="Foggy 🌫️" ;;
  51|53|55) DESC="Drizzle 🌧️" ;;
  61|63|65) DESC="Rain 🌧️" ;;
  71|73|75) DESC="Snow ❄️" ;;
  77) DESC="Snow grains ❄️" ;;
  80|82|85|86) DESC="Rain showers 🌦️" ;;
  95|96|99) DESC="Thunderstorm ⛈️" ;;
  *) DESC="Unknown" ;;
esac

# Display formatted output
echo ""
echo "Weather in $LOCATION_NAME ($LAT, $LON)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌡️  Temperature: ${TEMP}°C"
echo "☁️  Conditions: $DESC"
echo "💧 Humidity: ${HUMIDITY}%"
echo "💨 Wind: ${WIND} km/h"
echo "🌧️  Precipitation: ${PRECIP}mm"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
