def BRANCH="$branch"
def MVN_SKIPTESTS=new Boolean("$skip_tests_flag")
def ARTIFACTORY_URL="$artifactory_url"
def ARTIFACTORY_DEV_REPO="$artifactory_dev_repo"
def ARTIFACTORY_EXT_REPO="$artifactory_ext_repo"
def VERSION_BRANCHNAME=new Boolean("$version_branchname")
def VERSION_IN="${version_in}"
def GIT_TAGS = "${git_tags}"
def TOOLS_BUILD=new Boolean("$tools_build_only")

def VERSION

def dependenciesJson='integration/dependencies.json'

def artifactory_loc="infoworks-dev-mvn"
if ("${pom}" == "pom.xml") {
    artifactory_loc="infoworks-dev-mvn"
} else {
    artifactory_loc="infoworks-dev-mvn-hdp3"
}

node {
    //Pre-build
    deleteDir()
    stage "pre"
    echo "executing pre script."
    def mvnHome=tool 'mvn3'

    //git lfs
    sh "git lfs install --skip-smudge"

    git branch: BRANCH, changelog: false, credentialsId: 'krishna-git', poll: false, url: 'git@github.com:Infoworks/dblore.git'
    def COMMIT = sh returnStdout: true, script: 'git rev-parse HEAD 2> /dev/null'
    COMMIT = COMMIT.trim()
    echo "Commit Hash: " + COMMIT

    //git lfs
    //sh "git lfs pull"
    //sh "git lfs install --force"

    if (VERSION_BRANCHNAME) {
        VERSION = BRANCH + "-STAGING"
        sh mvnHome + "/bin/mvn -f ${pom} versions:set -DnewVersion=" + VERSION
    } else {
        if (VERSION_IN) {
            VERSION = VERSION_IN
            sh mvnHome + "/bin/mvn -f ${pom} versions:set -DnewVersion=" + VERSION
        } else {
            sh mvnHome + '/bin/mvn -f ${pom} org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.version | grep -v "\\[" > versionInfo'
            VERSION = readFile 'versionInfo'
            VERSION = VERSION.trim()
        }

    }
    echo 'got project version: ' + VERSION

    echo "resource-allocate: nothing to do"
    sleep 1

    stage "build"
    if (TOOLS_BUILD) {
        dir('metadata') {
            sh "${mvnHome}/bin/mvn -f ${pom} -DaltDeploymentRepository=releaseRepository::default::http://172.30.0.211:8081/artifactory/${artifactory_loc}/ clean test-compile install deploy -Dmaven.test.skip=${MVN_SKIPTESTS}"
        }
        dir('tools') {
            sh "${mvnHome}/bin/mvn -f ${pom} -Dmaven.repo.remote=http://172.30.0.211:8081/artifactory/${artifactory_loc}/,http://repository.mapr.com/maven/ -DaltDeploymentRepository=releaseRepository::default::http://172.30.0.211:8081/artifactory/${artifactory_loc}/ clean test-compile install deploy -Dmaven.test.skip=${MVN_SKIPTESTS}"
            currentBuild.result = 'SUCCESS'
            return
        }
    } else {
        sh "${mvnHome}/bin/mvn -f ${pom} -DaltDeploymentRepository=releaseRepository::default::http://172.30.0.211:8081/artifactory/${artifactory_loc}/ clean test-compile install deploy -Dmaven.test.skip=${MVN_SKIPTESTS}"
    }

    stage "test"
    echo "test: nothing to do"

    stage "package"
    //Make libs jar
    if ("${pom}" == "pom.xml") {
        echo "package: copying default conf to conf_2.3"

        sh "rm -rf /opt/bDr/conf_2.3/metadata/ || true ; "
        sh "if [ -d artifacts/build/metadata ]; then cp -af artifacts/build/metadata /opt/bDr/conf_2.3/; fi "
        sh "if [ -f artifacts/OracleUDA.txt ]; then cp -af artifacts/OracleUDA.txt /opt/bDr/conf_2.3/; fi "
        echo "package: copying mappings"
        sh "cp -af artifacts/mappings/* /opt/bDr/conf_2.3/mappings/; "

        echo "package: consolidate dependencies"
        sh "mkdir -p target/lib; " +
        "cp discovery/target/lib/* target/lib/;" +
        "cp datacube/target/lib/* target/lib/;" +
        "cp tools/target/lib/* target/lib/;" +
        //"cp QueryService/target/lib/* target/lib/;" +
        "if [ -d 'SparkStream/target' ]; then cp SparkStream/target/lib/* target/lib/; fi;" +
        "pushd target; " +
        "tar czf dblore-libs-"+ VERSION + ".tar.gz lib/;" +
        "curl -H 'X-JFrog-Art-Api: AKCp2V6dFLFfExVFqZL4QCGR95A2W14HW5zCQsr7y3BquKqyjtYNprspjEgrVHkqjFEjUR6vP' " +
        "-T dblore-libs-"+ VERSION + ".tar.gz " +
        "\"http://172.30.0.211:8081/artifactory/infoworks-dev-generic/io/infoworks/lib/" + VERSION + "/dblore-libs-"+ VERSION + ".tar.gz\";" +
        "popd"

        //3rd party dependencies
        echo "package: 3rd party dependencies"
        def depsFile = readFile dependenciesJson
        def deps = depsFile.split('\n')
        for ( def i=0; i<deps.size(); i++ ) {
            def tokens = deps[i].split( '=' )
            print tokens[0]
            def k = tokens[0]
            def v = tokens[1]
            echo "got dependency " + k + " version " + v
            echo "checking artifactory for " + k + ":" + v
            request_url = ARTIFACTORY_URL + ARTIFACTORY_EXT_REPO + "/" + k + "/" + v + "/" + k + "-" + v + ".tar.gz"
            echo "Request type: HEAD "
            echo "Request URL: " + request_url

        }

        echo 'Generating manifest for dblore'
        echo 'Generating manifest entry for dependencies'
        def depsJSON = "{"

        for ( def i=0; i<deps.size(); i++ ) {
            def tokens = deps[i].split( '=' )
            print tokens[0]
            def k = tokens[0]
            def v = tokens[1]
            depsJSON += "$k : \"$v\""
            if ( i < deps.size()-1 ) {
                depsJSON += ","
            }
        }
        depsJSON += "}"
        def manifest = """{
        "dblore":
            {
              "branch": "$BRANCH",
              "commit": "$COMMIT",
              "version": "$VERSION",
              "dependencies": $depsJSON
            }
    }"""
        echo "Manifest: " + manifest
        echo "Saving manifest file"
        writeFile file: 'manifest', text: manifest

        sh "curl -H 'X-JFrog-Art-Api: AKCp2V6dFLFfExVFqZL4QCGR95A2W14HW5zCQsr7y3BquKqyjtYNprspjEgrVHkqjFEjUR6vP' " +
        "-T manifest " +
        "\"http://172.30.0.211:8081/artifactory/infoworks-dev-generic/io/infoworks/manifest/" + VERSION + "/dblore-manifest-"+ VERSION + ".json\";"
    }
    stage "post"
    if ("${pom}" == "pom.xml") {
        echo "apply git tags(if any): ${GIT_TAGS}"
        if ( GIT_TAGS?.trim() ) {
            def tags = GIT_TAGS.split(",")
            for(int i=0; i<tags.size(); i++ ) {
                tag = tags[i].trim()
                sh "git tag ${tag}"
            }
            sh "git push --tags"
        }
    }
    echo "Executing mvn clean"
    sh "${mvnHome}/bin/mvn -f ${pom} clean"
}
