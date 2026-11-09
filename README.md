# DE-практикум: stand-репозиторий

Этот репозиторий содержит **только инфраструктуру стенда** для DE-практикума:

- Docker Compose
- Dockerfile'ы сервисов
- конфиги Spark / Airflow / Postgres
- init-скрипты для БД
- исходные датасеты
- рабочие директории проекта

**Текстовые уроки, задания, тесты, рецензирование и порядок прохождения находятся на Stepik.**  
Этот репозиторий нужен для того, чтобы поднять локальный стенд и выполнять практические задания по модулям.

Если что-то не взлетело по окружению, сначала открой [troubleshooting.md](troubleshooting.md).

---

## Что поднимается

Локальный мини-стенд для практики по Data Engineering:

- Postgres
- Spark Master / Workers
- JupyterLab
- MinIO
- Airflow

---

## Сервисы и ссылки

- JupyterLab: http://localhost:8890
- Spark Master UI: http://localhost:18080
- Spark Workers UI: http://localhost:8081, http://localhost:8082
- Airflow UI: http://localhost:8085
- MinIO Console: http://localhost:9001
- MinIO API (S3): http://localhost:9000

Postgres для DBeaver / psql:

- host: `127.0.0.1`
- port: `5433`
- db: `dwh`
- user: `app`
- password: см. `.env`

---

## Быстрый старт

Все команды `docker compose ...` выполняйте из корня проекта, там где лежит `docker-compose.yml`.

### 0) Клонируйте репозиторий

```bash
git clone <url-репозитория> de_practicum_stand
cd de_practicum_stand
```

Проверка:

```bash
ls -la docker-compose.yml
```

---

### 1) Создайте `.env`

Linux / Mac / Git Bash:

```bash
cp .env_template .env
```

Windows PowerShell:

```powershell
Copy-Item .env_template .env
```

После этого откройте `.env` и сгенерируйте значения для Airflow.

Fernet key:

```bash
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

Webserver secret key:

```bash
python -c "import secrets; print(secrets.token_hex(32))"
```

Если локально нет `cryptography`, используйте запасной вариант:

```bash
python -c "import os, base64; print(base64.urlsafe_b64encode(os.urandom(32)).decode())"
```

---

### 2) Скачайте JAR-файлы в `jars/`

Они нужны:

- для работы Spark с MinIO через `s3a://`
- для JDBC-подключения к Postgres

Ожидаемый набор:

- `jars/hadoop-aws-3.3.4.jar`
- `jars/aws-java-sdk-bundle-1.12.262.jar`
- `jars/postgresql-42.7.4.jar`

Linux / Mac:

```bash
mkdir -p jars

curl -L -o jars/hadoop-aws-3.3.4.jar https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar
curl -L -o jars/aws-java-sdk-bundle-1.12.262.jar https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar
curl -L -o jars/postgresql-42.7.4.jar https://repo1.maven.org/maven2/org/postgresql/postgresql/42.7.4/postgresql-42.7.4.jar

ls -la jars
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force -Path jars | Out-Null

Invoke-WebRequest -Uri "https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar" `
  -OutFile "jars\hadoop-aws-3.3.4.jar"

Invoke-WebRequest -Uri "https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar" `
  -OutFile "jars\aws-java-sdk-bundle-1.12.262.jar"

Invoke-WebRequest -Uri "https://repo1.maven.org/maven2/org/postgresql/postgresql/42.7.4/postgresql-42.7.4.jar" `
  -OutFile "jars\postgresql-42.7.4.jar"

Get-ChildItem jars
```

Если JAR'ы скачаны уже после запуска контейнеров, обычно хватает:

```bash
docker compose restart jupyter spark-master spark-worker-1 spark-worker-2
```

---

### 3) Поднимите стек

Первый запуск или после изменения Dockerfile / Compose:

```bash
docker compose up -d --build
```

Обычный запуск:

```bash
docker compose up -d
```

Проверка:

```bash
docker compose ps
```

Проверка, что JAR'ы видны внутри контейнеров:

```bash
docker compose exec jupyter ls -la /jars
docker compose exec spark-master ls -la /jars
```

Если в Git Bash на Windows видите ошибку вида `C:/Program Files/Git/jars`, это MSYS path conversion.  
Тогда либо используйте PowerShell, либо так:

```bash
MSYS_NO_PATHCONV=1 docker compose exec jupyter ls -la /jars
MSYS_NO_PATHCONV=1 docker compose exec spark-master ls -la /jars
```

---

### 4) Откройте интерфейсы

- Jupyter: http://localhost:8890
- Spark Master: http://localhost:18080
- Airflow: http://localhost:8085
- MinIO Console: http://localhost:9001

---

### 5) Быстрые smoke-checks

Проверка Postgres:

```bash
docker compose exec postgres psql -U app -d dwh -c "select 1 as ok;"
```

Если подключаетесь из DBeaver:

- Host: `127.0.0.1`
- Port: `5433`
- Database: `dwh`
- User: `app`
- Password: из `.env`

Проверка Jupyter:

```python
import os, sys, glob

print("python:", sys.executable)
print("cwd:", os.getcwd())
print("/jars exists:", os.path.exists("/jars"))
print("/jars glob:", glob.glob("/jars/*.jar"))
```

Ожидаемо:

- `/jars exists: True`
- список `.jar` файлов не пустой

---

## Где проходить обучение

Все уроки, задания, тесты и контрольные точки находятся на платформе Stepik.  
Этот репозиторий не содержит текстовых уроков и решений.

---

## Структура проекта

Минимум того, что важно понимать:

- `data/csv/` — исходные CSV-файлы
- `data/csv2/` — дополнительные CSV-исходники
- `data/parquet/` — parquet-версии датасетов
- `data/raw/` — локальный RAW-слой
- `db/postgres/init/` — init-скрипты для Postgres
- `db/work/` — рабочая папка под SQL студента
- `scripts/put_to_raw.py` — служебный скрипт раскладки данных
- `spark/conf/` — конфиги Spark
- `notebooks/workspace/` — рабочая зона под ноутбуки
- `workspace/` — дополнительная рабочая директория проекта
- `dags/` — папка под DAG'и Airflow
- `jars/` — локальные JAR'ы для Spark
- `troubleshooting.md` — разбор типовых проблем

---

## Что не хранится в репозитории

В Git не коммитятся локальные рабочие артефакты:

- содержимое `workspace/`
- содержимое `db/work/`
- содержимое `data/raw/`
- содержимое `dags/`
- содержимое `jars/`
- рабочие файлы из `notebooks/workspace/`

Структура папок в репозитории есть, но их рабочее содержимое у каждого студента свое локально.

---

## Как задавать вопросы в чате

Чтобы не превращать диагностику в угадайку, сразу прикладывайте:

1. модуль / урок / шаг
2. ОС
3. что ожидали получить
4. что получилось по факту
5. текст ошибки или скрин
6. что уже пробовали
7. вывод `docker compose ps`

Если вопрос про JAR'ы / MinIO, добавьте еще:

```bash
ls -la jars
docker compose exec jupyter ls -la /jars
```
