FROM python:3.11-slim

WORKDIR /app

# Install dependencies for SonarScanner and curl
RUN apt-get update && apt-get install -y curl unzip openjdk-11-jre-headless && rm -rf /var/lib/apt/lists/*

# Install SonarScanner CLI
RUN curl -sSLo sonar-scanner.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.8.0.2856-linux.zip \
    && unzip sonar-scanner.zip -d /opt \
    && rm sonar-scanner.zip

ENV PATH="/opt/sonar-scanner-4.8.0.2856-linux/bin:${PATH}"

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["gunicorn", "django_k8s.wsgi:application", "--bind", "0.0.0.0:8000"]
