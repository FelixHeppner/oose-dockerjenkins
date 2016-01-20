require 'spec_helper'

describe 'dockerjenkins', :type => :class do
  
  context "Install default Jenkins" do 
   
    let :facts do
      {
        :lsbdistid => 'Debian',
        :osfamily => 'Debian'
      }
    end
   
    it do
      # empty conf dir created
      should contain_file('/var/lib/jenkins_home').with( {
        'ensure' => 'directory',
        'owner' => '1000',
        'group' => 'docker'    
      })
      # service that runs docker container is present
      should contain_service('docker-jenkins')

      should contain_package('docker')
    end
  end
end
