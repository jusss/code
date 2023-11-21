from django.urls import path
from . import views
urlpatterns = [
        path('', views.index, name='index'),
        path('add', views.add, name='add'),
        path('logout', views.logout_view, name='logout_view'),
        ]
