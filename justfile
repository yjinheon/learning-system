_default:
    @just --choose -f {{ justfile() }} -d {{ invocation_directory() }}

# - git pre-commit hook 추가
install:
    uv lock --upgrade
    uv sync --all-extras --frozen
    @just hook


# 코드 포맷팅 및 자동 수정 린터 실행
lint:
    uv run ruff format
    uv run ruff check --fix
    uv run mypy .


# 테스팅
test *args:
    uv run --no-sync pytest {{ args }}

# AIRFLOW
# init airflow db
airflow-init:
    @echo "Initializing Airflow Database..."
    uv run airflow db migrate
    @echo "Creating default user..."
    uv run airflow users create \
        --username admin \
        --firstname Admin \
        --lastname User \
        --role Admin \
        --email admin@example.com \
        --password admin

airflow-db-migrate:
    @echo "Migrating Airflow Database..."
    uv run airflow db migrate

airflow-webserver:
    uv run airflow webserver --port 8080

airflow-scheduler:
    uv run airflow scheduler

airflow-start:
    @echo "Airflow 웹서버 및 스케줄러 시작..."
    uv run airflow scheduler & uv run airflow webserver --port 8080

# show all DAGs
airflow-dags:
    uv run airflow dags list

# 특정 DAG 수동 트리거
# just airflow-trigger my_dag_id
airflow-trigger dag_id:
    @echo "DAG 트리거 중: {{dag_id}}..."
    uv run airflow dags trigger {{dag_id}}

# DAG 실행 상태 확인
airflow-status:
    @echo "DAG 실행 상태 확인 중..."
    uv run airflow dags state

# DAG의 특정 작업 테스트
# 사용법: just airflow-test my_dag_id my_task_id 2024-01-01
airflow-test dag_id task_id execution_date:
    @echo "작업 테스트 중: {{task_id}} (DAG: {{dag_id}})..."
    uv run airflow tasks test {{dag_id}} {{task_id}} {{execution_date}}

# 개발 도구
# =========

# 자동화된 코드 품질 검사를 위한 git pre-commit hook 설정
hook:
    uv run pre-commit install --install-hooks --overwrite

# unhook git pre-commit 
unhook:
    uv run pre-commit uninstall

# start mkdocs 개발 서버
docs:
    uv pip install -r requirements.txt
    uv run mkdocs serve

venv:
  @echo "Activating virtual environment..."
  @. .venv/bin/activate && exec $SHELL

# Deployment

publish:
    rm -rf dist
    uv build
    uv publish --token $PYPI_TOKEN

# Utilities
clean:
    rm -rf dist/
    rm -rf build/
    rm -rf *.egg-info/
    find . -type d -name __pycache__ -delete
    find . -type f -name "*.pyc" -delete

status:
    @echo "Python version:"
    uv run python --version
    @echo "installed packages:"
    uv pip list
    @echo "Git status:"
    git status --short

# install, lint, test
dev-setup: install lint test
    @echo "Development environment setup complete."
