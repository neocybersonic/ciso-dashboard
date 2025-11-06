from django.db import migrations

def create_roles(apps, schema_editor):
    Group = apps.get_model("auth", "Group")
    Permission = apps.get_model("auth", "Permission")
    ContentType = apps.get_model("contenttypes", "ContentType")

    admin_group, _ = Group.objects.get_or_create(name="admin")
    readonly_group, _ = Group.objects.get_or_create(name="readonly")

    # Grant admin all permissions for your app labels (add more as needed)
    app_labels = ["core"]  # add other app labels here
    admin_perms = Permission.objects.filter(content_type__app_label__in=app_labels)
    admin_group.permissions.set(admin_perms)

    # readonly gets only 'view_' perms
    readonly_perms = Permission.objects.filter(
        content_type__app_label__in=app_labels, codename__startswith="view_"
    )
    readonly_group.permissions.set(readonly_perms)

def remove_roles(apps, schema_editor):
    Group = apps.get_model("auth", "Group")
    Group.objects.filter(name__in=["admin", "readonly"]).delete()

class Migration(migrations.Migration):
    dependencies = [
        #("core", "0001_initial"),   # adjust to your last migration
        ("auth", "__latest__"),
    ]
    operations = [
        migrations.RunPython(create_roles, remove_roles),
    ]
