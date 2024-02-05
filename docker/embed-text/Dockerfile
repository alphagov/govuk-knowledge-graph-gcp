FROM python:3.11.6-slim-bullseye

WORKDIR /usr/src/app
COPY requirements.txt .

RUN python3 -m pip install --upgrade pip \
    && pip3 install -r requirements.txt

ENV MODEL_PATH /usr/src/app/model

COPY download-model.py .
RUN python3 download-model.py

COPY . .

# Run the web service on container startup.
ENTRYPOINT ["functions-framework-python", "--target", "embed_text"]
