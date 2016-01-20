node 'default' {
  class { 'docker_jenkins':
    # put all jenkins "secrets" here, especially a 
    # .ssh directory with an id_rsa key that can 
    # clone the config repo
    jenkins_id_dir            => 'puppet:///files/myJenkins/jenkins_id',
    # this repository is created by jenkins scm-sync plugin
    jenkins_scm_sync_git_repo => 'git@bitbucket.org:myOrg/jenkins.git',
  }
}
