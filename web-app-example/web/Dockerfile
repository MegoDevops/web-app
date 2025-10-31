# استخدم base image مناسب للـ Node.js
FROM node:10.24.1

# أنشئ مجلد العمل
WORKDIR /app

# انسخ package.json و package-lock.json أو yarn.lock لو موجود
COPY package*.json ./
# COPY yarn.lock ./   # لو بتستخدم Yarn

# ثبت الـ dependencies
RUN npm install
# RUN yarn install   # لو بتستخدم Yarn

# انسخ باقي ملفات المشروع
COPY . .

# كشف البورت اللي هيتشغل عليه
EXPOSE 8080

# ضع environment variables لو محتاج
ENV NODE_ENV=production

# أمر تشغيل التطبيق
CMD ["npm", "run", "serve"]
