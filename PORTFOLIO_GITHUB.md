# Как оформить учебный проект как портфолио на GitHub

Эта инструкция поможет вынести свою работу из учебного стенда в отдельный аккуратный репозиторий. Старую историю коммитов переносить не нужно.

> Важно: GitHub хранит файлы только через коммиты. Загрузить проект совсем без коммита нельзя. Но можно создать новый репозиторий без истории учебного стенда и сделать один новый коммит со своей версией проекта.

## 1. Что можно положить в портфолио

Публикуйте только собственную работу и те инфраструктурные файлы, которые нужны, чтобы понять или запустить проект:

- свои DAG-файлы Airflow;
- свои SQL-скрипты для RAW, STG, CORE, MARTS и проверок качества;
- свои Spark jobs и Python-скрипты;
- очищенные notebooks без временного вывода и секретов;
- пример `docker-compose.yml`, если вы самостоятельно его дорабатывали;
- `.env.example` только с фиктивными значениями;
- README с описанием архитектуры, запуска и результата;
- несколько скриншотов Airflow, Spark UI, Metabase и результатов проверок;
- небольшой обезличенный пример данных, если его разрешено распространять.

Не выдавайте весь учебный стенд и стартеры за полностью самостоятельную разработку. В README честно укажите, что проект сделан в рамках практикума, а затем доработан вами.

## 2. Что нельзя публиковать

Не добавляйте в репозиторий:

- файл `.env`;
- GitHub PAT, пароли, ключи и реальные строки подключения;
- содержимое Docker volumes и базы данных;
- логи Airflow, Spark и Docker;
- большие CSV, Parquet и другие исходные датасеты;
- JAR-файлы;
- папки `.git`, `.idea`, `.vscode`, `__pycache__`;
- чужие решения и закрытые материалы курса;
- персональные данные.

Перед публикацией обязательно проверьте проект поиском:

```powershell
Get-ChildItem -Recurse -File | Select-String -Pattern "password|secret|token|access_key|private_key" -CaseSensitive:$false
```

Совпадение не всегда означает утечку, но каждую найденную строку нужно проверить вручную.

## 3. Рекомендуемая структура

```text
de-practicum-portfolio/
├── README.md
├── .gitignore
├── .env.example
├── docker-compose.example.yml
├── dags/
├── sql/
│   ├── stg/
│   ├── core/
│   ├── marts/
│   └── quality/
├── spark_jobs/
├── notebooks/
└── docs/
    └── screenshots/
```

Не обязательно заполнять все папки. Лучше показать один законченный маршрут данных, чем выложить десятки случайных файлов.

## 4. Создание чистой папки проекта

Откройте PowerShell и создайте новую папку отдельно от учебного стенда:

```powershell
cd $HOME\Documents
New-Item -ItemType Directory -Name de-practicum-portfolio
cd de-practicum-portfolio

New-Item -ItemType Directory -Path dags, sql, spark_jobs, notebooks, docs\screenshots
```

Скопируйте только выбранные собственные файлы. Пример:

```powershell
Copy-Item "D:\docker_de_practicum\de_practicum_stand\dags\lesson09_10_b_spark_job_from_airflow.py" ".\dags\"
Copy-Item "D:\docker_de_practicum\de_practicum_stand\workspace\module08\work\m8_02_build_wide_parquet_ksa.py" ".\spark_jobs\"
```

Замените имена файлов в примере на свои. Не копируйте папку проекта целиком: вместе с ней легко утащить секреты, временные файлы и чужой код.

## 5. Файл `.gitignore`

Создайте `.gitignore` со следующим содержимым:

```gitignore
.env
.env.*
!.env.example

__pycache__/
*.py[cod]
.venv/
.pytest_cache/
.ipynb_checkpoints/

.idea/
.vscode/
*.iml
.DS_Store
Thumbs.db

*.log
logs/
data/
datasets/
jars/
*.jar
*.parquet

pg_data/
minio_data/
metabase-data/
airflow/logs/
```

## 6. Что написать в README

README должен быстро отвечать на следующие вопросы:

1. Какую задачу решает проект?
2. Как данные проходят через слои?
3. Какие технологии использованы?
4. Что именно сделано вами?
5. Как запустить демонстрацию?
6. Какие проверки качества реализованы?
7. Где посмотреть результат?

Минимальный шаблон:

```markdown
# Data Engineering Practicum Portfolio

Пет-проект пакетной обработки данных интернет-магазина.

## Архитектура

Источник → RAW → STG → CORE → MARTS → BI

## Стек

PostgreSQL, Python, Spark, Airflow, MinIO, Metabase, Docker Compose.

## Что реализовано

- идемпотентная загрузка данных;
- преобразования между слоями хранилища;
- Spark job для формирования Parquet;
- DAG-и Airflow и журналирование запусков;
- проверки качества и сверки данных;
- BI-витрины и дашборд.

## Запуск

Опишите только реально проверенные команды запуска.

## Результаты

Добавьте 2-4 скриншота и коротко объясните, что на них подтверждается.

## Происхождение проекта

Проект выполнен в рамках практикума по Data Engineering. В репозитории опубликованы мои решения и доработки; исходные данные и закрытые материалы курса не распространяются.
```

## 7. Создание репозитория на GitHub

На GitHub нажмите `+` → `New repository` и заполните:

- `Repository name`: например, `de-practicum-portfolio`;
- `Description`: короткое описание проекта;
- `Public`, если проект готов к публичному просмотру;
- не добавляйте на GitHub README, `.gitignore` и License, если они уже созданы локально.

После создания GitHub покажет адрес репозитория. Он будет выглядеть так:

```text
https://github.com/ВАШ_ЛОГИН/de-practicum-portfolio.git
```

## 8. Первый коммит и публикация

Выполните в новой папке портфолио:

```powershell
git init
git branch -M main
git status

git add README.md .gitignore .env.example dags sql spark_jobs notebooks docs
git status

git commit -m "Initial portfolio version"
git remote add origin https://github.com/ВАШ_ЛОГИН/de-practicum-portfolio.git
git push -u origin main
```

Если какого-то файла или каталога пока нет, уберите его имя из команды `git add`. Не используйте сразу `git add .`, пока не убедитесь, что `.gitignore` работает правильно.

При работе через HTTPS GitHub может запросить авторизацию:

- `Username` — ваш GitHub-логин;
- `Password` — Personal Access Token, а не пароль от аккаунта.

## 9. Проверка перед публикацией

Перед `git push` выполните:

```powershell
git status
git diff --cached --stat
git diff --cached
```

Убедитесь, что в staged-файлах нет `.env`, токенов, паролей, исходных датасетов и случайных файлов IDE.

После публикации откройте репозиторий в режиме инкогнито. Проверьте, что README отображается, скриншоты открываются, структура понятна без объяснений автора, а команды запуска не содержат локальных путей с вашим именем пользователя.

## 10. Как развивать репозиторий дальше

После первого чистого коммита делайте небольшие осмысленные изменения:

```powershell
git add dags\имя_файла.py
git commit -m "Add Airflow orchestration DAG"
git push
```

Хорошее портфолио показывает не количество файлов, а законченную инженерную историю: задача, архитектура, код, проверки, запуск и измеримый результат.
