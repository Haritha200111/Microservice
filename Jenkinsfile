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
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_HUB_USER', passwordVariable: 'DOCKER_HUB_PSW')]) {
                    // Login once before pushing all images
                    bat """
                        echo %DOCKER_HUB_PSW% | docker login -u %DOCKER_HUB_USER% --password-stdin
                    """
                
                // Build and push images for each changed service
                    services.each { service ->
                        def imageName = "${env.REGISTRY}/${service}:${env.GIT_COMMIT_SHORT}"
                        bat """
                            docker build -t ${imageName} .\\services\\${service}
                            docker push ${imageName}
                        """
                    }

                // Logout after pushing all images (optional)
                    bat "docker logout"
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
