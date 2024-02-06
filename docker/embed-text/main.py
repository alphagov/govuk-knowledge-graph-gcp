import os

from flask import Flask, request, jsonify
from typing import List
from sentence_transformers import SentenceTransformer
import numpy as np


# Max INT64 value encoded as a number in JSON by TO_JSON_STRING. Larger values are encoded as
# strings.
# See https://cloud.google.com/bigquery/docs/reference/standard-sql/json_functions#json_encodings
# Following the example at
# https://cloud.google.com/bigquery/docs/remote-functions#sample-functions-code
_MAX_LOSSLESS = 9007199254740992


# Load a sentence transformer model.
# The model is global so that it can be reused between invocations of
# parse_html(), which will be much more performant
model_path = os.environ["MODEL_PATH"]
model = SentenceTransformer(model_path)


app = Flask(__name__)


# A function to embed a list of short strings with a sentence transformer model.
#
# It's best to have removed tables from the input text beforehand.
@app.route("/", methods=["POST"])
def embed_text(*args):
    embeddings = []
    error_message = None
    status_code = 200
    try:
        request_json = request.get_json()
        calls = request_json["calls"]
        texts = [call[0] for call in calls]
        # model.encode doesn't handle None consistently, so temporarily replace
        # None with an empty string.
        is_none = [text is None for text in texts]
        texts = substitute_if(texts, is_none, "")
        embeddings = model.encode(texts, convert_to_tensor=False).tolist()
        # Where the text was None, ensure the embedding is None
        embeddings = substitute_if(embeddings, is_none, None)
    except Exception as e:
        error_message = str(e)
        status_code = 400
    return jsonify({"replies": embeddings, "errorMessage": error_message}), status_code


# A function to substitute values in a list when their corresponding values in
# another list are True.
def substitute_if(values, truefalse, substitute):
    return [substitute if b else a for a, b in zip(values, truefalse)]


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
