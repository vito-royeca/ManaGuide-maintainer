pipeline {
    agent any

    parameters {
        string(name: 'HOST', defaultValue: 'localhost', description: 'Database hostname or IP address')
        string(name: 'PORT', defaultValue: '5432', description: 'Database port')
        string(name: 'DATABASE', defaultValue: 'database', description: 'Database name')
        string(name: 'USERNAME', defaultValue: 'user', description: 'Database user')
        password(name: 'PASSWORD', defaultValue: 'secret', description: 'Enter a password')
        booleanParam(name: 'FULL_UPDATE', defaultValue: false, description: 'Perform a full update or not')
        string(name: 'IMAGES_PATH', defaultValue: '/mnt/managuide_images/cards', description: 'Path to the card image files')
        string(name: 'IMAGES_OWNER', defaultValue: 'user', description: 'User who has RW access to the card image files')
    }

    stages {
        stage('Preparation') {
            steps {
                // Get some code from a GitHub repository
                git 'https://github.com/vito-royeca/ManaGuide-maintainer.git'
            }
        }
        stage('Build') {
            steps {
                echo 'Building..'
                sh '~/.local/share/swiftly/bin/swift build -c release'
            }
        }
        stage('Run') {
            steps {
                echo 'Running...'
                withCredentials([string(credentialsId: 'masked-string', variable: 'STRING')]) {
                    sh("sudo -u ${params.IMAGES_OWNER} sh -c '.build/release/managuide \
                            --host ${params.HOST} \
                            --port ${params.PORT} \
                            --database ${params.DATABASE} \
                            --user ${params.USERNAME} \
                            --password ${params.PASSWORD} \
                            --full-update ${params.FULL_UPDATE} \
                            --images-path ${params.IMAGES_PATH}'")
                }
            }
        }
    }
}
