import boto3
import json
import logging
from botocore.exceptions import ClientError

logger = logging.getLogger(__name__)

def get_secret(secret_name, region_name="us-east-1"):
    """
    Retrieve a secret from AWS Secrets Manager
    """
    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )
    
    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        logger.error(f"Error retrieving secret {secret_name}: {e}")
        raise e
    
    # Parse the secret
    secret = get_secret_value_response['SecretString']
    return json.loads(secret)

def get_rds_connection_info(secret_name, region_name="us-east-1"):
    """
    Get RDS connection information from AWS Secrets Manager
    Returns a dictionary with database connection parameters
    """
    try:
        secret_data = get_secret(secret_name, region_name)
        
        return {
            'ENGINE': 'django.db.backends.mysql',
            'NAME': secret_data.get('db', 'taskdb'),
            'USER': secret_data.get('user'),
            'PASSWORD': secret_data.get('password'),
            'HOST': secret_data.get('host'),
            'PORT': secret_data.get('port', 3306),
            'OPTIONS': {
                'charset': 'utf8mb4',
                'sql_mode': 'STRICT_TRANS_TABLES',
                'init_command': "SET foreign_key_checks = 0;",
            },
        }
    except Exception as e:
        logger.error(f"Error getting RDS connection info: {e}")
        # Fallback to environment variables if secrets manager fails
        import os
        return {
            'ENGINE': 'django.db.backends.mysql',
            'NAME': os.getenv('DB_NAME', 'taskdb'),
            'USER': os.getenv('DB_USER', 'taskapp'),
            'PASSWORD': os.getenv('DB_PASSWORD', 'task@123'),
            'HOST': os.getenv('DB_HOST', 'localhost'),
            'PORT': os.getenv('DB_PORT', '3306'),
            'OPTIONS': {
                'charset': 'utf8mb4',
            },
        }

def get_django_secret_key(secret_name, region_name="us-east-1"):
    """
    Get Django secret key from AWS Secrets Manager
    """
    try:
        secret_data = get_secret(secret_name, region_name)
        return secret_data.get('django_secret_key')
    except Exception as e:
        logger.error(f"Error getting Django secret key: {e}")
        # Fallback to environment variable
        import os
        from django.core.management.utils import get_random_secret_key
        return os.getenv('SECRET_KEY', get_random_secret_key())
