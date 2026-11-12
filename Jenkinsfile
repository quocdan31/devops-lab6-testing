pipeline {
    agent any

    environment {
        PROJECT_KEY = 'devops-lab6'
        TARGET_URL  = 'http://127.0.0.1:3000'
        ZAP_URL     = 'http://127.0.0.1:8080'
    }

    stages {
        stage('Install Dependencies') {
            steps {
                sh 'npm ci'
            }
        }

        stage('SAST - SonarQube Scan') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh 'npx sonar-scanner -Dsonar.projectKey=${PROJECT_KEY} -Dsonar.sources=.'
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: false
                }
            }
        }

        stage('API Functional Test - Newman') {
            steps {
                sh '''
                    node server.js &
                    SERVER_PID=$!
                    trap "kill $SERVER_PID 2>/dev/null || true" EXIT
                    sleep 2
                    npx newman run Student-API-Tests.json --reporters cli,json --reporter-json-export newman-report.json
                '''
            }
        }

        stage('DAST - OWASP ZAP Scan') {
            steps {
                sh '''
                    bash ci-test.sh
                '''
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'newman-report.json,zap-report.html', allowEmptyArchive: true
        }
    }
}
