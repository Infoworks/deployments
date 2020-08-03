//pipeline for 3.2.1
def saas_commit, dblore_commit, platform_commit, ingestion_commit, awb_commit, cloud_commit, saas_scala_commit, apricot_commit

pipeline {
  agent any
  parameters {
    string(defaultValue: "prod-4.0", description: 'Branch name(common to all repos)', name: 'BRANCH')
    string(defaultValue: "4.0", description: 'Package version', name: 'VERSION')
  }

  environment {
    BUILD_HOME = pwd()
    PACKAGE_HOME = "$BUILD_HOME/infoworks"
    INSTALLER_PACKAGE_HOME = "$BUILD_HOME/installer"
    REPO_HOME = "$BUILD_HOME/repos"
    EXTRAS_HOME = "$BUILD_HOME/extras"

    // BRANCH = "features/saas-build"
    DBLORE_BRANCH = "bugfix/4.0"
    PLATFORM_BRANCH = "bugfix/4.0"
    APRICOT_BRANCH = "bugfix/4.0"
    INGESTION_BRANCH = "bugfix/4.0"
    AWB_BRANCH = "bugfix/4.0"
    INFOWORKS_CLOUD_BRANCH = "bugfix/4.0"
    SAAS_SCALA_UTILS_BRANCH = "bugfix/4.0"
    INTERACTIVE_GUIDE_BRANCH = "release/4.0"
    NOTEBOOK_BRANCH = "bugfix/4.0"
    SAMPLE_DATASETS_BRANCH = "release/4.0"

    // VERSION = "${params.VERSION}"
    //PARTS = extractVersionParts VERSION
    //MAJOR_VERSION = "${PARTS[1]}"
    MAJOR_VERSION = "4.0"
    //MINOR_VERSION = PARTS[2]

    // S3_BUCKET = "infoworks-setup"
    // Saas packages will be stored in s3 accelerated bucket
    S3_BUCKET = "iw-saas-setup"
    PACKAGE_NAME = "infoworks-$VERSION-adb-ubuntu.tar.gz"
    INSTALLER_PACKAGE_NAME = "deploy_$VERSION-adb-ubuntu.tar.gz"
    S3_PACKAGE_URL = "s3://$S3_BUCKET/$MAJOR_VERSION/"

    // RESOURCES_TARBALL_URL = "http://54.221.70.148:8081/artifactory/resources/centos6/resources-orchestrator-2.8.0.tar.gz"
    // RESOURCES_TARBALL_URL = "http://54.221.70.148:8081/artifactory/resources/azure/resources-2.8.x.tar.gz"
    //RESOURCES_TARBALL_URL = "http://54.221.70.148:8081/artifactory/resources/ubuntu1604/resources-orchestrator-4.0.tar.gz"
    //RESOURCES_TARBALL_URL = "http://54.221.70.148:8081/artifactory/resources/ubuntu1604/resources-orchestrator-saas-4.0.tar.gz"
    RESOURCES_TARBALL_URL = "http://54.221.70.148:8081/artifactory/resources/ubuntu1604/resources-orchestrator.tar.gz"

    LICENSE_TARBALL_URL = "https://infoworks-setup.s3.amazonaws.com/licences_3.0.0_cloud.tar.gz"

    GH_CREDENTIAL_ID = "jenkins-b3"

    MVN_HOME = tool 'mvn3'
    NODE_HOME = tool 'nodejs'
    }

  stages {

    stage('init') {
      steps {
        script{
          saas_commit = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
        }
        //create package directory
        sh 'mkdir -p $REPO_HOME $REPO_HOME/dblore $REPO_HOME/platform $REPO_HOME/apricot-meteor $REPO_HOME/ingestion-saas $REPO_HOME/awb $REPO_HOME/notebook $BUILD_HOME/extras/interactive-guide $BUILD_HOME/extras/interactive-guide/images $PACKAGE_HOME/notebook $PACKAGE_HOME/sample-datasets $BUILD_HOME/extra/notebook'
        sh 'rm -rf $PACKAGE_HOME $INSTALLER_PACKAGE_HOME && mkdir -p $PACKAGE_HOME $PACKAGE_HOME/bin $PACKAGE_HOME/conf $PACKAGE_HOME/lib $PACKAGE_HOME/logs $PACKAGE_HOME/temp $PACKAGE_HOME/interactive-guides $PACKAGE_HOME/interactive-guides/images $INSTALLER_PACKAGE_HOME'
        //sh 'rm -rf $BUILD_HOME/extras/interactive-guide/*"
      }
    }

    stage('resources') {
      steps {
        dir("$PACKAGE_HOME") {
          //Add resources from tarball
          sh "wget -qO resources.tar.gz $RESOURCES_TARBALL_URL \
              && tar xf resources.tar.gz \
              && rm resources.tar.gz \
              && rm resources/mongodb/data/mongod.lock;"
        }
      }
    }

    stage('metadb') {
      steps {
        echo 'Building..'
        dir("$REPO_HOME/platform/metadb-service") {
          withEnv(["SKIP_UNITTESTS=${env.SKIP_UNITTESTS?:false}",
            "PATH+WHATEVER=$MVN_HOME/bin"]) {
            script {
                checkout scm: [$class: 'GitSCM', userRemoteConfigs: [[url: 'git@github.com:Infoworks/platform.git', credentialsId: GH_CREDENTIAL_ID]], branches: [[name: PLATFORM_BRANCH]], extensions: [[$class: 'WipeWorkspace']]]
                platform_commit = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
              }
            sh 'pwd; ls -lart'
            sh "mvn -pl metadb-service clean install -DskipTests"
          }
        }
      }
    }

    stage('infoworks-cloud') {
      steps {
        echo 'Building..'
        dir("$REPO_HOME/infoworks-cloud") {
          withEnv(["SKIP_UNITTESTS=${env.SKIP_UNITTESTS?:false}",
            "PATH+WHATEVER=$MVN_HOME/bin"]) {
            // git branch: INFOWORKS_CLOUD_BRANCH, changelog: false, credentialsId: GH_CREDENTIAL_ID, poll: false, url: 'git@github.com:Infoworks/infoworks-cloud.git'
            script {
                // Checkout the repository and save the resulting metadata
                checkout scm: [$class: 'GitSCM', userRemoteConfigs: [[url: 'git@github.com:Infoworks/infoworks-cloud.git', credentialsId: GH_CREDENTIAL_ID]], branches: [[name: INFOWORKS_CLOUD_BRANCH]]]
                cloud_commit = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
            }
            sh 'pwd; ls -lart'
            sh script: './build/saas/build.sh'
          }
        }
      }
    }

    stage('ingestion') {
      steps {
        echo 'Building..'
        dir("$REPO_HOME/ingestion-saas") {
          withEnv(["SKIP_UNITTESTS=${env.SKIP_UNITTESTS?:false}",
            "PATH+WHATEVER=$MVN_HOME/bin"]) {
            // git branch: INGESTION_BRANCH, changelog: false, credentialsId: GH_CREDENTIAL_ID, poll: false, url: 'git@github.com:Infoworks/ingestion-saas.git'
            script {
                // Checkout the repository and save the resulting metadata
                checkout scm: [$class: 'GitSCM', userRemoteConfigs: [[url: 'git@github.com:Infoworks/ingestion-saas.git', credentialsId: GH_CREDENTIAL_ID]], branches: [[name: INGESTION_BRANCH]]]
                ingestion_commit = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
            }
            sh 'pwd; ls -lart'
            sh script: './build/saas/build.sh'
          }
        }
      }
    }

    stage('dblore') {
      steps {
        echo 'Building..'
        dir("$REPO_HOME/dblore") {
          withEnv(["SKIP_UNITTESTS=${env.SKIP_UNITTESTS?:false}",
            "PATH+WHATEVER=$MVN_HOME/bin"]) {
            //TODO move into dblore repo
            // git branch: DBLORE_BRANCH, changelog: false, credentialsId: GH_CREDENTIAL_ID, poll: false, url: 'git@github.com:Infoworks/dblore.git'
            script {
              checkout scm: [$class: 'GitSCM', userRemoteConfigs: [[url: 'git@github.com:Infoworks/dblore.git', credentialsId: GH_CREDENTIAL_ID]], branches: [[name: DBLORE_BRANCH]]]
              dblore_commit = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
            }
            sh 'pwd; ls -lart'
            sh 'mvn clean install -DskipTests -pl :tools,:QueryDriver -am'
            sh 'mkdir -p $PACKAGE_HOME/bin/ $PACKAGE_HOME/conf/; '
            sh 'cp tools/target/tools*jar QueryDriver/target/QueryDriver*jar $PACKAGE_HOME/bin/'
          }
        }
      }
    }

    stage('platform') {
      steps {
        echo 'Building..'
        dir("$REPO_HOME/platform") {
          withEnv(["SKIP_UNITTESTS=${env.SKIP_UNITTESTS?:false}",
            "PATH+WHATEVER=$MVN_HOME/bin"]) {
            script {
                checkout scm: [$class: 'GitSCM', userRemoteConfigs: [[url: 'git@github.com:Infoworks/platform.git', credentialsId: GH_CREDENTIAL_ID]], branches: [[name: PLATFORM_BRANCH]], extensions: [[$class: 'WipeWorkspace']]]
                platform_commit = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
              }
            sh 'pwd; ls -lart'
            sh script: './build/saas/build.sh'
          }
        }
      }
    }

    stage('sample data-sets') {
      steps {
        echo 'Building..'
        dir("$PACKAGE_HOME/sample-datasets") {
          withEnv(["SKIP_UNITTESTS=${env.SKIP_UNITTESTS?:false}",
            "PATH+WHATEVER=$MVN_HOME/bin"]) {
            script {
                checkout scm: [$class: 'GitSCM', userRemoteConfigs: [[url: 'git@github.com:Infoworks/sample-datasets.git', credentialsId: GH_CREDENTIAL_ID]], branches: [[name: SAMPLE_DATASETS_BRANCH]], extensions: [[$class: 'WipeWorkspace']]]
              //platform_commit = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
              }
            //sh 'pwd; ls -lart'
            //sh script: './build/saas/build.sh'
          }
        }
      }
    }

    stage('notebook') {
      steps {
        echo 'Building..'
        dir("$PACKAGE_HOME/notebook") {
          withEnv(["SKIP_UNITTESTS=${env.SKIP_UNITTESTS?:false}",
            "PATH+WHATEVER=$MVN_HOME/bin"]) {
            script {
                checkout scm: [$class: 'GitSCM', userRemoteConfigs: [[url: 'git@github.com:Infoworks/notebook.git', credentialsId: GH_CREDENTIAL_ID]], branches: [[name: NOTEBOOK_BRANCH]], extensions: [[$class: 'WipeWorkspace']]]
                //platform_commit = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
              }
             //sh "cp -ar * $PACKAGE_HOME/notebook/"
          }
        }
      }
    }

    stage('dt') {
      steps {
        echo 'Building..'
        dir("$REPO_HOME/awb") {
          withEnv(["SKIP_UNITTESTS=${env.SKIP_UNITTESTS?:false}",
            "PATH+WHATEVER=$MVN_HOME/bin"]) {
            // git branch: AWB_BRANCH, changelog: false, credentialsId: GH_CREDENTIAL_ID, poll: false, url: 'git@github.com:Infoworks/awb.git'
            script {
                // Checkout the repository and save the resulting metadata
                checkout scm: [$class: 'GitSCM', userRemoteConfigs: [[url: 'git@github.com:Infoworks/dt.git', credentialsId: GH_CREDENTIAL_ID]], branches: [[name: AWB_BRANCH]]]
                awb_commit = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
            }
            sh 'pwd; ls -lart'
            sh script: './build/saas/build.sh'
          }
        }
      }
    }

    stage('saas-scala-utils') {
      steps {
        echo 'Building..'
        dir("$REPO_HOME/saas-scala-utils") {
          withEnv(["SKIP_UNITTESTS=${env.SKIP_UNITTESTS?:false}",
            "PATH+WHATEVER=$MVN_HOME/bin"]) {
            // git branch: SAAS_SCALA_UTILS_BRANCH, changelog: false, credentialsId: GH_CREDENTIAL_ID, poll: false, url: 'git@github.com:Infoworks/saas-scala-utils.git'
            script {
                // Checkout the repository and save the resulting metadata
                checkout scm: [$class: 'GitSCM', userRemoteConfigs: [[url: 'git@github.com:Infoworks/saas-scala-utils.git', credentialsId: GH_CREDENTIAL_ID]], branches: [[name: SAAS_SCALA_UTILS_BRANCH]]]
                saas_scala_commit = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
            }
            sh 'pwd; ls -lart'
            sh script: './build/saas/build.sh'
          }
        }
      }
    }

    stage('apricot-meteor') {
      steps {
        echo 'Building..'
        dir("$REPO_HOME/apricot-meteor") {
          withEnv(["SKIP_UNITTESTS=${env.SKIP_UNITTESTS?:false}",
            "PATH+WHATEVER=$MVN_HOME/bin:$NODE_HOME/bin"]) {
            // git branch: APRICOT_BRANCH, changelog: false, credentialsId: GH_CREDENTIAL_ID, poll: false, url: 'git@github.com:Infoworks/apricot-meteor.git'
            script {
                // Checkout the repository and save the resulting metadata
                checkout scm: [$class: 'GitSCM', userRemoteConfigs: [[url: 'git@github.com:Infoworks/apricot-meteor.git', credentialsId: GH_CREDENTIAL_ID]], branches: [[name: APRICOT_BRANCH]]]
                apricot_commit = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
            }

            sh 'pwd; ls -lart'
            sh script: './build/saas/build.sh'
          }
        }
      }
    }

    stage('interactive-guides') {
      steps {
        echo 'Building..'
        dir("$BUILD_HOME/extras/interactive-guide") {
          withEnv(["SKIP_UNITTESTS=${env.SKIP_UNITTESTS?:false}",
            "PATH+WHATEVER=$MVN_HOME/bin:$NODE_HOME/bin"]) {
            // git branch: APRICOT_BRANCH, changelog: false, credentialsId: GH_CREDENTIAL_ID, poll: false, url: 'git@github.com:Infoworks/apricot-meteor.git'
            script {
                // Checkout the repository and save the resulting metadata
                checkout scm: [$class: 'GitSCM', userRemoteConfigs: [[url: 'git@github.com:Infoworks/interactive-guides.git', credentialsId: GH_CREDENTIAL_ID]], branches: [[name: INTERACTIVE_GUIDE_BRANCH]]]
                //apricot_commit = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
            }
            //sh "cp $BUILD_HOME/extras/interactive-guide/interactive_guides.json $PACKAGE_HOME/apricot-meteor/apricot/"
            sh "cp $BUILD_HOME/extras/interactive-guide/interactive_guides.json $PACKAGE_HOME/interactive-guides/"
            sh "cp -ar $BUILD_HOME/extras/interactive-guide/images/* $PACKAGE_HOME/interactive-guides/images"
            sh "cp -ar $BUILD_HOME/extras/interactive-guide/style.css $PACKAGE_HOME/interactive-guides/"
          }
        }
      }
    }


    stage('package') {
      steps {
        dir("$BUILD_HOME") {
          //set permissions for all files
          dir("$PACKAGE_HOME") {
            sh "chmod -R 740 ."
          }
          //add version and manifest
          dir("$PACKAGE_HOME") {
            sh "echo \"\$VERSION\" > version"
            script{
              sh 'echo "manifest making in progress"'

              env.SAAS_JSON = makeManifest("infoworks-saas", "$BUILD_NUMBER", "$VERSION", "$BRANCH", "$saas_commit")
              sh "echo \"\$SAAS_JSON\" >> manifest.json"

              env.DBLORE_JSON = makeManifest("dblore", "$BUILD_NUMBER", "$VERSION", "$DBLORE_BRANCH", "$dblore_commit")
              sh "echo \"\$DBLORE_JSON\" >> manifest.json"

              env.PLATFORM_JSON = makeManifest("platform", "$BUILD_NUMBER", "$VERSION", "$PLATFORM_BRANCH", "$platform_commit")
              sh "echo \"\$PLATFORM_JSON\" >> manifest.json"

              env.INGESTION_JSON = makeManifest("ingestion", "$BUILD_NUMBER", "$VERSION", "$INGESTION_BRANCH", "$ingestion_commit")
              sh "echo \"\$INGESTION_JSON\" >> manifest.json"

              env.AWB_JSON = makeManifest("dt", "$BUILD_NUMBER", "$VERSION", "$AWB_BRANCH", "$awb_commit")
              sh "echo \"\$AWB_JSON\" >> manifest.json"

              env.CLOUD_JSON = makeManifest("infoworks-cloud", "$BUILD_NUMBER", "$VERSION", "$INFOWORKS_CLOUD_BRANCH", "$cloud_commit")
              sh "echo \"\$CLOUD_JSON\" >> manifest.json"

              env.SAAS_SCALA_JSON = makeManifest("saas-scala-utils", "$BUILD_NUMBER", "$VERSION", "$SAAS_SCALA_UTILS_BRANCH", "$saas_scala_commit")
              sh "echo \"\$SAAS_SCALA_JSON\" >> manifest.json"

              env.APRICOT_JSON = makeManifest("apricot-meteor", "$BUILD_NUMBER", "$VERSION", "$APRICOT_BRANCH", "$apricot_commit")
              sh "echo \"\$APRICOT_JSON\" >> manifest.json"
            }

          }
          //add license files
          dir("$PACKAGE_HOME") {
            sh "wget -qO license.tar.gz $LICENSE_TARBALL_URL \
            && tar xzf license.tar.gz \
            && rm license.tar.gz"
          }
          //Packaging stuff here
          //PATH is for aws command
          withEnv(["PATH+WHATEVER=~/.local/bin"]) {
            sh "rm -f $PACKAGE_NAME"
            sh "rm -f $PACKAGE_NAME/resources/mongodb/data/mongod.lock"
            sh "tar -czf $PACKAGE_NAME -C \$(dirname $PACKAGE_HOME) \$(basename $PACKAGE_HOME)"
            sh "aws s3 cp $PACKAGE_NAME $S3_PACKAGE_URL --acl public-read"
            sh "rm $PACKAGE_NAME"
          }
        }
      }
    }

      stage('package-installer') {
      steps {
        dir("$BUILD_HOME") {
          //set permissions for all files
          dir("$INSTALLER_PACKAGE_HOME") {
            sh "chmod -R 740 ."
          }
          //Packaging stuff here
          //PATH is for aws command
          withEnv(["PATH+WHATEVER=~/.local/bin"]) {
            sh "rm -f $INSTALLER_PACKAGE_NAME"
            sh "tar -czf $INSTALLER_PACKAGE_NAME -C$INSTALLER_PACKAGE_HOME ."
            sh "aws s3 cp $INSTALLER_PACKAGE_NAME $S3_PACKAGE_URL --acl public-read"
            sh "rm $INSTALLER_PACKAGE_NAME"
            mail bcc: '', body: "Build is successfull", cc: '', from: '', replyTo: '', subject: "Jenkins Job: Databricks-release-pipeline-4.0.x | Package:infoworks-4.0_beta1.tar.gz | SUCCESSFUL", to: 'roopa.k@infoworks.io,sumanth.vasu@infoworks.io'
            //build job: 'packer_azure_image_creation', parameters: [string(name: 'VERSION', value: "${VERSION}")]
          }
        }
      }
    }

    stage('cleanup') {
      steps {
        dir("$BUILD_HOME") {
          //delete package
          sh "rm -rf $PACKAGE_HOME"
          sh "rm -rf $BUILD_HOME/extras"
          //Test, delete
          println env
        }
      }
    }
    stage('Packer_Azure') {
      steps {
        dir("$BUILD_HOME") {
            mail bcc: '', body: "Starting Azure packer build", cc: '', from: '', replyTo: '', subject: "Started packer build", to: 'roopa.k@infoworks.io,sumanth.vasu@infoworks.io'
            build job: 'packer_azure_image_creation', parameters: [string(name: 'VERSION', value: "${VERSION}")]
            //build job: 'parallel_packer_image_creation', parameters: [string(name: 'VERSION', value: "${VERSION}")]
            mail bcc: '', body: "Completed Azure packer build", cc: '', from: '', replyTo: '', subject: "Completed packer build", to: 'roopa.k@infoworks.io,sumanth.vasu@infoworks.io'
        }
      }
    }
  }
}

def extractVersionParts(String version) {
  //def version = "3.0.0-beta"
  //def pattern = ~/^(\d{1,3}\.\d{1,3})\.(.*)$/
  //def pattern = ~/^(\d{1,2}\.\d{1,2})\.(.*)$/
  //def (parts) = version =~ pattern
  //return parts
}


def makeManifest(String repo_name, String buildNumber,String version, String branch, String commit) {
  return """{
  "$repo_name":
      {
        "buidId": "$buildNumber",
        "version": "$version"
        "branch": "$branch",
        "commit": "$commit"
      }
}"""
}
