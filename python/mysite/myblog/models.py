from django.db import models
from django.contrib.auth.models import User
from django.conf import settings
from uuid import uuid4

# Create your models here.

class Blog(models.Model):
    title = models.CharField(max_length=200)
    content = models.TextField()
    author = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, null=True)
    article_id = models.UUIDField(primary_key=True, default=uuid4, editable=False)
    created_time = models.DateTimeField(auto_now_add=True)
    changed_time = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.title
