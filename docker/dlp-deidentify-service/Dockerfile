# Use a standard Python slim image
FROM python:3.12-slim

# Disable stdout/stderr buffering, silence root warning, and define certificate locations
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=True \
    PIP_ROOT_USER_ACTION=ignore \
    SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt" \
    REQUESTS_CA_BUNDLE="/etc/ssl/certs/ca-certificates.crt"

# Set the working directory
WORKDIR /app

# Create virtual environment and add it to PATH 
RUN python -m venv /app/venv
ENV PATH="/app/venv/bin:$PATH"

# Install CA certificates
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    update-ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install dependencies
COPY requirements.txt .

# Update certifi alongside dependencies
RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir --upgrade certifi

# Copy your Python script
COPY main.py .

# Expose the default Cloud Run port
EXPOSE 8080

# Use functions-framework to start the web server and target your handler
ENTRYPOINT ["functions-framework", "--target=deidentify_handler"]
