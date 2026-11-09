# Docker Desktop: как поднять стенд заранее

Этот файл нужен для ситуации, когда ты хочешь поднять стенд до того, как дойдёшь до соответствующего шага на Stepik.

Здесь собран полный путь для Windows:

- вход в Docker Desktop;
- обновление WSL2, если Docker это требует;
- проверка, что Docker реально работает;
- подготовка `.env`;
- скачивание JAR-файлов;
- первый запуск стенда;
- проверка сервисов после старта.

Если репозиторий ещё не склонирован, сначала пройди [git.md](git.md).

Важно:

- все команды `docker compose ...` выполняй из корня проекта, там где лежит `docker-compose.yml`;
- в примерах ниже путь показан как `D:\de_lab\de_practicum_stand`;
- если ты клонировал проект в другую папку, подставь свой путь;
- в Docker Desktop проект может отображаться как `de_practicum_stand`, потому что это имя задано в `docker-compose.yml`. Это нормально.

---

## 1. Войди в Docker Desktop

Если Docker Desktop ещё не установлен, сначала установи его под Windows.

При первом запуске Docker Desktop может попросить авторизацию или регистрацию. Проще всего зайти через Google-аккаунт или пройти обычную регистрацию.

Что здесь важно:

- аккаунт нужен для работы Docker Desktop и скачивания образов;
- публиковать свои образы в Docker Hub для практикума не нужно;
- на этом шаге тебе нужен только рабочий доступ к Docker Desktop.

![Вход или регистрация в Docker](https://ucarecdn.stepik.net/b45c7a63-5188-4c07-9963-7d3e2edf4ba7/)

---

## 2. Если Docker просит обновить WSL

На Windows это обычная история. Docker Desktop запускается и показывает сообщение:

> **WSL needs updating**  
> Your version of Windows Subsystem for Linux (WSL) is too old.

Если видишь это сообщение, не пытайся идти дальше. Сначала обнови WSL.

Что сделать:

1. Открой `PowerShell` или `Командную строку` от имени администратора.
2. Выполни:

```bash
wsl --update
```

3. Дождись завершения обновления.
4. Закрой и заново открой Docker Desktop.
5. Если есть возможность, перезагрузи компьютер.

После этого предупреждение про WSL должно исчезнуть.

![Docker просит обновить WSL](https://ucarecdn.stepik.net/20227072-3938-4bc2-87ad-ecf5f3595a9d/)

![WSL успешно обновлён](https://ucarecdn.stepik.net/7b96dc51-9a64-4b4b-b437-667fccc5a4a5/)

---

## 3. Проверь, что Docker реально работает

Открой Docker Desktop и убедись, что:

- есть рабочий статус `Engine running`;
- нет активной ошибки запуска;
- интерфейс Docker Desktop открылся нормально.

После этого открой терминал и проверь CLI:

```bash
docker --version
docker compose version
```

Обе команды должны отработать без ошибок.

Если Docker Desktop открыт, но движок не поднялся, дальше ты упрёшься в стену на первом же `docker compose up`.

![Docker Desktop в рабочем состоянии](https://ucarecdn.stepik.net/789802f5-6128-41b3-b614-72504b8125ce/)

---

## 4. Перейди в корень проекта

Если ты клонировал проект по инструкции из `git.md`, путь обычно такой:

Для PowerShell:

```powershell
cd D:\de_lab\de_practicum_stand
```

Для Git Bash:

```bash
cd /d/de_lab/de_practicum_stand
```

Сразу проверь, что ты реально в корне проекта:

Для PowerShell:

```powershell
Get-ChildItem docker-compose.yml
```

Для Git Bash:

```bash
ls -la docker-compose.yml
```

Если файла `docker-compose.yml` в текущей папке нет, ты не в корне проекта. Дальше команды запускать бессмысленно.

---

## 5. Создай `.env`

Перед первым запуском создай локальный `.env` на основе `.env_template`.

Для PowerShell:

```powershell
Copy-Item .env_template .env
```

Для Git Bash:

```bash
cp .env_template .env
```

Потом открой `.env` и заполни два ключа:

- `AIRFLOW_FERNET_KEY`
- `AIRFLOW_WEBSERVER_SECRET_KEY`

Сгенерировать `AIRFLOW_FERNET_KEY`:

```bash
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

Если локально нет `cryptography`, используй запасной вариант:

```bash
python -c "import os, base64; print(base64.urlsafe_b64encode(os.urandom(32)).decode())"
```

Сгенерировать `AIRFLOW_WEBSERVER_SECRET_KEY`:

```bash
python -c "import secrets; print(secrets.token_hex(32))"
```

Вставь значения в `.env` и сохрани файл.

Что важно:

- эти ключи генерируются один раз для твоей локальной машины;
- перед каждым запуском перевыпускать их не нужно;
- если оставить их пустыми, Airflow либо не поднимется, либо будет вести себя криво.

---

## 6. Скачай JAR-файлы для Spark

Перед запуском стенда отдельно скачай JAR-файлы в папку `jars/`.

Нужны три файла:

- `hadoop-aws-3.3.4.jar`
- `aws-java-sdk-bundle-1.12.262.jar`
- `postgresql-42.7.4.jar`

Они нужны для двух вещей:

- Spark должен уметь работать с MinIO через `s3a://`;
- Spark должен уметь подключаться к Postgres через JDBC.

Проще всего на Windows сделать это из PowerShell:

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

После этого проверь, что файлы реально лежат в `jars/`.

Если JAR-файлы скачаны уже после запуска контейнеров, пересборка образов не нужна. Обычно хватает:

```bash
docker compose restart jupyter spark-master spark-worker-1 spark-worker-2
```

---

## 7. Подними стенд (после клонирования репозитория)

Если это первый запуск или ты менял `Dockerfile` / `docker-compose.yml`, используй:

```bash
docker compose up -d --build
```

Если стенд уже собирался раньше и ты не менял инфраструктурные файлы, обычно хватает:

```bash
docker compose up -d
```

Что нормально при первом запуске:

- Docker скачивает образы;
- часть контейнеров собирается дольше обычного;
- одноразовые init-контейнеры могут завершиться после успешной инициализации.

Не закрывай терминал сразу. Сначала смотри, нет ли явных ошибок сборки, запуска или монтирования.

---

## 8. Проверь, что контейнеры поднялись как надо

Сначала выполни:

```bash
docker compose ps
```

Нормальная картина такая:

- `postgres`, `jupyter`, `spark-master`, `spark-worker-1`, `spark-worker-2`, `minio`, `airflow-webserver`, `airflow-scheduler`, `metabase` находятся в состоянии `running`;
- `airflow-init`, `minio-init`, `bi-bootstrap` могут быть в состоянии `exited` или `completed successfully`, если они уже выполнили свою одноразовую работу.

Если контейнеры с основными сервисами падают в `exited` или бесконечно перезапускаются, смотри логи, а не гадай.

---

## 9. Базовые проверки после старта

### 9.1. Postgres

Проверь, что база отвечает:

```bash
docker compose exec postgres psql -U app -d dwh -c "select 1 as ok;"
```

Для DBeaver используй такие параметры:

- Host: `127.0.0.1`
- Port: `5433`
- Database: `dwh`
- User: `app`
- Password: смотри в `.env`

### 9.2. JupyterLab

Открой:

```text
http://localhost:8890
```

### 9.3. Spark Master UI

Открой:

```text
http://localhost:18080
```

Дополнительно можно открыть UI воркеров:

- `http://localhost:8081`
- `http://localhost:8082`

### 9.4. Airflow UI

Открой:

```text
http://localhost:8085
```

Дефолтный логин, который создаётся на старте:

- login: `admin`
- password: `admin`

### 9.5. MinIO Console

Открой:

```text
http://localhost:9001
```

Логин:

- user: `airflow`
- password: `airflow123`

### 9.6. Metabase

Открой:

```text
http://localhost:3000
```

Если Metabase не поднялся сразу, не устраивай шаманство в Docker Desktop. Сначала проверь `docker compose ps`. Этот сервис стартует только после Postgres и `bi-bootstrap`.

---

## 10. Если есть проблемы с JAR-файлами, Spark или MinIO

Проверь, видны ли JAR'ы внутри контейнеров:

```bash
docker compose exec jupyter ls -la /jars
docker compose exec spark-master ls -la /jars
```

Если работаешь в Git Bash на Windows и видишь кривую подстановку пути вроде `C:/Program Files/Git/jars`, используй:

```bash
MSYS_NO_PATHCONV=1 docker compose exec jupyter ls -la /jars
MSYS_NO_PATHCONV=1 docker compose exec spark-master ls -la /jars
```

Внутри `/jars` должны лежать все три файла. Если их там нет, Spark не увидит нужные зависимости.

---

## 11. Как останавливать и запускать стенд повторно

Остановить стенд:

```bash
docker compose down
```

Запустить повторно:

```bash
docker compose up -d
```

Если ты не менял `Dockerfile` и `docker-compose.yml`, повторная сборка обычно не нужна.

---

## 12. Что должно получиться в итоге

После этой инструкции у тебя должно быть следующее:

1. Docker Desktop установлен и запускается без ошибки.
2. Если требовалось, WSL обновлён.
3. Команды `docker --version` и `docker compose version` работают.
4. Файл `.env` создан, а ключи для Airflow заполнены.
5. JAR-файлы лежат в папке `jars/`.
6. Стенд поднимается через `docker compose up -d --build` или `docker compose up -d`.
7. `docker compose ps` показывает рабочие сервисы.
8. Postgres отвечает на `select 1`, а Jupyter, Spark, Airflow, MinIO и Metabase открываются в браузере.
