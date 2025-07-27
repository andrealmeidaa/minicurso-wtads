from django import forms
from django.forms.widgets import DateTimeInput
from .models import Task


class TaskForm(forms.ModelForm):
    class Meta:
        model = Task
        fields = ['title', 'description', 'due_date', 'completed']
        widgets = {
            'title': forms.TextInput(attrs={
                'class': 'input',
                'placeholder': 'Digite o título da task...'
            }),
            'description': forms.Textarea(attrs={
                'class': 'textarea',
                'placeholder': 'Descrição detalhada da task (opcional)...',
                'rows': 4
            }),
            'due_date': DateTimeInput(attrs={
                'type': 'datetime-local',
                'class': 'input'
            }),
            'completed': forms.CheckboxInput(attrs={
                'class': 'checkbox'
            })
        }
        labels = {
            'title': 'Título',
            'description': 'Descrição',
            'due_date': 'Data de Vencimento',
            'completed': 'Concluída'
        }
        help_texts = {
            'title': 'Título descritivo para sua task',
            'description': 'Descrição detalhada (opcional)',
            'due_date': 'Data e hora limite para conclusão (opcional)',
            'completed': 'Marque se a task já foi concluída'
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # Tornar todos os campos opcionais exceto o título
        for field in self.fields:
            if field != 'title':
                self.fields[field].required = False
