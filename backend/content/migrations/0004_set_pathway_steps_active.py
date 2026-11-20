import json

from django.db import migrations


def set_pathway_steps_active(apps, schema_editor):
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
        if isinstance(step, dict) and step.get('step') in (3, 4) and step.get('status') != 'active':
            step['status'] = 'active'
            changed = True

    if changed:
        setting.value = json.dumps(steps)
        setting.save(update_fields=['value', 'updated_at'])


class Migration(migrations.Migration):

    dependencies = [
        ('content', '0003_complete_pathway_steps'),
    ]

    operations = [
        migrations.RunPython(set_pathway_steps_active, migrations.RunPython.noop),
    ]
