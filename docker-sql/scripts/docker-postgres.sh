#!/usr/bin/env bash

## Bash script to start the Postgres container
echo "Starting PostgreSQL container..."

docker run -it \
  -e POSTGRES_USER="root" \
  -e POSTGRES_PASSWORD="root" \
  -e POSTGRES_DB="ny_taxi" \
  -v ny_taxi_postgres_data:/var/lib/postgresql/data \
  -p 5432:5432 \
  --network=pg-network \
  --name pgdatabase \
  postgres:18

# To use the pgcli:
# pgcli -h localhost -p 5432 -u root -d ny_taxi
