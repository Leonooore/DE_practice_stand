FROM apache/spark:3.5.1

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv python3-numpy \
    ca-certificates tini procps curl \
 && ln -sf /usr/bin/python3 /usr/bin/python \
 && rm -rf /var/lib/apt/lists/*

# ✅ Вместо скачивания — копируем jar'ы из репо
# (если имена у тебя такие же, как на скрине)
COPY jars/hadoop-aws-3.3.4.jar /opt/spark/jars/
COPY jars/aws-java-sdk-bundle-1.12.262.jar /opt/spark/jars/
COPY jars/postgresql-42.7.4.jar /opt/spark/jars/

# (опционально) прокидываем конфиги Spark внутрь образа
COPY spark/conf/ /opt/spark/conf/

USER spark
