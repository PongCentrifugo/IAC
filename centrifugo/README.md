# Centrifugo Infrastructure

Centrifugo WebSocket server for Pong game.

## Quick Start

### Option 1: Docker Compose

```bash
# 1. Create config
cp config.example.json config.json
# Edit config.json - set your secrets

# 2. Start
docker-compose up -d

# 3. Check logs
docker-compose logs -f

# 4. Stop
docker-compose down
```

### Option 2: Local Binary

```bash
# 1. Install Centrifugo
# macOS
brew install centrifugo

# Or download from https://github.com/centrifugal/centrifugo/releases

# 2. Create config
cp config.example.json config.json

# 3. Run
centrifugo --config=config.json
```

## Configuration

Edit `config.json`:

```json
{
  "token_hmac_secret_key": "your-secret-key",
  "api_key": "your-api-key",
  "proxy_rpc_endpoint": "http://localhost:8080/v1/centrifugo/rpc"
}
```

**Important**: 
- `token_hmac_secret_key` must match `CENTRIFUGO_SECRET` in pong-backend `.env`
- `api_key` must match `CENTRIFUGO_API_KEY` in pong-backend `.env`

## Namespaces

Two namespaces for three channels:

### 1. pong_public namespace
- **Channel**: `pong_public:lobby`
- **Access**: Anonymous (no auth)
- **History**: 10 messages, 300s TTL
- **Purpose**: Lobby events, spectator view

### 2. pong_private namespace
- **Channels**: `pong_private:first`, `pong_private:second`
- **Access**: Requires JWT subscription token
- **History**: None
- **Purpose**: Private enemy movement messages

## Docker Notes

If running backend locally (not in Docker):
- Use `proxy_rpc_endpoint: "http://host.docker.internal:8080/v1/centrifugo/rpc"`

If running backend in Docker on same network:
- Use `proxy_rpc_endpoint: "http://pong-api:8080/v1/centrifugo/rpc"`

## Endpoints

- **WebSocket**: `ws://localhost:8000/connection/websocket`
- **Admin panel**: `http://localhost:8000/` (user: admin, password: from config)
- **HTTP API**: `http://localhost:8000/api`

## Channels

| Channel | Namespace | Anonymous | History | Purpose |
|---------|-----------|-----------|---------|---------|
| `pong_public:lobby` | `pong_public` | ✅ Yes | 10 msgs | Lobby + spectators |
| `pong_private:first` | `pong_private` | ❌ No | None | Player 1 private |
| `pong_private:second` | `pong_private` | ❌ No | None | Player 2 private |

## Test Connection

### Anonymous (public channel)
```bash
# Install wscat
npm install -g wscat

# Connect
wscat -c ws://localhost:8000/connection/websocket

# Send connect command
{"id":1,"connect":{}}

# Subscribe to public channel
{"id":2,"subscribe":{"channel":"pong_public:lobby"}}
```

### Authenticated (private channel)
You need a subscription token from backend:
```bash
curl -X POST -H "Authorization: Bearer alice" \
  -H "Content-Type: application/json" \
  -d '{"place":"first"}' \
  http://localhost:8080/v1/games/join
```

Then use the returned tokens to connect and subscribe.

## Network

Docker network: `pong-network`

Other services can join this network to communicate with Centrifugo.
