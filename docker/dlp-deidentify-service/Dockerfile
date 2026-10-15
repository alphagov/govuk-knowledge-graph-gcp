# Use a standard Python slim image
FROM python:3.12-slim

# Set the working directory
WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy your Python script
COPY main.py .

# Expose the default Cloud Run port
EXPOSE 8080

# Use functions-framework to start the web server and target your handler
ENTRYPOINT ["functions-framework", "--target=deidentify_handler"]
