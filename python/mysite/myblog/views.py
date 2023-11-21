from django.shortcuts import render, redirect
from .forms import BlogForm
from django.http import HttpResponse
from django.contrib.auth import logout
from django.contrib.auth.decorators import login_required
from .models import Blog

@login_required(login_url = "/account/login/")
def index(request) :
    # return render(request, 'myblog/index.html', {'blog_list': Blog.objects.all(), 'user': current_user})
    return render(request, 'myblog/index.html', {'blog_list': Blog.objects.filter(author=request.user), 'user': request.user})

@login_required(login_url="/account/login/")
def add(request) :
    if request.method == "POST":
        form = BlogForm(request.POST)
        if form.is_valid():
            obj = form.save(commit=False)
            obj.author = request.user
            obj.save()
        else:
            return HttpResponse('post failed')
        return redirect("/myblog")

    if request.method == "GET":
        form = BlogForm()
        return render(request, 'myblog/add.html',{'blog_List': Blog.objects.filter(author=request.user), "form": form, 'user': request.user})

def logout_view(request):
    logout(request)
    return HttpResponse('logout done!')

