pipeline {
    agent any

    environment {
        REGISTRY = "docker.io/haritharavichandran" // Docker Hub username
        DOCKER_CREDS = credentials('dockerhub-creds') // Jenkins Docker Hub credentials ID
        // For Windows, use 'bat' to run git command and capture output:
        GIT_COMMIT_SHORT = ''
    }

    stages {
        stage('Get short commit hash') {
            steps {
                script {
                    // Capture short commit hash on Windows using bat
                    def commitHash = bat(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    env.GIT_COMMIT_SHORT = commitHash
                    echo "Short commit hash: ${env.GIT_COMMIT_SHORT}"
                }
            }
        }

        stage('Detect Changed Services') {
            steps {
                script {
                    // Detect changed files between HEAD~1 and HEAD on Windows
                    def changedFilesRaw = bat(script: 'git diff --name-only HEAD~1 HEAD', returnStdout: true).trim()
                    def changedFiles = changedFilesRaw.tokenize('\r\n')
                    def changedServices = changedFiles
                        .findAll { it.startsWith("services/") }
                        .collect { it.split("/")[1] }
                        .unique()
                    env.CHANGED_SERVICES = changedServices.join(',')
                    echo "Changed services: ${env.CHANGED_SERVICES}"
                }
            }
        }

        stage('Build and Push Images') {
            when {
                expression { env.CHANGED_SERVICES && env.CHANGED_SERVICES != '' }
            }
            steps {
                script {
                    def services = env.CHANGED_SERVICES.tokenize(',')
                    docker.withRegistry("https://${env.REGISTRY}", "dockerhub-creds") {
                        services.each { service ->
                            bat """
                                docker build -t ${env.REGISTRY}/${service}:${env.GIT_COMMIT_SHORT} .\\services\\${service}
                                docker push ${env.REGISTRY}/${service}:${env.GIT_COMMIT_SHORT}
                            """
                        }
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            when {
                expression { env.CHANGED_SERVICES && env.CHANGED_SERVICES != '' }
            }
            steps {
                script {
                    def services = env.CHANGED_SERVICES.tokenize(',')
                    services.each { service ->
                        bat """
                            helm upgrade --install ${service} .\\helm\\${service} ^
                            --set image.repository=${env.REGISTRY}/${service} ^
                            --set image.tag=${env.GIT_COMMIT_SHORT}
                        """
                    }
                }
            }
        }
    }
}
