from locust import constant, SequentialTaskSet

from neo4j_client import *


class Neo4jTasks(SequentialTaskSet):

    def on_start(self):
        try:
            self.client.connect("neo4j", "password")
        except ConnectionError as exception:
            logging.info(f"Caught {exception}")
            self.user.environment.runner.quit()

    @task
    def send_query(self):
        cypher_query = '''
            CALL db.index.fulltext.queryNodes("description_text", 'children born in the uk')
            YIELD node as n, score
            WITH n, score
            ORDER BY score DESC
            LIMIT 50
            WITH n
            WHERE NOT n.documentType IN['gone', 'redirect', 'placeholder', 'placeholder_person']
            OPTIONAL MATCH(n: Page) - [: IS_TAGGED_TO] -> (taxon:Taxon)
            OPTIONAL MATCH(n: Page) - [r: HAS_PRIMARY_PUBLISHING_ORGANISATION] -> (o:Organisation)
            OPTIONAL MATCH(n: Page) - [: HAS_ORGANISATIONS] -> (o2:Organisation)
            RETURN
              n.url as url,
              n.title AS title,
              n.documentType AS documentType,
              n.contentID AS contentID,
              n.locale AS locale,
              n.publishingApp AS publishing_app,
              n.firstPublishedAt AS first_published_at,
              n.publicUpdatedAt AS public_updated_at,
              n.withdrawnAt AS withdrawn_at,
              n.withdrawnExplanation AS withdrawn_explanation,
              n.pagerank AS pagerank,
              COLLECT(distinct taxon.name) AS taxons,
              COLLECT(distinct o.name) AS primary_organisation,
              COLLECT(distinct o2.name) AS all_organisations
            ORDER BY n.pagerank DESC
            ;
        '''
        database = "neo4j"

        res = self.client.send(cypher_query, database)
        # print(res)

    # @task
    # def write_query(self):
    #     cypher_query = '''
    #     CREATE (u:User { name: "dataproducts", userId: "714" })
    #     '''
    #     database = "neo4j"
    #     res = self.client.write(cypher_query, database)
    #     print(res)

    def on_stop(self):
        self.client.disconnect()


class Neo4jCustom(Neo4jUser):
    tasks = [Neo4jTasks]
    host = "govgraph.dev:7687"
    wait_time = constant(1)
