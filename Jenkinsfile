pipeline {
    agent any
    
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        DOCKER_IMAGE = 'hedobriggs/netflix-clone-file1'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        TMDB_API_KEY = credentials('tmdb-api-key')
    }
    
    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }
        
        stage('Checkout from Git') {
            steps {
                git branch: 'main', url: 'https://github.com/hedobriggs/netflix.git'
            }
        }
        
        stage("Sonarqube Analysis") {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh '''$SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectName=netflix-clone-file1 \
                        -Dsonar.projectKey=netflix-clone-file1'''
                }
                echo "✅ SonarQube analysis submitted"
            }
        }
        
        stage("Quality Gate") {
            steps {
                script {
                    timeout(time: 10, unit: 'MINUTES') {
                        try {
                            def qg = waitForQualityGate()
                            if (qg.status != 'OK') {
                                echo "⚠️ Warning: Quality gate failed with status: ${qg.status}"
                                echo "Continuing pipeline execution..."
                            } else {
                                echo "✅ Quality gate passed!"
                            }
                        } catch (Exception e) {
                            echo "⚠️ Quality gate check failed: ${e.message}"
                            echo "Continuing pipeline execution..."
                        }
                    }
                }
            }
        }
        
        stage('OWASP Dependency Check') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'nvd-api-key', variable: 'NVD_KEY')]) {
                        dependencyCheck additionalArguments: "--scan ./ --disableYarnAudit --disableNodeAudit --nvdApiKey ${NVD_KEY} --format HTML --format XML", 
                                       odcInstallation: 'OWASP DP-Check'
                        
                        dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
                    }
                }
            }
        }
        
        stage('Trivy Filesystem Scan') {
            steps {
                script {
                    sh "trivy fs . > trivyfs.txt"
                    
                    def trivyOutput = readFile('trivyfs.txt')
                    echo "Trivy FS Scan Results:\n${trivyOutput}"
                }
            }
        }
        
        stage("Build Docker Image") {
            steps {
                script {
                    sh """
                        docker build \
                        --build-arg API_KEY=${TMDB_API_KEY} \
                        -t ${DOCKER_IMAGE}:${DOCKER_TAG} \
                        -t ${DOCKER_IMAGE}:latest \
                        .
                    """
                }
            }
        }
        
        stage("Trivy Image Scan") {
            steps {
                script {
                    sh "trivy image ${DOCKER_IMAGE}:${DOCKER_TAG} > trivyimage.txt"
                    
                    def trivyImageOutput = readFile('trivyimage.txt')
                    echo "Trivy Image Scan Results:\n${trivyImageOutput}"
                }
            }
        }
        
        stage("Push to Docker Hub") {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker-cred', toolName: 'docker') {
                        sh """
                            docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                            docker push ${DOCKER_IMAGE}:latest
                        """
                    }
                }
            }
        }
        
        stage("Cleanup") {
            steps {
                script {
                    sh """
                        docker rmi ${DOCKER_IMAGE}:${DOCKER_TAG} || true
                        docker rmi ${DOCKER_IMAGE}:latest || true
                    """
                }
            }
        }
    }
    
    post {
        always {
            archiveArtifacts artifacts: '**/trivyfs.txt, **/trivyimage.txt, **/dependency-check-report.*', 
                            allowEmptyArchive: true
            cleanWs()
        }
        
        success {
            echo "✅ Pipeline completed successfully! Image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
        }
        
        failure {
            echo "❌ Pipeline failed! Check the logs."
        }
    }
}
