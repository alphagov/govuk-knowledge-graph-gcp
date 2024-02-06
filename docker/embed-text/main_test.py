import os
import pytest
import main
import json


@pytest.fixture
def client():
    main.app.testing = True
    return main.app.test_client()


def query(client_fixture, json_dict):
    response = client_fixture.post("/", json=json_dict)
    return {
        "replies": json.loads(response.data.decode())["replies"],
        "error_message": json.loads(response.data.decode())["errorMessage"],
        "status": response.status,
    }


def test_200_with_nil_input(client):
    response = query(
        client,
        json_dict={
            "calls": [[None]],
        },
    )
    assert response["status"] == "200 OK"


def test_200_with_blank_input(client):
    response = query(
        client,
        json_dict={
            "calls": [[""]],
        },
    )
    assert response["status"] == "200 OK"


def test_200_with_nonblank_input(client):
    response = query(
        client,
        json_dict={
            "calls": [["Embed me."]],
        },
    )
    assert response["status"] == "200 OK"


def test_returns_embeddings(client):
    response = query(
        client,
        json_dict={
            "calls": [["Line 1"], ["Line 2"]],
        },
    )
    embeddings = response["replies"]
    assert type(embeddings) is list
    assert len(embeddings) == 2
    embedding = response["replies"][0]
    assert type(embedding) is list
    assert type(embedding[0]) is float
    assert len(embedding) == 768
