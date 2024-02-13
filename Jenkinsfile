// This pipeline uses Groovy functions from https://github.com/juspay/jenkins-nix-ci
pipeline {
    agent any
    stages {
        stage ('NixCI') {
            steps {
                nixCI system: env.SYSTEM
            }
        }
        // TODO: Do this as part of dev
        stage ('Tests') {
            steps {
                sh 'nix run nixpkgs#bash runtest.sh'
            }
        }
    }
}
