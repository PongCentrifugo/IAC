# Redis Infrastructure

Redis instance used by Centrifugo (broker/presence) and backend disconnect listener.

## Quick Start

```bash
docker-compose up -d
docker-compose logs -f
```

## Notes

- Container name: `pong-redis`
- Network: `pong-network` (shared with Centrifugo and backend)
- Redis URL (from other services): `redis://pong-redis:6379/0`

