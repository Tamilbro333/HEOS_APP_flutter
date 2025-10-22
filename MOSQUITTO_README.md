Local Mosquitto broker (for development)

This project includes a small Mosquitto broker setup using Docker Compose for local testing with your ESP32.

Files added:
- `docker-compose.yml` - runs Eclipse Mosquitto (ports 1883 and 9001)
- `mosquitto.conf` - minimal local config (anonymous allowed) - do NOT use this in production
- `run_mosquitto.ps1` - PowerShell helper to start/stop the broker

Quick start (Windows PowerShell):

1. Make sure Docker Desktop is installed and running.
2. From the project root run:

```powershell
.\
un_mosquitto.ps1 up
```

3. Verify broker is running:

```powershell
docker ps --filter "name=heos_mosquitto"
```

4. To stop:

```powershell
.\
un_mosquitto.ps1 down
```

Connecting devices:
- MQTT TCP: use host `localhost` port `1883`
- WebSocket: use ws://localhost:9001

Security note:
- This configuration allows anonymous connections for convenience during development. Require authentication and TLS in production.
