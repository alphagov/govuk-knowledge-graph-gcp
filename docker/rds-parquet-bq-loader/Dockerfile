FROM python:3.11-slim

# Disable stdout/stderr buffering and silence root warning globally
ENV PYTHONUNBUFFERED=TRUE
ENV PIP_ROOT_USER_ACTION=ignore

# Set working directory
WORKDIR /app

# Upgrade pip first to silence the "new release" warning
RUN pip install --no-cache-dir --upgrade pip

# Copy requirements first
COPY requirements.txt .

# Install dependencies (Using the --root-user-action flag to silence the warning)
RUN pip install --no-cache-dir --root-user-action=ignore -r requirements.txt

# Copy your code
COPY . /app/

CMD ["python", "main.py"]