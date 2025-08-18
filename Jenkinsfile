pipeline {
  agent any

  environment {
    REGISTRY = "docker.io/haritharavichandran"
    DOCKER_CREDS = credentials('dockerhub-creds')
    GIT_COMMIT_SHORT = ''
  }

  stages {
    stage('Debug Git Info') {
      steps {
        bat 'echo ==== Git Branches ==== && git branch -a'
        bat 'echo ==== Recent Commits ==== && git log --oneline -n 5'
      }
    }

    stage('Get Short Commit Hash') {
      steps {
        script {
          def commitHash = bat(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
          env.GIT_COMMIT_SHORT = commitHash
          echo "Short commit hash: ${env.GIT_COMMIT_SHORT}"
        }
      }
    }

    stage('Detect Changed Services') {
      steps {
        script {
          bat 'git fetch origin'
          def changed = bat(script: 'git diff --name-only origin/main...HEAD', returnStdout: true).trim()
          echo "Changed Files:\n${changed}"
          def servicesList = changed
            .tokenize('\r\n')
            .findAll { it.startsWith("services/") }
            .collect { it.split('/')[1] }
            .unique()
          env.CHANGED_SERVICES = servicesList.join(',')
          echo "Detected Changed Services: ${env.CHANGED_SERVICES ?: 'None'}"
        }
      }
    }

    stage('Build & Push Images') {
      when { expression { env.CHANGED_SERVICES?.trim() } }
      steps {
        script {
          def services = env.CHANGED_SERVICES.tokenize(',')
          withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_HUB_USER', passwordVariable: 'DOCKER_HUB_PSW')]) {
            bat "echo %DOCKER_HUB_PSW% | docker login -u %DOCKER_HUB_USER% --password-stdin"
            services.each { svc ->
              def img = "${env.REGISTRY}/${svc}:${env.GIT_COMMIT_SHORT}"
              echo "Building & Pushing image for: ${svc} → ${img}"
              bat """
                docker build -t ${img} services\\\\${svc}
                docker push ${img}
              """
            }
            bat "docker logout"
          }
        }
      }
    }

    stage('Deploy via Helm') {
      when { expression { env.CHANGED_SERVICES?.trim() } }
      steps {
        script {
          def svcs = env.CHANGED_SERVICES.tokenize(',')
          svcs.each { s ->
            echo "Deploying Helm release for: ${s}"
            bat """
              helm upgrade --install ${s} helm\\\\${s} ^
              --set image.repository=${env.REGISTRY}/${s} ^
              --set image.tag=${env.GIT_COMMIT_SHORT}
            """
          }
        }
      }
    }
  }
}
