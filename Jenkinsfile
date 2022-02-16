def artserver = Artifactory.server('repository.terradue.com')
def buildInfo = Artifactory.newBuildInfo()
buildInfo.env.capture = true
def dockerNewVersion = 0.12

node('ci-community-docker') {

    def mType=getTypeOfVersion(env.BRANCH_NAME)
      
    stage('Clone') {
    
        checkout scm
    }

    stage('Build') {
    
        sh "docker build --no-cache --rm -t docker.terradue.com/calrissian-session:${mType}${dockerNewVersion} -f container/Dockerfile container" 
    }

    stage('Push'){

      sh "docker tag -f  docker.terradue.com/calrissian-session:${mType}${dockerNewVersion} docker.terradue.com/calrissian-session:${mType}latest"
      sh "docker push docker.terradue.com/calrissian-session:${mType}${dockerNewVersion}"
      sh "docker push docker.terradue.com/calrissian-session:${mType}latest"
    }
    
    stage('Clean'){

      sh "docker rmi docker.terradue.com/calrissian-session:${mType}${dockerNewVersion}"
      sh "docker rmi docker.terradue.com/calrissian-session:${mType}latest"
    }


}

def disableRepository(branchName) {

    def matcher = (env.BRANCH_NAME =~ /master/)
    if (matcher.matches())
        return "terradue-testing-el7"

    return "terradue-stable-el7"
}

def getTypeOfVersion(branchName){
        
    def matcher = (env.BRANCH_NAME =~ /master/)
    if (matcher.matches())
      return ""

    return "d"
}