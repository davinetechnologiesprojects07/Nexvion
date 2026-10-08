pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    triggers {
        pollSCM('H/2 * * * *')
    }

    environment {
        DOCKERHUB_USER = 'richieit'
        IMAGE_NAME     = "${DOCKERHUB_USER}/nexvion"
        IMAGE_TAG      = "${env.BUILD_NUMBER}"
        CI_CONTAINER   = 'nexvion-ci'
        CI_PORT        = '8089'
        AWS_HOST       = '54.147.106.107'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'git log --oneline -1'
            }
        }

        stage('Validate') {
            steps {
                sh '''
                    set -e
                    for f in app/index.html app/products.html app/payment.html \
                             app/style.css app/script.js docker/Dockerfile docker/nginx.conf; do
                        test -f "$f" || { echo "Missing $f"; exit 1; }
                    done
                    echo "Required files present"
                '''
            }
        }

        stage('Build Image') {
            steps {
                sh '''
                    docker build -f docker/Dockerfile \
                        -t ${IMAGE_NAME}:${IMAGE_TAG} \
                        -t ${IMAGE_NAME}:latest .
                '''
            }
        }

        stage('Test Config') {
            steps {
                sh 'docker run --rm --entrypoint nginx ${IMAGE_NAME}:${IMAGE_TAG} -t'
            }
        }

        stage('Security Scan') {
            steps {
                sh '''
                    echo "== Gitleaks: secret scan (fails on any leak) =="
                    docker run --rm -v jenkins_jenkins_home:/var/jenkins_home:ro \
                        zricethezav/gitleaks:latest detect --source "${WORKSPACE}" --redact --exit-code 1

                    echo "== Trivy: image report (HIGH and CRITICAL) =="
                    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v trivy-cache:/root/.cache \
                        aquasec/trivy:latest image --severity HIGH,CRITICAL --ignore-unfixed --quiet ${IMAGE_NAME}:${IMAGE_TAG}

                    echo "== Trivy: image gate (fails on CRITICAL) =="
                    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v trivy-cache:/root/.cache \
                        aquasec/trivy:latest image --severity CRITICAL --ignore-unfixed --exit-code 1 --quiet ${IMAGE_NAME}:${IMAGE_TAG}

                    echo "== Trivy: config report (docker, k8s, helm) =="
                    for d in docker k8s helm; do
                        docker run --rm -v jenkins_jenkins_home:/var/jenkins_home:ro -v trivy-cache:/root/.cache \
                            aquasec/trivy:latest config --severity HIGH,CRITICAL --quiet "${WORKSPACE}/$d"
                    done
                '''
            }
        }

        stage('Push Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds',
                                                  usernameVariable: 'DH_USER',
                                                  passwordVariable: 'DH_PASS')]) {
                    sh '''
                        echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${IMAGE_NAME}:latest
                        docker logout
                    '''
                }
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    docker rm -f ${CI_CONTAINER} 2>/dev/null || true
                    docker run -d --name ${CI_CONTAINER} \
                        -p ${CI_PORT}:8080 \
                        --restart unless-stopped \
                        ${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }

        stage('Verify') {
            steps {
                sh '''
                    for i in 1 2 3 4 5 6 7 8 9 10; do
                        if docker exec ${CI_CONTAINER} wget -qO- http://127.0.0.1:8080/healthz | grep -q ok; then
                            echo "Deployment healthy"
                            exit 0
                        fi
                        echo "Waiting for app... ($i)"
                        sleep 3
                    done
                    docker logs ${CI_CONTAINER}
                    exit 1
                '''
            }
        }

        stage('Deploy to AWS') {
            steps {
                catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                    withCredentials([sshUserPrivateKey(credentialsId: 'nexvion-aws-key',
                                                       keyFileVariable: 'SSH_KEY',
                                                       usernameVariable: 'SSH_USER')]) {
                        sh '''
                            ssh -i "$SSH_KEY" -o StrictHostKeyChecking=accept-new -o ConnectTimeout=15 \
                                "$SSH_USER@${AWS_HOST}" \
                                "cd /opt/nexvion && NEXVION_TAG=${IMAGE_TAG} docker compose up -d --pull always"
                            for i in 1 2 3 4 5 6 7 8 9 10; do
                                if curl -fs --max-time 5 http://${AWS_HOST}/healthz | grep -q ok; then
                                    echo "AWS deployment healthy"
                                    exit 0
                                fi
                                sleep 3
                            done
                            echo "AWS health check failed"
                            exit 1
                        '''
                    }
                }
            }
        }
    }

    post {
        success { echo "Nexvion ${IMAGE_TAG} deployed on port ${CI_PORT}" }
        failure { echo 'Pipeline failed. Check the stage logs above.' }
        always  { sh 'docker image prune -f || true' }
    }
}
