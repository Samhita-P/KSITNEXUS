# Generated manually for chatbot app

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('accounts', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='ChatbotCategory',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=100, unique=True)),
                ('description', models.TextField(blank=True, null=True)),
                ('icon', models.CharField(blank=True, max_length=50, null=True)),
                ('is_active', models.BooleanField(default=True)),
                ('order', models.IntegerField(default=0)),
            ],
            options={
                'verbose_name_plural': 'Chatbot Categories',
                'ordering': ['order', 'name'],
            },
        ),
        migrations.CreateModel(
            name='ChatbotQuestion',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('question', models.TextField()),
                ('answer', models.TextField()),
                ('keywords', models.JSONField(blank=True, default=list)),
                ('tags', models.JSONField(blank=True, default=list)),
                ('is_active', models.BooleanField(default=True)),
                ('priority', models.IntegerField(default=0)),
                ('usage_count', models.IntegerField(default=0)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('category', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='questions', to='chatbot.chatbotcategory')),
            ],
            options={
                'ordering': ['-priority', '-usage_count', 'question'],
            },
        ),
        migrations.CreateModel(
            name='ChatbotSession',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('session_id', models.CharField(max_length=100, unique=True)),
                ('ip_address', models.GenericIPAddressField(blank=True, null=True)),
                ('user_agent', models.TextField(blank=True, null=True)),
                ('is_active', models.BooleanField(default=True)),
                ('ended_at', models.DateTimeField(blank=True, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('user', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, related_name='chatbot_sessions', to='accounts.user')),
            ],
            options={
                'ordering': ['-created_at'],
            },
        ),
        migrations.CreateModel(
            name='ChatbotMessage',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('message_type', models.CharField(choices=[('user', 'User Message'), ('bot', 'Bot Response'), ('system', 'System Message')], max_length=10)),
                ('content', models.TextField()),
                ('confidence_score', models.FloatField(blank=True, null=True)),
                ('is_helpful', models.BooleanField(blank=True, null=True)),
                ('feedback_comment', models.TextField(blank=True, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('related_question', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='messages', to='chatbot.chatbotquestion')),
                ('session', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='messages', to='chatbot.chatbotsession')),
            ],
            options={
                'ordering': ['created_at'],
            },
        ),
        migrations.CreateModel(
            name='ChatbotFeedback',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('rating', models.IntegerField(choices=[(1, '1 - Not Helpful'), (2, '2 - Slightly Helpful'), (3, '3 - Moderately Helpful'), (4, '4 - Very Helpful'), (5, '5 - Extremely Helpful')])),
                ('comment', models.TextField(blank=True, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('message', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='feedback', to='chatbot.chatbotmessage')),
                ('user', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='chatbot_feedback', to='accounts.user')),
            ],
            options={
                'ordering': ['-created_at'],
            },
        ),
        migrations.CreateModel(
            name='ChatbotAnalytics',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('date', models.DateField()),
                ('total_sessions', models.IntegerField(default=0)),
                ('total_messages', models.IntegerField(default=0)),
                ('unique_users', models.IntegerField(default=0)),
                ('most_asked_questions', models.JSONField(blank=True, default=list)),
                ('unanswered_questions', models.JSONField(blank=True, default=list)),
                ('average_response_time', models.FloatField(default=0.0)),
                ('average_rating', models.FloatField(default=0.0)),
                ('resolution_rate', models.FloatField(default=0.0)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
            ],
            options={
                'ordering': ['-date'],
            },
        ),
        migrations.AlterUniqueTogether(
            name='chatbotanalytics',
            unique_together={('date',)},
        ),
    ]