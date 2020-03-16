#!/usr/bin/env groovy

@Library('lco-shared-libs@0.0.9') _

pipeline {
	agent any
	environment {
		dockerImage = null
		PROJ_NAME = projName()
		GIT_DESCRIPTION = gitDescribe()
		DOCKER_IMG = dockerImageName("${LCO_DOCK_REG}", "${PROJ_NAME}", "${GIT_DESCRIPTION}")
		RANCHERDEV_CREDS = credentials('rancher-cli-dev')
		SSH_CREDS = credentials('jenkins-rancher-ssh-userpass')
		ARCHIVE_UID = credentials('archive-userid')
	}
	options {
		timeout(time: 12, unit: 'HOURS')
		lock resource: 'IDLLock'
	}
	stages {
		stage("Build image") {
			steps {
				script {
					dockerImage = docker.build("${DOCKER_IMG}")
				}
			}
		}
		stage("Push image") {
			steps {
				script {
					dockerImage.push("${GIT_DESCRIPTION}")
				}
			}
		}
		stage("DeployTestStack") {
			when {
				anyOf {
					branch "PR-*"
					expression { return params.forceEndToEnd }
				}
			}
	        steps {
	            script {
                    withKubeConfig([credentialsId: "dev-kube-config"]) {
                        sh('helm repo update && helm upgrade --install nres-pipe lco/nres-pipe ' +
                                '--set nresPipeline.tag="${GIT_DESCRIPTION}" --namespace dev --wait --timeout=3600')

                        podName = sh(script: 'kubectl -n dev get po -l app.kubernetes.io/instance=nres-pipe ' +
                                        '--sort-by=.status.startTime -o jsonpath="{.items[-1].metadata.name}"',
                                     returnStdout: true).trim()

                    }
                 }
		    }
		}
		stage("Test-Bias-Ingestion") {
			when {
				anyOf {
					branch "PR-*"
					expression { return params.forceEndToEnd }
				}
			}
			steps {
				script {
                    withKubeConfig([credentialsId: "dev-kube-config"]) {
						sh("kubectl exec -c nres-pipeline ${podName} -- " +
						        "/usr/bin/sudo -s -E -u archive /opt/conda/bin/pytest -s --durations=0 " +
						        "--junitxml=/nres-pipe/code/pytest-bias-ingestion.xml -m bias_ingestion /nres-pipe/code/")
					}
				}
			}
			post {
				always {
					script {
					    withKubeConfig([credentialsId: "dev-kube-config"]) {
						    sh("kubectl cp -c nres-pipeline " +
						            "${podName}:/nres-pipe/code/pytest-bias-ingestion.xml " +
						            "pytest-bias-ingestion.xml")
						    junit "pytest-bias-ingestion.xml"
						}
					}
				}
			}
		}
		stage("Test-Master-Bias-Creation") {
			when {
				anyOf {
					branch "PR-*"
					expression { return params.forceEndToEnd }
				}
			}
			steps {
				script {
			        withKubeConfig([credentialsId: "dev-kube-config"]) {
                        sh("kubectl exec -c nres-pipeline ${podName} -- " +
                                "/usr/bin/sudo -s -E -u archive /opt/conda/bin/pytest -s --durations=0 " +
                                "--junitxml=/nres-pipe/code/pytest-master-bias.xml -m master_bias /nres-pipe/code/")
			        }
			    }
			}
			post {
				always {
					script {
					    withKubeConfig([credentialsId: "dev-kube-config"]) {
						    sh("kubectl cp -c nres-pipeline " +
						            "${podName}:/nres-pipe/code/pytest-master-bias.xml pytest-master-bias.xml")
						    junit "pytest-master-bias.xml"
						}
					}
				}
			}
		}
		stage("Test-Dark-Ingestion") {
			when {
				anyOf {
					branch "PR-*"
					expression { return params.forceEndToEnd }
				}
			}
			steps {
				script {
				    withKubeConfig([credentialsId: "dev-kube-config"]) {
					    sh("kubectl exec -c nres-pipeline ${podName} -- " +
						        "/usr/bin/sudo -s -E -u archive /opt/conda/bin/pytest -s --durations=0 " +
						        "--junitxml=/nres-pipe/code/pytest-dark-ingestion.xml -m dark_ingestion /nres-pipe/code/")
					}
				}
			}
			post {
				always {
					script {
					    withKubeConfig([credentialsId: "dev-kube-config"]) {
						    sh("kubectl cp -c nres-pipeline " +
						            "${podName}:/nres-pipe/code/pytest-dark-ingestion.xml " +
						            "pytest-dark-ingestion.xml")
						    junit "pytest-dark-ingestion.xml"
						}
					}
				}
			}
		}
		stage("Test-Master-Dark-Creation") {
			when {
				anyOf {
					branch "PR-*"
					expression { return params.forceEndToEnd }
				}
			}
			steps {
				script {
			        withKubeConfig([credentialsId: "dev-kube-config"]) {
						sh("kubectl exec -c nres-pipeline ${podName} -- " +
						        "/usr/bin/sudo -s -E -u archive /opt/conda/bin/pytest -s --durations=0 " +
						        "--junitxml=/nres-pipe/code/pytest-master-dark.xml -m master_dark /nres-pipe/code/")
					}
				}
			}
			post {
				always {
					script {
					    withKubeConfig([credentialsId: "dev-kube-config"]) {
						    sh("kubectl cp -c nres-pipeline " +
						            "${podName}:/nres-pipe/code/pytest-master-dark.xml pytest-master-dark.xml")
						    junit "pytest-master-dark.xml"
						}
					}
				}
			}
		}
		stage("Test-Flat-Ingestion") {
			when {
				anyOf {
					branch "PR-*"
					expression { return params.forceEndToEnd }
				}
			}
			steps {
				script {
				    withKubeConfig([credentialsId: "dev-kube-config"]) {
				        sh("kubectl exec -c nres-pipeline ${podName} -- " +
						        "/usr/bin/sudo -s -E -u archive /opt/conda/bin/pytest -s --durations=0 " +
						        "--junitxml=/nres-pipe/code/pytest-flat-ingestion.xml -m flat_ingestion /nres-pipe/code/")
					}
				}
			}
			post {
				always {
					script {
					    withKubeConfig([credentialsId: "dev-kube-config"]) {
						    sh("kubectl cp -c nres-pipeline " +
						            "${podName}:/nres-pipe/code/pytest-flat-ingestion.xml pytest-flat-ingestion.xml")
						    junit "pytest-flat-ingestion.xml"
						}
					}
				}
			}
		}
		stage("Test-Master-Flat-Creation") {
			when {
				anyOf {
					branch "PR-*"
					expression { return params.forceEndToEnd }
				}
			}
			steps {
				script {
                    withKubeConfig([credentialsId: "dev-kube-config"]) {
                        sh("kubectl exec -c nres-pipeline ${podName} -- " +
                                "/usr/bin/sudo -s -E -u archive /opt/conda/bin/pytest -s --durations=0 " +
                                "--junitxml=/nres-pipe/code/pytest-master-flat.xml -m master_flat /nres-pipe/code/")
					}
				}
			}
			post {
				always {
					script {
					    withKubeConfig([credentialsId: "dev-kube-config"]) {
						    sh("kubectl cp -c nres-pipeline " +
						            "${podName}:/nres-pipe/code/pytest-master-flat.xml pytest-master-flat.xml")
						    junit "pytest-master-flat.xml"
						}
					}
				}
			}
		}
		stage("Test-Arc-Ingestion") {
			when {
				anyOf {
					branch "PR-*"
					expression { return params.forceEndToEnd }
				}
			}
			steps {
				script {
                    withKubeConfig([credentialsId: "dev-kube-config"]) {
                        sh("kubectl exec -c nres-pipeline ${podName} -- " +
                                "/usr/bin/sudo -s -E -u archive /opt/conda/bin/pytest -s --durations=0 " +
                                "--junitxml=/nres-pipe/code/pytest-arc-ingestion.xml -m arc_ingestion /nres-pipe/code/")
					}
				}
			}
			post {
				always {
					script {
					    withKubeConfig([credentialsId: "dev-kube-config"]) {
						    sh("kubectl cp -c nres-pipeline " +
						            "${podName}:/nres-pipe/code/pytest-arc-ingestion.xml pytest-arc-ingestion.xml")
						    junit "pytest-arc-ingestion.xml"
						}
					}
				}
			}
		}
		stage("Test-Master-Arc-Creation") {
			when {
				anyOf {
					branch "PR-*"
					expression { return params.forceEndToEnd }
				}
			}
			steps {
				script {
                    withKubeConfig([credentialsId: "dev-kube-config"]) {
                        sh("kubectl exec -c nres-pipeline ${podName} -- " +
                            "/usr/bin/sudo -s -E -u archive /opt/conda/bin/pytest -s --durations=0 " +
                            "--junitxml=/nres-pipe/code/pytest-master-arc.xml -m master_arc /nres-pipe/code/")
					}
				}
			}
			post {
				always {
					script {
					    withKubeConfig([credentialsId: "dev-kube-config"]) {
						    sh("kubectl cp -c nres-pipeline " +
						            "${podName}:/nres-pipe/code/pytest-master-arc.xml pytest-master-arc.xml")
						    junit "pytest-master-arc.xml"
						}
					}
				}
			}
		}
		stage("Test-Zero-File-Creation") {
			when {
				anyOf {
					branch "PR-*"
					expression { return params.forceEndToEnd }
				}
			}
			steps {
				script {
                    withKubeConfig([credentialsId: "dev-kube-config"]) {
                        sh("kubectl exec -c nres-pipeline ${podName} -- " +
                            "/usr/bin/sudo -s -E -u archive /opt/conda/bin/pytest -s --durations=0 " +
                            "--junitxml=/nres-pipe/code/pytest-zero-file.xml -m zero_file /nres-pipe/code/")
					}
				}
			}
			post {
				always {
					script {
					    withKubeConfig([credentialsId: "dev-kube-config"]) {
						    sh("kubectl cp -c nres-pipeline " +
						            "${podName}:/nres-pipe/code/pytest-zero-file.xml pytest-zero-file.xml")
						    junit "pytest-zero-file.xml"
						}
					}
				}
			}
		}
		stage("Test-Science-File-Creation") {
			when {
				anyOf {
					branch "PR-*"
					expression { return params.forceEndToEnd }
				}
			}
			steps {
				script {
			        withKubeConfig([credentialsId: "dev-kube-config"]) {
						sh("kubectl exec -c nres-pipeline ${podName} -- " +
                            "/usr/bin/sudo -s -E -u archive /opt/conda/bin/pytest -s --durations=0 " +
                            "--junitxml=/nres-pipe/code/pytest-science-files.xml -m science_files /nres-pipe/code/")
					}
				}
			}
			post {
				always {
					script {
					    withKubeConfig([credentialsId: "dev-kube-config"]) {
						    sh("kubectl cp -c nres-pipeline " +
						            "${podName}:/nres-pipe/code/pytest-science-files.xml pytest-science-files.xml")
						    junit "pytest-science-files.xml"
						}
					}
				}
				success {
					script {
					    withKubeConfig([credentialsId: "dev-kube-config"]) {
                            sh("helm delete nres-pipe || true")
					    }
					}
				}
			}
		}
	}
}
