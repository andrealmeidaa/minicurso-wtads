from django.contrib.auth import get_user_model

def create_superusers():
    User = get_user_model()
    superusers = [
        {'username': 'admin1', 'email': 'admin1@example.com', 'password': 'admin1pass'},
        {'username': 'admin2', 'email': 'admin2@example.com', 'password': 'admin2pass'},
    ]
    for su in superusers:
        if not User.objects.filter(username=su['username']).exists():
            User.objects.create_superuser(
                username=su['username'],
                email=su['email'],
                password=su['password']
            )

def run():
    create_superusers()