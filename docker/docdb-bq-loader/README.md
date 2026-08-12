Asset Manager Data Ingestion

Overview

This is a Python-based data ingestion process that runs as a Google Cloud Run Job, required Python dependencies are installed from requirements.txt, and MongoDB tools are included in the container for data ingestion and processing, which reads the db backup files and loads Bigquery tables.

How It Works

The Docker image is built from the provided Dockerfile.

Python dependencies are installed from requirements.txt.

Application source code and ingestion modules are copied into the container.

The Cloud Run Job starts the application using: python main.py
