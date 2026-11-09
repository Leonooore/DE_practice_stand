FROM apache/airflow:2.9.3-python3.12

USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      openjdk-17-jre-headless postgresql-client \
 && rm -rf /var/lib/apt/lists/*

USER airflow

# constraints из репозитория (НЕ из интернета)
COPY docker/airflow/constraints-3.12.txt /constraints.txt

RUN pip install --no-cache-dir --upgrade pip setuptools wheel \
 && pip install --no-cache-dir --constraint /constraints.txt \
      apache-airflow-providers-amazon \
      apache-airflow-providers-apache-spark \
      apache-airflow-providers-fab \
      boto3 \
      psycopg2-binary
