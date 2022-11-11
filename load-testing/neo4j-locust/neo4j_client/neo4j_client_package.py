from neo4j import GraphDatabase, basic_auth
from neo4j.exceptions import *
from neo4j._exceptions import *
from locust import events, User, task

import logging
import inspect
import time

"""Return a duration

Decorator to measure the timings for the tasks.
"""


def stopwatch(func):
    def wrapper(*args, **kwargs):
        previous_frame = inspect.currentframe().f_back
        _, _, task_name, _, _ = inspect.getframeinfo(previous_frame)
        start = time.time()
        result = None
        try:
            result = func(*args, **kwargs)
        except Exception as e:
            total = int((time.time() - start) * 1000)
            events.request_failure.fire(request_type="TYPE",
                                        name=task_name,
                                        response_time=total,
                                        exception=e)
        else:
            total = int((time.time() - start) * 1000)
            events.request_success.fire(request_type="TYPE",
                                        name=task_name,
                                        response_time=total,
                                        response_length=0)
        return result

    return wrapper


"""Class for the Neo4j Client """


class Neo4jClient(User):
    abstract = True

    def __init__(self, host):
        self.host = host
        # self.username = username
        # self.password = password
        self.driver = None

    """Connects to neo4j database"""

    def connect(self, username, password):
        bolt_url = "neo4j+s://" + self.host
        try:
            self.driver = GraphDatabase.driver(
                bolt_url,
                auth=basic_auth(username, password))
            print("Connected to the database successfully")

        except ConnectionError as exception:
            logging.error(f"Caught 1 {exception}")
            self.environment.runner.quit()
        except BoltHandshakeError as exception:
            logging.error(f"Caught 2 {exception}")
            self.environment.runner.quit()
        except ServiceUnavailable as exception:
            logging.error(f"Caught 3 {exception}")
            self.environment.runner.quit()

    """Send query to neo4j"""

    @stopwatch
    def send(self, cypher_query, database):
        with self.driver.session(database=database) as session:
            results = session.read_transaction(
                lambda tx: tx.run(cypher_query).data())
        return results

    """Write query to neo4j"""

    @stopwatch
    def write(self, cypher_query, database, **kwargs):
        try:
            with self.driver.session(database=database) as session:
                results = session.write_transaction(
                    lambda tx: tx.run(cypher_query).data())
            return results

        except ConstraintError as exception:
            logging.error(f"{cypher_query} raised an exception with {exception}")
            self.user.environment.runner.quit()
        except DatabaseError as exception:
            logging.error(f"{cypher_query} raised an exception with {exception}")
            self.user.environment.runner.quit()

    """Disconnects from neo3j database"""

    def disconnect(self):
        self.driver.close()


"""Abstract class for Neo4j"""


class Neo4jUser(User):
    abstract = True

    def __init__(self, *args, **kwargs):
        super(Neo4jUser, self).__init__(*args, **kwargs)
        self.client = Neo4jClient(self.host)
        self.client.environment = self.environment
