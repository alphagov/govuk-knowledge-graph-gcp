
Parquet to BigQuery Data Ingestion

Overview

This is a Python-based data ingestion process that runs as a Google Cloud Run Job.

The application reads data from Parquet files stored in Google Cloud Storage (GCS), processes the data, and loads it into Google BigQuery. The application is packaged and deployed as a Docker container.

How It Works

The ingestion process works as follows:

The Docker image is built using the Dockerfile.

Python dependencies are installed from requirements.txt.

The application source code is copied into the Docker image.

The Cloud Run Job starts the application using:

python main.py


High-Level Flow:
GCS Parquet Files
        |
        v
Python Ingestion Application
        |
        v
Google Cloud Run Job
        |
        v
Google BigQuery


Project Structure

```text
.
├── docker/
│   └── postgres-mysql-feeds/
│       ├── Dockerfile
│       ├── README.md
│       ├── requirements.txt
│       └── ...
└── src/
    └── postgres-mysql-feeds/
        ├── main.py
        └── ...

```


Below are the CloudRunJob deployment commands to live environment:

Build and Push Docker Image
gcloud builds submit --tag europe-west2-docker.pkg.dev/govuk-knowledge-graph/cloud-run-job-deploy/rds-parquet-bq-loader

Deploy Cloud Run Job
gcloud run jobs deploy rds-parquet-bq-loader \
  --image europe-west2-docker.pkg.dev/govuk-knowledge-graph/cloud-run-job-deploy/rds-parquet-bq-loader \
  --region europe-west2 \
  --tasks 5 \
  --max-retries 0 \
  --cpu 2 \
  --memory 8Gi \
  --parallelism 3 \
  --task-timeout 7200s \
  --execution-environment gen2 \
  --set-env-vars="CONFIG_PATH=config/live/config.json,RECOVERY_MODE=False" \
  --service-account="rds-parquet-bq-loader@govuk-knowledge-graph.iam.gserviceaccount.com"
