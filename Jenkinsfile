pipeline {
  agent any
  stages {
    stage("Checkout Code") {
      steps {
        checkout scm
      }
    }

    stage("PUSH - IMAGE - MASTER") {
      when { branch "master" }
      steps {

        script {
          def app
          docker.withRegistry("https://registry-tmp.devops-ci", "registry-devops-ci-login") {
            app = docker.build("swampfox/thirdparty/pgFormatter")
            app.push("4.4-${env.BUILD_ID}")
            app.push("latest")
          }
        }

      }
    }

    stage("PUSH - IMAGE - TAG") {
      when { buildingTag() }
      steps {

        script {
          def app
          docker.withRegistry("https://registry.devops-ci", "registry-devops-ci-login") {
            app = docker.build("swampfox/thirdparty/pgFormatter")
            app.push("${env.TAG_Name}")
            app.push("latest")
          }
        }
      }
    }
  }
}
