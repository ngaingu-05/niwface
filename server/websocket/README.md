# niwface WebSocket receiver

The iOS app streams each Core Data recording as one JSON WebSocket message. The server acknowledges each saved record with `{"success": true, "uuid": "..."}`. If an acknowledgement is lost, the app retries and the receiver uses the record UUID to avoid writing a duplicate JSONL line. The app's **Save & Test** action sends a `ping` message and expects a `pong` response without writing a sample.

## Run on Ubuntu

From the repository root:

```bash
./server/websocket/scripts/start.sh
```

The script creates a virtual environment, installs the packages in `requirements.txt`, then listens on `0.0.0.0:8000`. Keep it running while recording. Find the Ubuntu Wi-Fi address with:

```bash
hostname -I
```

If UFW is enabled, allow port 8000 from the phone's LAN subnet (replace the example subnet):

```bash
sudo ufw allow from 192.168.1.0/24 to any port 8000 proto tcp
```

In the iOS app, tap **Server**, enter `ws://<UBUNTU_WIFI_IP>:8000`, and tap **Save & Test**. The app connects to `/ws/arkit/<session UUID>` for each session. The receiver writes to `server/websocket/data/<session UUID>.jsonl`; `/health` is available over HTTP on port 8000.

The current WebSocket endpoint has authentication disabled in `config/server.yaml`, matching its implementation. Keep it on a trusted LAN and do not expose port 8000 to the public internet.
