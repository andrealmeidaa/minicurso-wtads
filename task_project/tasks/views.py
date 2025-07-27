from django.shortcuts import render
from django.contrib.auth.mixins import LoginRequiredMixin
from django.views.generic import ListView, DetailView, CreateView, UpdateView, DeleteView
from django.urls import reverse_lazy
from django.contrib import messages
from django.db.models import Q
from .models import Task
from .forms import TaskForm


class TaskListView(LoginRequiredMixin, ListView):
    model = Task
    template_name = 'tasks/task_list.html'
    context_object_name = 'tasks'
    paginate_by = 10
    
    def get_queryset(self):
        queryset = Task.objects.filter(owner=self.request.user)
        search_query = self.request.GET.get('search')
        status_filter = self.request.GET.get('status')
        
        if search_query:
            queryset = queryset.filter(
                Q(title__icontains=search_query) | 
                Q(description__icontains=search_query)
            )
        
        if status_filter == 'completed':
            queryset = queryset.filter(completed=True)
        elif status_filter == 'pending':
            queryset = queryset.filter(completed=False)
            
        return queryset
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['search_query'] = self.request.GET.get('search', '')
        context['status_filter'] = self.request.GET.get('status', '')
        return context


class TaskDetailView(LoginRequiredMixin, DetailView):
    model = Task
    template_name = 'tasks/task_detail.html'
    context_object_name = 'task'
    
    def get_queryset(self):
        return Task.objects.filter(owner=self.request.user)


class TaskCreateView(LoginRequiredMixin, CreateView):
    model = Task
    form_class = TaskForm
    template_name = 'tasks/task_form.html'
    success_url = reverse_lazy('task-list')
    
    def form_valid(self, form):
        form.instance.owner = self.request.user
        messages.success(self.request, 'Task criada com sucesso!')
        return super().form_valid(form)
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['title'] = 'Criar Nova Task'
        context['button_text'] = 'Criar Task'
        return context


class TaskUpdateView(LoginRequiredMixin, UpdateView):
    model = Task
    form_class = TaskForm
    template_name = 'tasks/task_form.html'
    success_url = reverse_lazy('task-list')
    
    def get_queryset(self):
        return Task.objects.filter(owner=self.request.user)
    
    def form_valid(self, form):
        messages.success(self.request, 'Task atualizada com sucesso!')
        return super().form_valid(form)
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['title'] = 'Editar Task'
        context['button_text'] = 'Atualizar Task'
        return context


class TaskDeleteView(LoginRequiredMixin, DeleteView):
    model = Task
    template_name = 'tasks/task_confirm_delete.html'
    success_url = reverse_lazy('task-list')
    context_object_name = 'task'
    
    def get_queryset(self):
        return Task.objects.filter(owner=self.request.user)
    
    def delete(self, request, *args, **kwargs):
        messages.success(self.request, 'Task removida com sucesso!')
        return super().delete(request, *args, **kwargs)
