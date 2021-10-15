# -*- coding: utf-8 -*-
from django.db import migrations


def reassign_admin_access_permission(apps, schema_editor):
    ContentType = apps.get_model('contenttypes.ContentType')
    Permission = apps.get_model('auth.Permission')

    # Add a content type to hang the 'can access Wagtail admin' permission off
    admin_content_type, created = ContentType.objects.get_or_create(
        app_label='wagtailcore',
        model='admin'
    )

    Permission.objects.filter(codename='access_admin').update(content_type=admin_content_type)


class Migration(migrations.Migration):

    dependencies = [
        ('wagtailcore', '0069_admin'),
    ]

    operations = [
        migrations.RunPython(reassign_admin_access_permission),
    ]
