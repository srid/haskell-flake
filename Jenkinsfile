// This pipeline uses Groovy functions from https://github.com/juspay/jenkins-nix-ci
pipeline {
    agent any
    stages {
        stage ('Dev Flake') {
            steps {
                nixBuildAll flakeDir: "./dev", overrideInputs: ["haskell-flake": "."]
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
