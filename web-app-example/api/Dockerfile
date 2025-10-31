# استخدم base image للـ Python
FROM python:3.10.5

# إنشاء مجلد العمل
WORKDIR /app

# نسخ ملفات المشروع الأساسية
COPY requirements.txt ./
# لو عندك Pipfile أو poetry.lock ممكن تستخدمهم بدل requirements.txt

# تثبيت الـ dependencies
RUN pip install --upgrade pip==22.0.4 setuptools==58.1.0 \
    && pip install -r requirements.txt

# نسخ باقي ملفات المشروع
COPY . .

# كشف البورت
EXPOSE 8080

# وضع environment variables
ENV DB_PASSWORD=postgres
ENV DB_NAME=postgres
ENV DB_HOST=db
ENV DB_PORT=5432
ENV DB_USER=postgres
ENV LANG=C.UTF-8

# أمر تشغيل التطبيق
CMD ["gunicorn", "app:app", "-b", "0.0.0.0:8080", "--log-file", "-", "--access-logfile", "-", "--workers", "4", "--keep-alive", "0"]
