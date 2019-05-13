class filebeat::params {
  $package_ensure = present
  $manage_repo    = true
  $repo_version     = '1.3'

  if versioncmp('1.9.1', $::rubyversion) > 0 {
    $ruby_yaml_support = false
    $conf_template = "${module_name}/filebeat.yml.ruby18.erb"
  } else {
    $ruby_yaml_support = true
    $conf_template = "${module_name}/filebeat.yml.erb"
  }

  case $::kernel {
    'Linux'   : {
      # These parameters are ignored if/until tarball installs are supported in Linux
      $tmp_dir         = '/tmp'
      $install_dir     = undef
      $download_url    = undef
      case $::osfamily {
        'RedHat': {
          $service_provider = 'redhat'
        }
        default: {
          $service_provider = undef
        }
      }
    }

    'Windows' : {
      $download_url     = 'https://download.elastic.co/beats/filebeat/filebeat-1.3.1-windows.zip'
      $install_dir      = 'C:/Program Files'
      $tmp_dir          = 'C:/Windows/Temp'
      $service_provider = undef
    }

    default : {
      fail($filebeat::kernel_fail_message)
    }
  }
}
