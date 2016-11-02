class filebeat::repo {
  case $::osfamily {
    'Debian': {
      include ::apt
      Class['apt::update'] -> Package['filebeat']

      if versioncmp($filebeat::repo_version, '1.3') > 0 {
        $final_location = "https://artifacts.elastic.co/packages/${filebeat::repo_version}/apt"
      } else {
        $final_location = "https://packages.elastic.co/beats/apt"
      }

      if !defined(Apt::Source['beats']){
        apt::source { 'beats':
          location => $final_location,
          release  => 'stable',
          repos    => 'main',
          key      => {
            id     => '46095ACC8548582C1A2699A9D27D666CD88E42B4',
            source => 'http://packages.elastic.co/GPG-KEY-elasticsearch',
          },
        }
      }
    }
    'RedHat', 'Linux': {
      if !defined(Yumrepo['beats']){
        yumrepo { 'beats':
          descr    => 'elastic beats repo',
          baseurl  => 'https://packages.elastic.co/beats/yum/el/$basearch',
          gpgcheck => 1,
          gpgkey   => 'http://packages.elastic.co/GPG-KEY-elasticsearch',
          enabled  => 1,
        }
      }
    }
    'Suse': {
      exec { 'topbeat_suse_import_gpg':
        command => 'rpmkeys --import http://packages.elastic.co/GPG-KEY-elasticsearch',
        unless  => 'test $(rpm -qa gpg-pubkey | grep -i "D88E42B4" | wc -l) -eq 1 ',
        notify  => [ Zypprepo['beats'] ],
      }
      if !defined(Zypprepo['beats']){
        zypprepo { 'beats':
          baseurl     => 'https://packages.elastic.co/beats/yum/el/$basearch',
          enabled     => 1,
          autorefresh => 1,
          name        => 'beats',
          gpgcheck    => 1,
          gpgkey      => 'http://packages.elastic.co/GPG-KEY-elasticsearch',
          type        => 'yum',
        }
      }
    }
    default: {
      fail($filebeat::kernel_fail_message)
    }
  }
}
