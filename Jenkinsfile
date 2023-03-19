pipeline {
    agent any
    stages {
        stage ('Tests') {
            steps {
                sh 'nix run nixpkgs#bash runtest.sh'
            }
        }
    }
}
