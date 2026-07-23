# Matrix Synapse with Tailscale Sidecar

Matrix Synapse homeserver with Tailscale sidecar for secure Tailnet access.

## Prerequisites

- Docker & Docker Compose
- Tailscale account with auth key

## Setup

1. **Configure environment variables:**

   Edit `.env` and set:
   - `SYNAPSE_SERVER_NAME` - Your server name (e.g., `matrix.yourdomain.com`)
   - `TS_AUTHKEY` - Tailscale auth key from https://tailscale.com/admin/authkeys
   - `POSTGRES_USER` / `POSTGRES_PASSWORD` - Database credentials

2. **Start the database first:**

   ```bash
   docker compose up -d database
   ```

3. **Generate Synapse configuration:**

   ```bash
   docker compose run --rm application generate
   ```

4. **Configure database connection:**

   Edit `matrix-data/homeserver.yaml` and update the database section:

   ```yaml
   database:
     name: psycopg2
     args:
       user: synapse_user
       password: synapse_password
       database: synapse
       host: db-matrix
       cp_min: 5
       cp_max: 10
   ```

5. **Start all services:**

   ```bash
   docker compose up -d
   ```

6. **Create admin user (optional):**

   ```bash
   docker exec -it app-matrix register_new_matrix_user http://localhost:8008 -c /data/homeserver.yaml
   ```

## Services

| Service | Description |
|---------|-------------|
| `tailscale` | Tailscale sidecar for Tailnet connectivity |
| `application` | Matrix Synapse homeserver (port 8008) |
| `database` | PostgreSQL 16 database |

## Access

- **Local:** http://localhost:8008
- **Tailnet:** Via Tailscale hostname configured in `TS_CERT_DOMAIN`

## Useful Commands

```bash
# View logs
docker compose logs -f

# Check status
docker compose ps

# Restart services
docker compose restart

# Stop all
docker compose down
```

## References

- [Synapse Docker](https://hub.docker.com/r/matrixdotorg/synapse/)
- [Synapse Documentation](https://element-hq.github.io/synapse/)
- [Matrix Specification](https://spec.matrix.org/)
