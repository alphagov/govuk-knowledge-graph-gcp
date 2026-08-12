
Parquet to BigQuery Data Ingestion

Overview

This is a Python-based data ingestion process that runs as a Google Cloud Run Job.

The application reads data from Parquet files stored in Google Cloud Storage (GCS), processes the data, and loads it into Google BigQuery. The application is packaged and deployed as a Docker container.

How It Works

The ingestion process works as follows:

The Docker image is built using the Dockerfile.

Python dependencies are installed from requirements.txt.

The application source code is copied into the Docker image.

The Cloud Run Job starts the application using: python main.py
