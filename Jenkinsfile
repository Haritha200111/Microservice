pipeline {
    agent any

    environment {
        REGISTRY = "docker.io/haritharavichandran"
        DOCKER_CREDS = credentials('dockerhub-creds')
        GIT_COMMIT_SHORT = ''
        CHANGED_SERVICES = ''
    }

    stages {
        stage('Fetch main branch') {
            steps {
                bat '''
                    git remote set-branches origin main
                    git fetch origin main
                '''
            }
        }

        stage('Get short commit hash') {
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
                    def changedFilesRaw = bat(script: 'git diff --name-only origin/main...HEAD', returnStdout: true).trim()
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
                        bat """
                            echo %DOCKER_HUB_PSW% | docker login -u %DOCKER_HUB_USER% --password-stdin
                        """

                        services.each { service ->
                            def imageName = "${env.REGISTRY}/${service}:${env.GIT_COMMIT_SHORT}"
                            bat """
                                docker build -t ${imageName} .\\services\\${service}
                                docker push ${imageName}
                            """
                        }

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
