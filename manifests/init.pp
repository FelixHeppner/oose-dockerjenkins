# == Define: dockerjenkins
#
# A class for running a jenkins that can run docker and is itself run as a 
# docker container.
# Optionally jenkins config stored in git repo via scm-sync-plugin can be
# restored before start.
# 
# A local directory on the host is used as jenkins home an bound to the
# container as volume.
#
# Configure docker (for example insecure registry) before using this class!!
#
# == Parameters
#
# [*jenkins_home_on_host
#
# The local directory for the jenkins home. Default is /var/lib/jenkins_home/
# 
# [*jenkins_build_agent_port*]
#
# The local port number for build agents to attach to. default is 50000   
#
# [*jenkins_web_port*]
#
# local port number to access the jenkins web frontend. default is 8080
# 
# [*jenkins_name*]
#
# internal name of jenkins instance. default is jenkins
#
# [*jenkins_id_dir*]
#
# Optional. A directory that contains at least a .ssh dir and an id_rsa file
# in there. Optionally other jenkins "secrets" can be stored here. The complete
# dir including sub dirs will be copied to the local jenkins home. 
# The .ssh/id_rsa key is used to checkout the git repo (see below)
#
# [*jenkins_scm_sync_git_repo*]
#
# Optional but when scm is set the id_dir must be set as well.
# A git repo (typically) created by jenkins scm-sync-plugin. The repo will be copied
# to jenkins home in addition to the id_dir.
#
# [*jenkins_links*]
# An optional list of links to other docker containers
#
# [*jenkins_depends*]
# An optional list of containers this jenkins depends on and that have to be started before.
#
# [*jenkins_docker_image_name*]
# The optional docker image name to use. The default is 'oose/dockerjenkins:2'
# 
# [*$jenkins_additional_volumes*]
# A list of strings with volume mappings.
# 
class dockerjenkins(
  $jenkins_home_on_host = '/var/lib/jenkins_home',
  $jenkins_build_agent_port = '50000',
  $jenkins_web_port = '8080',
  $jenkins_name = 'jenkins',
  $jenkins_id_dir = undef,
  $jenkins_scm_sync_git_repo = undef,
  $jenkins_links = [],
  $jenkins_depends = [],
  $jenkins_docker_image_name = 'oose/dockerjenkins:2',
  $jenkins_additional_volumes = []
) {

  require docker

  if $jenkins_id_dir != undef {

    if $jenkins_scm_sync_git_repo != undef {

      require git


      # provide ssh key for checkout of jenkins configuration
      file { "/tmp/${jenkins_name}" :
            ensure  => directory,
            source  => "${jenkins_id_dir}/.ssh",
            recurse => true,
            owner   => root,
            mode    => '0600',
      }

      # checkout jenkins config
      vcsrepo { "${jenkins_home_on_host}/scm-sync-configuration/checkoutConfiguration":
            ensure   => present,
            provider => git,
            source   => $jenkins_scm_sync_git_repo,
            identity => "/tmp/${jenkins_name}/id_rsa",
            require  => File["/tmp/${jenkins_name}"],
      }

      # copy from checkout location to jenkins home 
      # augment config with identity, password, keys etc.
      file { $jenkins_home_on_host :
            ensure       => directory,
            source       => ["${jenkins_home_on_host}/scm-sync-configuration/checkoutConfiguration",$jenkins_id_dir],
            sourceselect => all,
            recurse      => true,
            require      => Vcsrepo["${jenkins_home_on_host}/scm-sync-configuration/checkoutConfiguration"],
            ignore       => '.git',
            owner        => 1000,
            group        => docker,
      }

      # fix owner and group of scm-sync .git repo
      file { "${jenkins_home_on_host}/scm-sync-configuration/checkoutConfiguration/.git" :
            recurse => true,
            require => Vcsrepo["${jenkins_home_on_host}/scm-sync-configuration/checkoutConfiguration"],
            owner   => 1000,
            group   => docker,
      }
    } else {

      # jenkins home with id info only
      file { $jenkins_home_on_host :
            ensure  => directory,
            source  => $jenkins_id_dir,
            recurse => true,
            owner   => 1000,
            group   => docker,
      }
    }

    # fix mode and owner of ssh key
    file { "${jenkins_home_on_host}/.ssh/id_rsa":
        ensure => present,
        source => "${jenkins_id_dir}/.ssh/id_rsa",
        mode   => '0600',
        owner  => 1000,
        group  => docker,

    }

} else {
  # empty jenkins home
  file { $jenkins_home_on_host :
      ensure => directory,
      owner  => 1000,
      group  => docker,
  }
}

  # Think about refactoring ....
  # run
  docker::run { $jenkins_name:
    image   => $jenkins_docker_image_name,
    tty     => false,
    ports   => ["${jenkins_web_port}:8080","${jenkins_build_agent_port}:50000"],
    volumes => concat(['/var/run/docker.sock:/var/run/docker.sock', 
		'/usr/bin/docker:/usr/bin/docker',
		"${jenkins_home_on_host}:/var/jenkins_home" ] ,
		$jenkins_additional_volumes ),

    env     => ['DOCKER_GID_ON_HOST=$(cat /etc/group | grep docker: | cut -d: -f3)'],
    links   => $jenkins_links,
    depends => $jenkins_depends,
    require => File[$jenkins_home_on_host], 
  }

}
