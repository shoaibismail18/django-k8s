pipeline {
  agent {
    docker {
      image 'python:3.10-slim'
      args '--user root -v /var/run/docker.sock:/var/run/docker.sock'
    }
  }

  environment {
    DOCKER_IMAGE = "shoaibismail18/django-k8s:${BUILD_NUMBER}"
    SONAR_URL = "http://172.26.143.43:9000"
    GIT_REPO_NAME = "django-k8s"
    GIT_USER_NAME = "shoaibismail18"
  }

  stages {
    stage('Checkout') {
      steps {
        git branch: 'main', url: 'https://github.com/shoaibismail18/django-k8s.git'
      }
    }

    stage('Install Dependencies & Test') {
      steps {
        sh '''
          python -m pip install --upgrade pip
          pip install -r requirements.txt
          pip install pytest pytest-django
          pytest
        '''
      }
    }

    stage('Static Code Analysis') {
      steps {
        withCredentials([string(credentialsId: 'sonarqube', variable: 'SONAR_AUTH_TOKEN')]) {
          sh '''
            # Install Java, wget, unzip for sonar-scanner
            apt-get update -qq && apt-get install -y openjdk-11-jre-headless wget unzip
            
            # Download sonar-scanner CLI
            wget -q https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.8.0.2856-linux.zip
            
            # Unzip sonar-scanner
            unzip -q sonar-scanner-cli-4.8.0.2856-linux.zip
            
            # Add sonar-scanner to PATH
            export PATH=$PATH:$PWD/sonar-scanner-4.8.0.2856-linux/bin
            
            # Install coverage and run tests to generate coverage.xml
            pip install coverage
            coverage run manage.py test
            coverage xml
            
            # Run sonar-scanner analysis
            sonar-scanner \
              -Dsonar.projectKey=django-k8s \
              -Dsonar.sources=. \
              -Dsonar.host.url=${SONAR_URL} \
              -Dsonar.login=$SONAR_AUTH_TOKEN \
              -Dsonar.python.coverage.reportPaths=coverage.xml
          '''
        }
      }
    }

    stage('Build and Push Docker Image') {
      environment {
        REGISTRY_CREDENTIALS = credentials('docker-cred')
      }
      steps {
        script {
          sh 'docker build -t ${DOCKER_IMAGE} .'
          def dockerImage = docker.image("${DOCKER_IMAGE}")
          docker.withRegistry('https://index.docker.io/v1/', "docker-cred") {
            dockerImage.push()
          }
        }
      }
    }

    stage('Update Deployment File') {
      steps {
        withCredentials([string(credentialsId: 'github', variable: 'GITHUB_TOKEN')]) {
          sh '''
            git config user.email "shoaib@example.com"
            git config user.name "Shoaib Ismail"
            sed -i "s/replaceImageTag/${BUILD_NUMBER}/g" k8s/deployment.yml
            git add k8s/deployment.yml
            git commit -m "Update deployment image to version ${BUILD_NUMBER}"
            git push https://${GITHUB_TOKEN}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME} HEAD:main
          '''
        }
      }
    }
  }
}
