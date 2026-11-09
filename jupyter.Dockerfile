FROM apache/spark:3.5.1

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    PYSPARK_PYTHON=/usr/bin/python3 \
    PYSPARK_DRIVER_PYTHON=/usr/bin/python3 \
    PIP_DEFAULT_TIMEOUT=120

USER root

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      python3 python3-pip python3-venv \
      tini ca-certificates curl git procps \
 && ln -sf /usr/bin/python3 /usr/bin/python \
 && rm -rf /var/lib/apt/lists/*

# ✅ ВАЖНО: jar'ы берём из репозитория, ничего не скачиваем
# Ожидается, что в проекте есть папка ./jars с этими файлами:

RUN mkdir -p /opt/spark/jars
COPY jars/hadoop-aws-3.3.4.jar /opt/spark/jars/
COPY jars/aws-java-sdk-bundle-1.12.262.jar /opt/spark/jars/
COPY jars/postgresql-42.7.4.jar /opt/spark/jars/

# (опционально) конфиги Spark из репо внутрь образа
# Ожидается папка ./spark/conf/ (spark-defaults.conf, log4j2.properties и т.п.)
COPY spark/conf/ /opt/spark/conf/

RUN pip3 install --no-cache-dir \
      pyspark==3.5.1 \
      jupyterlab==4.* ipykernel \
      pandas pyarrow numpy findspark \
      boto3 \
      "fsspec>=2023.12.0" \
      "s3fs>=2023.12.0"

RUN useradd -ms /bin/bash jovyan \
 && mkdir -p /home/jovyan/work \
 && chown -R jovyan:jovyan /home/jovyan

WORKDIR /home/jovyan/work
EXPOSE 8888

ENTRYPOINT ["/usr/bin/tini","--"]
CMD ["bash","-lc","jupyter lab \
 --ServerApp.ip=0.0.0.0 \
 --ServerApp.port=8888 \
 --ServerApp.token='' \
 --ServerApp.allow_remote_access=True \
 --ServerApp.disable_check_xsrf=True \
 --ServerApp.open_browser=False"]
