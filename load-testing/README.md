# Load testing of Neo4j

Can Neo4j handle enough concurrent requests from Gov Graph Search?  We use
[locust](https://docs.locust.io/en/stable/what-is-locust.html) to find out.

The code in this directory has been adapted from
https://github.com/QAInsights/neo4j-locust, as follows:

- Everything from `neo4j-locust/requirements.txt` was removed except for the
  entries for `locust` and `neo4j`, but their version numbers were removed too,
  because of this issue: https://github.com/locustio/locust/issues/1759.
- The connection string was changed from `bolt` to `neo4j+s`.
- The query to be executed was changed, for relevance.

## Use

SSH into a running Neo4j instance of the Knowledge Graph.  For example:

```shell
gcloud compute ssh --zone "europe-west2-b" "neo4j" --project "govuk-knowledge-graph" --container "klt--pdoq"
```

The container ID might have changed.  It can be found by omitting `--container`,
to SSH into the instance hosting the container, and then using `docker ps` to
show the name of the container.

Install python and venv, create a virtual environment, and install the
dependencies.

```shell
apt install python3-venv
python3 -m venv venv
. venv/bin/activate
python -m pip install -r requirements.txt
```

Temporariliy raise the limit of the number of files that processes in the shell
are allowed to open.

- https://github.com/locustio/locust/wiki/Installation#increasing-maximum-number-of-open-files-limit
- https://wiki.archlinux.org/title/Limits.conf

```shell
ulimit -Sn unlimited
```

Run locust.  Redirect stdout to `/dev/null`.  Statistics are reported via
stderror.

```shell
locust -f locustfile.py --headless --users 100 --spawn-rate 10 1>/dev/null
```

Neo4j is currently configured to only allow 100 concurrent requests, so there is
no point simulating more than that, unless we really do need to serve more than
that number of users, in which case we could reconfigure that, or use a
different database.
