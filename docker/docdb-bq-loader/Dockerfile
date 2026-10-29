FROM python:3.12-slim

# Disable stdout/stderr buffering, silence root warning, and define certificate locations
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=True \
    PIP_ROOT_USER_ACTION=ignore \
    SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt" \
    REQUESTS_CA_BUNDLE="/etc/ssl/certs/ca-certificates.crt"

# Set working directory
WORKDIR /app

# Create virtual environment and add it to PATH 
RUN python -m venv /app/venv
ENV PATH="/app/venv/bin:$PATH"

# Install CA certificates, basic tools, configure APT, and install MongoDB tools securely.
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    update-ca-certificates && \
    apt-get install -y --no-install-recommends gnupg wget curl gpgv && \
    echo 'APT::Key::gpgvcommand "/usr/bin/gpgv";' > /etc/apt/apt.conf.d/99-temp-use-gpgv && \
    curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg && \
    echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 main" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends mongodb-org-server mongodb-org-tools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# Update certifi alongside dependencies
RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir --upgrade certifi

COPY . .

CMD ["python", "main.py"]