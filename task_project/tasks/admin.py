from django.contrib import admin
from .models import Task


@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
    list_display = ['title', 'owner', 'completed', 'due_date', 'created_at']
    list_filter = ['completed', 'created_at', 'due_date', 'owner']
    search_fields = ['title', 'description']
    list_editable = ['completed']
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Informações Básicas', {
            'fields': ('title', 'description', 'owner')
        }),
        ('Status e Datas', {
            'fields': ('completed', 'due_date')
        }),
    )
    
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        return qs.filter(owner=request.user)
