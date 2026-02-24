FROM python:3.10-slim

# Install dependencies
RUN pip install --no-cache-dir pandas sqlalchemy psycopg2-binary click tqdm

# Set working directory
WORKDIR /app

# Copy the ingestion script
COPY ingest_data.py .

# Entry point
ENTRYPOINT ["python", "ingest_data.py"]
