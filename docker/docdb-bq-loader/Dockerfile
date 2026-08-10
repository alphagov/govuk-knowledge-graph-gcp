FROM python:3.11-slim

# Tell apt-get to run automatically, buffer stdout, and silence pip root warnings globally
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=True \
    PIP_ROOT_USER_ACTION=ignore

# Install tools, configure APT to use classic 'gpgv' and install MongoDB tools securely.
RUN apt-get update && apt-get install -y gnupg wget curl gpgv && \
    echo 'APT::Key::gpgvcommand "/usr/bin/gpgv";' > /etc/apt/apt.conf.d/99-temp-use-gpgv && \
    curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg && \
    echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 main" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list && \
    apt-get update && apt-get install -y mongodb-org-server mongodb-org-tools && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python", "main.py"]