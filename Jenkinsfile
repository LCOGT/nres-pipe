#!/usr/bin/env groovy

@Library('lco-shared-libs@0.0.6') _

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
			steps {
				script {
					withCredentials([usernamePassword(
							credentialsId: 'rabbit-mq',
							usernameVariable: 'RABBITMQ_USER',
							passwordVariable: 'RABBITMQ_PASSWORD')]) {
						sh('rancher -c ${DEV_CREDS} up --stack NRESPipelineTest --force-upgrade --confirm-upgrade -d')
						sh('echo "Got here".')
					}
				}
			}
		}
		stage('Test'){
			when {
				anyOf {
					branch 'PR-*'
					expression { return params.forceEndToEnd }
				}
			}
			environment {
				RANCHERDEV_CREDS = credentials('rancher-cli-dev')
				SSH_CREDS = credentials('jenkins-rancher-ssh-userpass')
				CONTAINER_ID = getContainerId('NRESPipelineTest-NRESPipelineTest-1')
				CONTAINER_HOST = getContainerHostName('NRESPipelineTest-NRESPipelineTest-1')
			}
			steps {
				sshagent(credentials: ['jenkins-rancher-ssh']) {
				    executeOnRancher('/bin/true', CONTAINER_HOST, CONTAINER_ID)
				}
			}
		}
	}
}

