
This module runs the oose/dockerjenkins image. 

Use this module to start a jenkins CI server instance as a docker container. The started jenkins is capable of running docker! Cool!

The module will create a "service" to run the docker container (via docker modules). The default service is named "docker-jenkins", in general "docker-${jenkins_name}".

The jenkins config can be supplied as $jenkins_id_dir parameter for example pointing to files. See example and init.pp comments. If omitted, an empty local config dir will be created and populated with a default config on first service start.

Optionally the module can clone a git repository containing the jenkins configuration (created by scm sync plugin) and supply the working copy to the jenkins container. To check out the ssh key must be supplied in $jenkins_id_dir and the repository is configured using $jenkins_scm_sync_git_repo.

When starting multiple jenkins instances on one host, be sure to change the default for the directory containing the config, loacl ports and the service name (suffix).

  $jenkins_home_on_host = '/var/lib/jenkins_home',
  $jenkins_build_agent_port = '50000',
  $jenkins_web_port = '8080',
  $jenkins_name = 'jenkins',


See examples directory of module an init.pp for now. If more documentation is required, plese ping felix.heppner@oose.de.

