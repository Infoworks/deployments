def BRANCH="$branch"
def MVN_SKIPTESTS=new Boolean("$skip_tests_flag")
def ARTIFACTORY_URL="$artifactory_url"
def ARTIFACTORY_DEV_REPO="$artifactory_dev_repo"
def ARTIFACTORY_EXT_REPO="$artifactory_ext_repo"
def VERSION_BRANCHNAME=new Boolean("$version_branchname")
def VERSION_IN="${version_in}"
def GIT_TAGS = "${git_tags}"
def BUILD_NIMBUS_ONLY=new Boolean("$build_nimbus_only")

def VERSION
def MVN_PL=''

def GIT_REPO_URL='git@github.com:Infoworks/infoworks-cloud.git'
def GIT_CREDS_ID='krishna-git'

def PACKAGE_HOME='/tmp/infoworks/infoworks-cloud'
def TARGET_IW_HOME='/opt/infoworks'

def ARTIFACTORY_HOST='172.30.0.211:8081'
def ARTIFACTORY_REPO='infoworks-dev-mvn'
node {
    //Pre-build
    deleteDir()
    stage "pre"
    echo "executing pre script."
    def mvnHome=tool 'mvn3'

    //stage "checkout"
    git branch: BRANCH, changelog: false, credentialsId: GIT_CREDS_ID, poll: false, url: GIT_REPO_URL
    def COMMIT = sh returnStdout: true, script: 'git rev-parse HEAD 2> /dev/null'
    COMMIT = COMMIT.trim()
    echo "Commit Hash: " + COMMIT

    //stage "extract-version"
    if (VERSION_BRANCHNAME) {
        VERSION = BRANCH + "-STAGING"
        sh mvnHome + "/bin/mvn versions:set -DnewVersion=" + VERSION
    } else {
        if (VERSION_IN) {
            VERSION = VERSION_IN
            sh mvnHome + "/bin/mvn versions:set -DnewVersion=" + VERSION
        } else {
            sh mvnHome + '/bin/mvn org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.version | grep -v "\\[" > versionInfo'
            VERSION = readFile 'versionInfo'
            VERSION = VERSION.trim()
        }

    }
    echo 'got project version: ' + VERSION

    //stage "resource-allocate"
    echo "resource-allocate: nothing to do"
    sleep 1

    stage "build"
    withEnv(["TARGET_VERSION=$VERSION",
    "SKIP_UNITTESTS=$MVN_SKIPTESTS",
    "PACKAGE_HOME=$PACKAGE_HOME",
    "TARGET_HOSTNAME=localhost",
    "IW_HOME=$TARGET_IW_HOME",
    "USE_ARTIFACTORY=true",
    "ARTIFACTORY_HOST=$ARTIFACTORY_HOST",
    "ARTIFACTORY_REPO=$ARTIFACTORY_REPO",
    "BUILD_NIMBUS_ONLY=$BUILD_NIMBUS_ONLY",]) {
        //For backwards compatibility
        //Pre-2.5.0 versions will not have build/ecb dir
        sh  '''
#if available, use new build files
if [ -d build/infoworks-cloud ]; then
    if [ -d build/infoworks-cloud/steps ]; then
        #This is the current main dir, rest are for back-compat
        cd build/infoworks-cloud/steps/build
    else
        cd build/infoworks-cloud/scripts/build
    fi
else
    cd build/scripts/build
fi
echo "got env: "; env;
./build.sh
        '''
    }

    stage "test"
    echo "test: nothing to do"

    stage "package"
    echo "component packaging already completed in build step"

    stage "post"
    echo 'Generating manifest for infoworks-cloud'
    def manifest = """{
    "infoworks-cloud":
        {
          "branch": "$BRANCH",
          "commit": "$COMMIT",
          "version": "$VERSION"
        }
}"""
    echo "Manifest: " + manifest
    echo "Saving manifest file"
    writeFile file: 'manifest', text: manifest

    sh "curl -H 'X-JFrog-Art-Api: AKCp2V6dFLFfExVFqZL4QCGR95A2W14HW5zCQsr7y3BquKqyjtYNprspjEgrVHkqjFEjUR6vP' " +
    "-T manifest " +
    "\"http://172.30.0.211:8081/artifactory/infoworks-dev-generic/io/infoworks/manifest/" + VERSION + "/infoworks-cloud-manifest-"+ VERSION + ".json\";"

    echo "apply git tags(if any): ${GIT_TAGS}"
    if ( GIT_TAGS?.trim() ) {
        def tags = GIT_TAGS.split(",")
        for(int i=0; i<tags.size(); i++ ) {
            tag = tags[i].trim()
            sh "git tag ${tag}"
        }
        sh "git push --tags"
    }
    echo "Executing mvn clean"
    sh "${mvnHome}/bin/mvn clean"
}
