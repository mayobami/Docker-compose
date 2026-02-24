# NYC Taxi Data Ingestion with Docker & PostgreSQL

This project demonstrates how to ingest NYC taxi data into PostgreSQL using Docker containers.

## Project Structure

```
docker-sql/
├── ingest_data.py           # Python script to ingest taxi data
├── Dockerfile               # Container image for ingestion script
├── docker-compose.yml       # Multi-container orchestration
├── requirements.txt         # Python dependencies
└── scripts/
    ├── docker-postgres.sh   # Helper script to run Postgres
    ├── docker-pgadmin.sh    # Helper script to run pgAdmin
    └── docker-ingest.sh     # Helper script to run ingestion
```

## Prerequisites

- Docker installed (running in WSL if on Windows)
- Python 3.10+ (optional, for local testing)

### WSL One-Time Setup

If running Docker inside WSL (not Docker Desktop), do this once:

```bash
# Install docker compose plugin
sudo apt-get install -y docker-compose-plugin

# Allow dockerd to start without password prompt
echo 'YOUR_USERNAME ALL=(ALL) NOPASSWD: /usr/bin/dockerd' | sudo tee /etc/sudoers.d/dockerd-nopasswd
```

## Quick Start

### Option 1: Using Docker Compose (Recommended)

1. **Start the Docker daemon (WSL only):**

```bash
sudo dockerd > /tmp/dockerd.log 2>&1 &
sleep 5
```

2. **Start PostgreSQL and pgAdmin:**

```bash
cd docker-sql
docker compose up -d
```

This starts:
- PostgreSQL 15 database on `localhost:5432`
- pgAdmin on `http://localhost:8085`

3. **Build the ingestion container:**

```bash
docker build -t taxi_ingest:v001 .
```

4. **Run the ingestion:**

```bash
docker run -it --rm \
  --network=docker-sql_pg-network \
  taxi_ingest:v001 \
  --year=2021 \
  --month=1 \
  --pg-user=root \
  --pg-pass=root \
  --pg-host=pgdatabase \
  --pg-port=5432 \
  --pg-db=ny_taxi \
  --chunksize=100000 \
  --target-table=yellow_taxi_trips
```

### Option 2: Using Individual Containers

If you're running on **WSL**, use the bash scripts:

```bash
# Enter WSL
wsl

# Start Docker daemon (if not running)
sudo dockerd &

# Navigate to project
cd /mnt/c/Users/user/.conda/ML-Churning-Project/docker-sql

# Start PostgreSQL
bash scripts/docker-postgres.sh

# In another terminal, start pgAdmin
bash scripts/docker-pgadmin.sh

# Build ingestion image
docker build -t taxi_ingest:v001 .

# Run ingestion
bash scripts/docker-ingest.sh
```

## Access pgAdmin

1. Open browser: `http://localhost:8085`
2. Login:
   - Email: `admin@admin.com`
   - Password: `root`
3. Add server:
   - Host: `pgdatabase` (or `localhost` if accessing from host)
   - Port: `5432`
   - Username: `root`
   - Password: `root`
   - Database: `ny_taxi`

## Ingestion Script Options

The `ingest_data.py` script accepts these parameters:

| Option | Default | Description |
|--------|---------|-------------|
| `--pg-user` | `root` | PostgreSQL username |
| `--pg-pass` | `root` | PostgreSQL password |
| `--pg-host` | `localhost` | PostgreSQL host |
| `--pg-port` | `5432` | PostgreSQL port |
| `--pg-db` | `ny_taxi` | Database name |
| `--year` | `2021` | Year of taxi data |
| `--month` | `1` | Month of taxi data |
| `--target-table` | `yellow_taxi_trips` | Destination table |
| `--chunksize` | `100000` | Rows per chunk |

## Example: Load Multiple Months

```bash
# January 2021
docker run -it --rm --network=docker-sql_pg-network taxi_ingest:v001 \
  --year=2021 --month=1 --pg-host=pgdatabase --pg-user=root --pg-pass=root --pg-db=ny_taxi

# February 2021
docker run -it --rm --network=docker-sql_pg-network taxi_ingest:v001 \
  --year=2021 --month=2 --pg-host=pgdatabase --pg-user=root --pg-pass=root --pg-db=ny_taxi
```

## Query the Data

Using `pgcli` (if installed):

```bash
pgcli -h localhost -p 5432 -u root -d ny_taxi
```

Example queries:

```sql
-- Count total trips
SELECT COUNT(*) FROM yellow_taxi_trips;

-- Average fare by passenger count
SELECT passenger_count, AVG(total_amount) as avg_fare
FROM yellow_taxi_trips
GROUP BY passenger_count
ORDER BY passenger_count;

-- Trips by day
SELECT DATE(tpep_pickup_datetime) as trip_date, COUNT(*) as trip_count
FROM yellow_taxi_trips
GROUP BY trip_date
ORDER BY trip_date;
```

## Cleanup

Stop and remove containers:

```bash
# Using Docker Compose
docker compose down

# Remove volumes (warning: deletes data!)
docker compose down -v

# Or manually
docker stop pgdatabase pgadmin
docker rm pgdatabase pgadmin
docker network rm pg-network
```

## Notes

- Uses `postgres:15` (not 18) — postgres:18 changed the data directory layout and requires a different volume mount path.
- The ingestion script uses `psycopg2` as the SQLAlchemy driver (`postgresql+psycopg2://`).

## Troubleshooting

### Docker daemon not running (WSL)

```bash
wsl
sudo dockerd > /tmp/dockerd.log 2>&1 &
sleep 5
```

### Network not found

Check the network name created by Docker Compose:

```bash
docker network ls
```

Use the correct network name (e.g., `docker-sql_pg-network` or `docker-sql_default`).

### Can't connect to Postgres from ingestion container

Make sure:
1. Both containers are on the same network
2. Use `--pg-host=pgdatabase` (container name, not `localhost`)
3. Postgres container is running: `docker ps`

## Data Source

NYC Taxi data is downloaded from:
`https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_YYYY-MM.csv.gz`

## Credits

Based on the [Data Engineering Zoomcamp](https://github.com/DataTalksClub/data-engineering-zoomcamp) by DataTalks.Club.
