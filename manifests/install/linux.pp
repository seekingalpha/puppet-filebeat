class filebeat::install::linux {
  package {'filebeat':
    ensure => $filebeat::package_ensure,
  }

  service { 'filebeat':
    ensure   => stopped,
    enable   => false,
    provider => $filebeat::service_provider,
  }
}
