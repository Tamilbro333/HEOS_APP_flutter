# run_mosquitto.ps1 - helper to start/stop Mosquitto via Docker Compose
param(
    [Parameter(Position=0)] [string] $action = 'up'
)

switch ($action) {
    'up' {
        Write-Output "Starting Mosquitto via docker-compose..."
        docker-compose up -d
        break
    }
    'down' {
        Write-Output "Stopping Mosquitto..."
        docker-compose down
        break
    }
    default {
        Write-Output "Unknown action: $action. Use 'up' or 'down'."
    }
}
