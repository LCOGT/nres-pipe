#!/usr/bin/env groovy

@Library('lco-shared-libs@0.0.2') _

pipeline {
	agent any
	environment {
		dockerImage = null
		PROJ_NAME = projName("${JOB_NAME}")
		GIT_DESCRIPTION = gitDescription()
		DOCKER_IMG = dockerImageName("${LCO_DOCK_REG}", "${PROJ_NAME}", "${GIT_DESCRIPTION}")
	}
	options {
		timeout(time: 3, unit: 'HOURS')
	}
	stages {
		stage('Build image') {
			steps {
				script {
					dockerImage = docker.build("${DOCKER_IMG}")
				}
			}
		}
		stage('Push image') {
			steps {
				script {
					dockerImage.push("${GIT_DESCRIPTION}")
				}
			}
		}
		stage('Deploy') {
			when {
				anyOf {
					branch 'PR-*'
					expression { return params.forceEndToEnd }
				}
			}
			environment {
				DEV_CREDS = credentials('rancher-cli-dev')
			}
			script {
					sh('''echo $DEV_CREDS
                       #rancher -c ${DEV_CREDS} up --stack NRESPipelineTest --force-upgrade --confirm-upgrade -d''')
			}
		}
	}
}
