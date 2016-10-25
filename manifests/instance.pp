# @param instance_name [String] a unique name to be used for configuration
# @param spool_size [Integer] How large the spool should grow before being flushed to the network (default: 2048)
# @param idle_timeout [String] How often the spooler should be flushed even if spool size isn't reached (default: 5s)
# @param publish_async [Boolean] If set to true filebeat will publish while preparing the next batch of lines to send (defualt: false)
# @param registry_file [String] The registry file used to store positions, absolute or relative to working directory (default .filebeat)
# @param config_dir [String] The directory where prospectors should be defined (default: /etc/filebeat/conf.d)
# @param config_dir_mode [String] The unix permissions mode set on the configuration directory (default: 0755)
# @param config_file_mode [String] The unix permissions mode set on configuration files (default: 0644)
# @param purge_conf_dir [Boolean] Should files in the prospector configuration directory not managed by puppet be automatically purged
# @param outputs [Hash] Will be converted to YAML for the required outputs section of the configuration (see documentation, and above)
# @param shipper [Hash] Will be converted to YAML to create the optional shipper section of the filebeat config (see documentation)
# @param logging [Hash] Will be converted to YAML to create the optional logging section of the filebeat config (see documentation)
# @param prospectors [Hash] Prospectors that will be created. Commonly used to create prospectors using hiera
# @param prospectors_merge [Boolean] Whether $prospectors should merge all hiera sources, or use simple automatic parameter lookup
define filebeat::instance (
  $instance_name     = $name,
  $spool_size        = 2048,
  $idle_timeout      = '5s',
  $publish_async     = false,
  $registry_file     = ".filebeat_${instance_name}",
  $config_dir_mode   = '0755',
  $config_file_mode  = '0644',
  $purge_conf_dir    = true,
  #### v5 only ####
  $shutdown_timeout  = 0,
  $beat_name         = $::fqdn,
  $tags              = [],
  $queue_size        = 1000,
  $max_procs         = undef,
  $fields            = {},
  $fields_under_root = false,
  #### End v5 onlly ####
  $outputs           = {},
  $shipper           = {},
  $logging           = {},
  $run_options       = {},
  $prospectors       = {},
  $prospectors_merge = false,
  $service_ensure    = running,
  $service_enable    = true,
) {

  validate_hash($outputs, $logging)
  validate_string($instance_name, $idle_timeout, $registry_file)
  validate_bool($prospectors_merge)

  if empty($outputs) {
    fail("Outputs cannot be empty for instance [$instance_name]")
  }

  case $::kernel {
    'Linux'   : {
      $instance_dir = "/etc/filebeat_${instance_name}"
      $config_file  = "${instance_dir}/filebeat.yml"
      $config_dir   = "${instance_dir}/conf.d"
      $config_owner  = 'root'
      $config_group  = 'root'
      $service_name = "filebeat-${instance_name}"

      case $::osfamily {
        'RedHat': {
          $service_provider = 'redhat'
        }
        default: {
          $service_provider = undef
        }
      }

      file { "/etc/systemd/system/filebeat-${instance_name}.service":
        content => template('filebeat/filebeat.service.erb'),
        owner   => $config_owner,
        group   => $config_group,
        notify  => Service[$service_name],
      }

      service { $service_name :
        ensure   => $service_ensure,
        enable   => $service_enable,
        provider => $filebeat::service_provider,
      }
    } # end Linux

    'Windows' : {
      $instance_dir     = "C:/Program Files/Filebeat_${instance_name}"
      $config_file      = "${instance_dir}/filebeat.yml"
      $config_dir       = "${instance_dir}/conf.d"
      $config_owner      = undef
      $config_group      = undef
      $tmp_dir          = 'C:/Windows/Temp'
      $service_provider = undef

    } # end Windows

    default : {
      fail($filebeat::kernel_fail_message)
    }
  }

  $filebeat_config = {
    'shutdown_timeout'  => $filebeat::shutdown_timeout,
    'beat_name'         => $filebeat::beat_name,
    'tags'              => $filebeat::tags,
    'queue_size'        => $filebeat::queue_size,
    'max_procs'         => $filebeat::max_procs,
    'fields'            => $filebeat::fields,
    'fields_under_root' => $filebeat::fields_under_root,
    'filebeat'   => {
      'spool_size'    => $spool_size,
      'idle_timeout'  => $idle_timeout,
      'registry_file' => $registry_file,
      'publish_async' => $publish_async,
      'config_dir'    => $config_dir,
      'shutdown_timeout' => $shutdown_timeout,
    },
    'output'     => $outputs,
    'shipper'    => $shipper,
    'logging'    => $logging,
    'runoptions' => $run_options,
  }

  file { "filebeat-instance-dir-${instance_name}":
    ensure  => directory,
    path    => $instance_dir,
    owner   => $config_owner,
    group   => $config_group,
    mode    => $config_dir_mode,
    recurse => $purge_conf_dir,
    purge   => $purge_conf_dir,

  }

  file {"filebeat_${instance_name}.yml":
    ensure  => file,
    path    => $config_file,
    content => template($filebeat::conf_template),
    owner   => $config_owner,
    group   => $config_group,
    mode    => $config_file_mode,
    notify  => Service["filebeat-${instance_name}"],
    require => File[$instance_dir],
  }

  file {"filebeat-config-dir-${instance_name}":
    ensure  => directory,
    path    => $config_dir,
    owner   => $config_owner,
    group   => $config_group,
    mode    => $config_dir_mode,
    recurse => $purge_conf_dir,
    purge   => $purge_conf_dir,
    require => File[$instance_dir],
  }

  if $prospectors_merge {
    $prospectors_final = hiera_hash('filebeat::prospectors', $prospectors)
  } else {
    $prospectors_final = $prospectors
  }

  validate_hash($prospectors_final)

  if !empty($prospectors_final) {
    $prospector_defaults = {
      'service_name'     => $service_name,
      'config_dir'       => $config_dir,
      'config_owner'     => $config_owner,
      'config_group'     => $config_group,
      'config_file_mode' => $config_file_mode,
      'require'          => "File[filebeat-config-dir-${instance_name}]",
    }
    create_resources('filebeat::prospector', $prospectors_final, $prospector_defaults)
  }

}
