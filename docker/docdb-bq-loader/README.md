Asset Manager Data Ingestion

Overview

This is a Python-based data ingestion process that runs as a Google Cloud Run Job, required Python dependencies are installed from requirements.txt, and MongoDB tools are included in the container for data ingestion and processing, which reads the db backup files and loads Bigquery tables.

How It Works

The Docker image is built from the provided Dockerfile.

Python dependencies are installed from requirements.txt.

Application source code and ingestion modules are copied into the container.

The Cloud Run Job starts the application using: python main.py

High-Level Flow:
GCS MongoDB Backup File
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
│   └── asset-manager/
│       ├── Dockerfile
│       ├── README.md
│       └── requirements.txt
└── src/
    └── asset-manager/
        ├── main.py
        └── ...
```


Below are the CloudRunJob deployment commands to live environment:

Build and Push Docker Image
gcloud builds submit --tag europe-west2-docker.pkg.dev/govuk-knowledge-graph/cloud-run-job-deploy/docdb-bq-loader

Deploy Cloud Run Job
gcloud run jobs deploy docdb-bq-loader \
  --image europe-west2-docker.pkg.dev/govuk-knowledge-graph/cloud-run-job-deploy/docdb-bq-loader \
  --region europe-west2 \
  --tasks 1 \
  --max-retries 0 \
  --memory 8Gi \
  --cpu 2 \
  --task-timeout 7200s \
  --execution-environment gen2 \
  --project=govuk-knowledge-graph \
  --set-env-vars="CONFIG_PATH=config/live/config.json" \
  --service-account="docdb-bq-loader@govuk-knowledge-graph.iam.gserviceaccount.com"
