#!/bin/sh
set -eu
cd /app

if [ -n "${DATABASE_URL:-}" ]; then
  python - <<'PY'
import os
import time
import dj_database_url
import psycopg2
import urllib.parse

url = dj_database_url.parse(os.environ['DATABASE_URL'])
for attempt in range(30):
    try:
        query = urllib.parse.parse_qs(urllib.parse.urlparse(os.environ['DATABASE_URL']).query)
        sslmode = query.get('sslmode', [None])[0]
        if sslmode is None and url['HOST'] not in ('localhost', '127.0.0.1', 'db'):
            sslmode = 'require'
        connection_kwargs = dict(
            dbname=url['NAME'], user=url['USER'], password=url['PASSWORD'],
            host=url['HOST'], port=url['PORT'], connect_timeout=5
        )
        if sslmode:
            connection_kwargs['sslmode'] = sslmode
        connection = psycopg2.connect(**connection_kwargs)
        connection.close()
        break
    except psycopg2.OperationalError as exc:
        if attempt == 29:
            print(f"Database connection failed after 30 attempts: {exc}", file=os.sys.stderr)
            raise
        time.sleep(2)
PY
elif [ -n "${POSTGRES_DB:-}" ] && [ -n "${POSTGRES_USER:-}" ] && [ -n "${POSTGRES_PASSWORD:-}" ]; then
  python - <<'PY'
import os
import time
import psycopg2

for attempt in range(30):
    try:
        connection = psycopg2.connect(
            dbname=os.environ['POSTGRES_DB'],
            user=os.environ['POSTGRES_USER'],
            password=os.environ['POSTGRES_PASSWORD'],
            host=os.environ.get('POSTGRES_HOST', 'db'),
            port=os.environ.get('POSTGRES_PORT', '5432'),
            connect_timeout=5
        )
        connection.close()
        break
    except psycopg2.OperationalError as exc:
        if attempt == 29:
            print(f"Database connection failed after 30 attempts: {exc}", file=os.sys.stderr)
            raise
        time.sleep(2)
PY
fi

python manage.py collectstatic --noinput
python manage.py migrate --noinput
python manage.py shell -c "from django.core.management import call_command; from cohorts.models import Cohort; call_command('loaddata', 'seed_data.json') if not Cohort.objects.exists() else None"
python manage.py createsuperuser --noinput || true
exec gunicorn config.wsgi:application --bind 0.0.0.0:${PORT:-8000} --workers 2 --threads 4 --timeout 30 --access-logfile - --error-logfile -
