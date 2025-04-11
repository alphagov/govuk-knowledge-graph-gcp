## MySQL/MariaDB native

```sql
drop table if exists test;
create table test (col_int INT, col_string VARCHAR(255), col_bool BOOLEAN, col_json JSON);
insert into test (col_int, col_string, col_bool, col_json) VALUES (1, "foo'", true, '{"k1": "foo\'", "k2": [10, 20]}');
insert into test (col_int, col_string, col_bool, col_json) VALUES (1, 'foo"', true, '{"k1": "foo\\"", "k2": [10, 20]}');
```

```text
+---------+------------+----------+---------------------------------+
| col_int | col_string | col_bool | col_json                        |
+---------+------------+----------+---------------------------------+
|       1 | foo'       |        1 | {"k1": "foo'", "k2": [10, 20]}  |
|       1 | foo"       |        1 | {"k1": "foo\"", "k2": [10, 20]} |
+---------+------------+----------+---------------------------------+
```

## MySQL/MariaDB dump

```sql
INSERT INTO `test` VALUES
(1,'foo\'',1,'{\"k1\": \"foo\'\", \"k2\": [10, 20]}'),
(1,'foo\"',1,'{\"k1\": \"foo\\\"\", \"k2\": [10, 20]}');
```

## BigQuery native

```sql
SELECT 1, "foo'", "bar\"", JSON_OBJECT('a\'', NULL, 'b"', JSON 'null') AS json_data, true
```

Of which the JSON value is `{"a'":null,"b\"":null}`

## BigQuery serialised to CSV
```text
1,foo',"bar""","{""a'"":null,""b\"""":null}",true
```
