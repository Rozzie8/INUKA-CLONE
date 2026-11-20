import json

from django.db import migrations


def complete_pathway_steps(apps, schema_editor):
    site_setting = apps.get_model('content', 'SiteSetting')
    setting = site_setting.objects.filter(key='pathway_steps').first()
    if not setting:
        return

    try:
        steps = json.loads(setting.value)
    except (TypeError, json.JSONDecodeError):
        return
    if not isinstance(steps, list):
        return

    changed = False
    for step in steps:
        if isinstance(step, dict) and step.get('step') in (3, 4) and step.get('status') != 'completed':
            step['status'] = 'completed'
            changed = True

    if changed:
        setting.value = json.dumps(steps)
        setting.save(update_fields=['value', 'updated_at'])


class Migration(migrations.Migration):

    dependencies = [
        ('content', '0002_alter_post_slug'),
    ]

    operations = [
        migrations.RunPython(complete_pathway_steps, migrations.RunPython.noop),
    ]
