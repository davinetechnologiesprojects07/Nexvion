pipeline {
    agent any

    environment {
        LOCAL_IMAGE   = "nexvion"
        APP_CONTAINER = "nexvion-app"
        APP_PORT      = "8082"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Validate & Test') {
            steps {
                sh '''
                    set -e

                    for file in index.html products.html payment.html \
                                style.css products.css payment.css \
                                script.js payment.js logo.png
                    do
                        test -s "$file"
                        echo "[OK] $file"
                    done

                    bash -n scripts/*.sh
                '''
            }
        }

        stage('Security Check') {
            steps {
                sh '''
                    trivy fs \
                      --scanners vuln,secret \
                      --no-progress \
                      .
                '''
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    docker build -t ${LOCAL_IMAGE}:${BUILD_NUMBER} .
                '''
            }
        }

        stage('Image Scan') {
            steps {
                sh '''
                    trivy image \
                      --severity HIGH,CRITICAL \
                      --no-progress \
                      ${LOCAL_IMAGE}:${BUILD_NUMBER}
                '''
            }
        }

        stage('Publish Image') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub_cred',
                        usernameVariable: 'DOCKERHUB_USER',
                        passwordVariable: 'DOCKERHUB_PASS'
                    )
                ]) {
                    sh '''
                        IMAGE="${DOCKERHUB_USER}/nexvion"

                        docker tag ${LOCAL_IMAGE}:${BUILD_NUMBER} ${IMAGE}:${BUILD_NUMBER}
                        docker tag ${LOCAL_IMAGE}:${BUILD_NUMBER} ${IMAGE}:latest

                        echo "$DOCKERHUB_PASS" | docker login \
                          -u "$DOCKERHUB_USER" \
                          --password-stdin

                        docker push ${IMAGE}:${BUILD_NUMBER}
                        docker push ${IMAGE}:latest

                        docker logout
                    '''
                }
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    docker rm -f ${APP_CONTAINER} 2>/dev/null || true

                    docker run -d \
                      --name ${APP_CONTAINER} \
                      -p ${APP_PORT}:80 \
                      ${LOCAL_IMAGE}:${BUILD_NUMBER}
                '''
            }
        }

        stage('Health Verification') {
            steps {
                sh '''
                    for i in 1 2 3 4 5
                    do
                        if docker exec ${APP_CONTAINER} \
                           wget -q --spider http://localhost/
                        then
                            echo "Nexvion is healthy"
                            exit 0
                        fi

                        sleep 2
                    done

                    docker logs ${APP_CONTAINER}
                    exit 1
                '''
            }
        }
    }
}
