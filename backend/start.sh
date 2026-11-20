#!/bin/sh
set -eu
cd /app

if [ -n "${DATABASE_URL:-}" ]; then
  python - <<'PY'
import os
import time
import dj_database_url
import psycopg2

url = dj_database_url.parse(os.environ['DATABASE_URL'])
for attempt in range(30):
    try:
        connection = psycopg2.connect(
            dbname=url['NAME'], user=url['USER'], password=url['PASSWORD'],
            host=url['HOST'], port=url['PORT'], connect_timeout=5
        )
        connection.close()
        break
    except psycopg2.OperationalError:
        if attempt == 29:
            raise
        time.sleep(2)
PY
fi

python manage.py migrate --noinput
python manage.py shell -c "from django.core.management import call_command; from cohorts.models import Cohort; call_command('loaddata', 'seed_data.json') if not Cohort.objects.exists() else None"
python manage.py createsuperuser --noinput || true
exec gunicorn config.wsgi:application --bind 0.0.0.0:${PORT:-8000} --workers 2 --threads 4 --timeout 30 --access-logfile - --error-logfile -
