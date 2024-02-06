# A script to download a sentence transformer model to be included in a docker
# image.
# https://stackoverflow.com/a/69717491

import os
from sentence_transformers import SentenceTransformer

model_path = os.environ["MODEL_PATH"]

model = SentenceTransformer("multi-qa-mpnet-base-dot-v1")
model.save(model_path)
