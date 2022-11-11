# Locust Library for Neo4j database

This library helps you to performance test the neo4j database from Locust.

## Install

`git clone https://github.com/QAInsights/neo4j-locust`  
`cd neo4j-locust`  
`pip install -r requirements.txt`

## Usage

`from neo4j_client import *`

### Boilerplate

```
class Neo4jTasks(SequentialTaskSet):
    def on_start(self):
        try:
            self.client.connect("naveenkumar", "neo4j")
        except ConnectionError as exception:
            logging.info(f"Caught {exception}")
            self.user.environment.runner.quit()

    @task
    def send_query(self):
        cypher_query = '''
        MATCH (n:Actor) RETURN n LIMIT 25
        '''
        database = "neo4j"

        res = self.client.send(cypher_query, database)
        
    def on_stop(self):
        self.client.disconnect()

class Neo4jCustom(Neo4jUser):
    tasks = [Neo4jTasks]
    host = "localhost:7687"
    wait_time = constant(1)

```