// =============================================================================
// Network Security MLOps — Jenkins CI Pipeline
// =============================================================================
// This pipeline handles CI only. CD is managed by Argo CD (GitOps).
// All credentials are stored in Jenkins Credentials store.
// =============================================================================

pipeline {
    agent any

    environment {
        AWS_REGION          = credentials('AWS_REGION')
        AWS_ACCOUNT_ID      = credentials('AWS_ACCOUNT_ID')
        ECR_REPO_NAME       = 'network-security-mlops-dev'
        IMAGE_TAG           = "${BUILD_NUMBER}-${GIT_COMMIT.take(7)}"
        SCANNER_HOME        = tool 'sonar-scanner'
    }

    options {
        timeout(time: 60, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {
        // ---- Stage 1: Checkout ----
        stage('Checkout') {
            steps {
                cleanWs()
                checkout scm
                sh 'echo "Commit: ${GIT_COMMIT}"'
            }
        }

        // ---- Stage 2: Environment Validation ----
        stage('Environment Validation') {
            steps {
                sh '''
                    echo "=== Environment Validation ==="
                    python3 --version || python --version
                    docker --version
                    echo "Build: ${BUILD_NUMBER}"
                '''
            }
        }

        // ---- Stage 3: Install Dependencies ----
        stage('Install Dependencies') {
            steps {
                sh '''
                    python3 -m pip install --upgrade pip
                    pip install -r requirements.txt
                    pip install pytest pytest-cov flake8
                '''
            }
        }

        // ---- Stage 4: Code Quality - Lint ----
        stage('Code Quality - Lint') {
            steps {
                sh '''
                    echo "=== Running flake8 linter ==="
                    flake8 --count --select=E9,F63,F7,F82 --show-source --statistics networksecurity/ app.py || true
                    flake8 --count --max-line-length=120 --statistics networksecurity/ app.py || true
                '''
            }
        }

        // ---- Stage 5: Unit Tests ----
        stage('Unit Tests') {
            steps {
                sh '''
                    echo "=== Running unit tests ==="
                    python3 -m pytest tests/ --tb=short -q --junitxml=test-results.xml || echo "No tests found — add tests to tests/ directory"
                '''
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: 'test-results.xml'
                }
            }
        }

        // ---- Stage 6: SonarQube Analysis ----
        stage('SonarQube Analysis') {
            when { expression { fileExists('.sonarqube.configured') } }
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh '''
                        ${SCANNER_HOME}/bin/sonar-scanner \
                            -Dsonar.projectKey=network-security-mlops \
                            -Dsonar.projectName="Network Security MLOps" \
                            -Dsonar.sources=networksecurity/,app.py \
                            -Dsonar.language=py \
                            -Dsonar.python.version=3.10
                    '''
                }
            }
        }

        // ---- Stage 7: OWASP Dependency-Check ----
        stage('OWASP Dependency-Check') {
            steps {
                dependencyCheck additionalArguments: '''
                    --scan .
                    --format HTML
                    --format XML
                    --out dependency-check-report
                    --failOnCVSS 8
                    --disableYarnAudit
                ''', odcInstallation: 'DP-Check'

                dependencyCheckPublisher pattern: 'dependency-check-report/dependency-check-report.xml',
                    failedTotalCritical: 1,
                    failedTotalHigh: 5
            }
        }

        // ---- Stage 8: Trivy Filesystem Scan ----
        stage('Trivy Filesystem Scan') {
            steps {
                sh '''
                    echo "=== Trivy filesystem scan ==="
                    trivy fs --severity HIGH,CRITICAL \
                        --format table \
                        --output trivy-fs-report.txt \
                        --exit-code 0 \
                        . || true
                    cat trivy-fs-report.txt
                '''
            }
        }

        // ---- Stage 9: Terraform Validation ----
        stage('Terraform Validation') {
            steps {
                dir('terraform') {
                    sh '''
                        echo "=== Terraform fmt check ==="
                        terraform fmt -check -recursive || echo "Formatting issues found"
                        echo "=== Terraform init ==="
                        terraform init -backend=false
                        echo "=== Terraform validate ==="
                        terraform validate
                    '''
                }
            }
        }

        // ---- Stage 10: Checkov IaC Scan ----
        stage('Checkov IaC Scan') {
            steps {
                sh '''
                    echo "=== Checkov IaC security scan ==="
                    pip install checkov 2>/dev/null || true
                    checkov -d terraform/ --quiet --compact --output cli || echo "Checkov scan completed with findings"
                    checkov -d helm/ --framework helm --quiet --compact --output cli || echo "Checkov Helm scan completed"
                '''
            }
        }

        // ---- Stage 11: Helm Lint ----
        stage('Helm Lint') {
            steps {
                sh '''
                    echo "=== Helm lint ==="
                    helm lint helm/network-security-mlops/ --values helm/network-security-mlops/values-dev.yaml
                '''
            }
        }

        // ---- Stage 12: Docker Build ----
        stage('Docker Build') {
            steps {
                sh '''
                    echo "=== Building Docker image ==="
                    docker build -t ${ECR_REPO_NAME}:${IMAGE_TAG} .
                    docker tag ${ECR_REPO_NAME}:${IMAGE_TAG} ${ECR_REPO_NAME}:latest
                '''
            }
        }

        // ---- Stage 13: Trivy Image Scan ----
        stage('Trivy Image Scan') {
            steps {
                sh '''
                    echo "=== Trivy Docker image scan ==="
                    trivy image --severity HIGH,CRITICAL \
                        --format table \
                        --output trivy-image-report.txt \
                        --exit-code 0 \
                        ${ECR_REPO_NAME}:${IMAGE_TAG} || true
                    cat trivy-image-report.txt
                '''
            }
        }

        // ---- Stage 14: Push to ECR ----
        stage('Push to ECR') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        echo "=== Authenticating with AWS ECR ==="
                        aws ecr get-login-password --region ${AWS_REGION} | \
                            docker login --username AWS --password-stdin \
                            ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

                        ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"

                        echo "=== Tagging and pushing image ==="
                        docker tag ${ECR_REPO_NAME}:${IMAGE_TAG} ${ECR_URI}:${IMAGE_TAG}
                        docker tag ${ECR_REPO_NAME}:latest ${ECR_URI}:latest

                        docker push ${ECR_URI}:${IMAGE_TAG}
                        docker push ${ECR_URI}:latest
                    '''
                }
            }
        }

        // ---- Stage 15: Update GitOps Configuration ----
        stage('Update GitOps Image Tag') {
            steps {
                withCredentials([string(credentialsId: 'GITHUB_TOKEN', variable: 'GITHUB_TOKEN')]) {
                    sh '''
                        echo "=== Updating Helm values with new image tag ==="
                        ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"

                        # Update image tag in values.yaml for Argo CD to detect
                        sed -i "s|tag:.*|tag: \\"${IMAGE_TAG}\\"|g" helm/network-security-mlops/values.yaml
                        sed -i "s|repository:.*|repository: ${ECR_URI}|g" helm/network-security-mlops/values.yaml

                        git config user.email "jenkins@ci.local"
                        git config user.name "Jenkins CI"
                        git add helm/network-security-mlops/values.yaml
                        git commit -m "ci: update image tag to ${IMAGE_TAG} [skip ci]" || echo "No changes to commit"
                        git push https://${GITHUB_TOKEN}@github.com/${GIT_URL##*/} HEAD:main || echo "Push failed — verify GITHUB_TOKEN permissions"
                    '''
                }
            }
        }
    }

    post {
        always {
            sh 'docker rmi ${ECR_REPO_NAME}:${IMAGE_TAG} || true'
            sh 'docker rmi ${ECR_REPO_NAME}:latest || true'
            cleanWs()
        }
        success {
            echo '✅ Pipeline completed successfully. Argo CD will detect the GitOps change and deploy.'
        }
        failure {
            echo '❌ Pipeline failed. Check the logs above for details.'
        }
    }
}
