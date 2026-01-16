# Infrastructure as Code (IaC)

Infrastructure configuration for Pong game.

## Structure

```
iac/
├── centrifugo/          # Centrifugo WebSocket server
│   ├── docker-compose.yml
│   ├── config.example.json
│   └── README.md
└── redis/               # Redis broker/presence for Centrifugo + backend
    ├── docker-compose.yml
    └── README.md
```

## Quick Setup

### 1. Start Redis

```bash
cd redis
docker-compose up -d
```

### 2. Start Centrifugo

```bash
cd centrifugo
cp config.example.json config.json
# Edit config.json - set secrets
docker-compose up -d
```

### 3. Configure Backend

```bash
cd ../pong-backend
cp .env.example .env
# Edit .env - match secrets with Centrifugo config
```

### 4. Start Backend

```bash
# Local
go run cmd/pong-api/main.go

# Or Docker
docker-compose up -d
```

## Network

All services use Docker network `pong-network` for communication.

## Secrets

**Important**: Keep these in sync:
- `iac/centrifugo/config.json` → `token_hmac_secret_key`
- `pong-backend/.env` → `CENTRIFUGO_SECRET`

And:
- `iac/centrifugo/config.json` → `api_key`
- `pong-backend/.env` → `CENTRIFUGO_API_KEY`
