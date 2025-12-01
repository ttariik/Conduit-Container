from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
import os


class Command(BaseCommand):
    help = 'Ensures a superuser exists with the given credentials'

    def handle(self, *args, **options):
        User = get_user_model()
        username = os.environ.get('DJANGO_SUPERUSER_USERNAME', 'admin')
        email = os.environ.get('DJANGO_SUPERUSER_EMAIL', '')
        password = os.environ.get('DJANGO_SUPERUSER_PASSWORD', '')

        if not email or not password:
            self.stdout.write(
                self.style.WARNING(
                    '[entrypoint] DJANGO_SUPERUSER_EMAIL or DJANGO_SUPERUSER_PASSWORD not set - skipping superuser creation'
                )
            )
            return

        # Check if user with this username already exists
        if User.objects.filter(username=username).exists():
            self.stdout.write(
                self.style.SUCCESS(
                    "[entrypoint] Superuser '{}' already exists - skipping creation".format(username)
                )
            )
            return

        # Check if user with this email already exists
        if User.objects.filter(email=email).exists():
            self.stdout.write(
                self.style.SUCCESS(
                    "[entrypoint] User with email '{}' already exists - skipping creation".format(email)
                )
            )
            return

        # Create the superuser
        try:
            User.objects.create_superuser(
                username=username,
                email=email,
                password=password
            )
            self.stdout.write(
                self.style.SUCCESS(
                    "[entrypoint] Superuser '{}' created successfully".format(username)
                )
            )
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(
                    "[entrypoint] Failed to create superuser: {}".format(str(e))
                )
            )

