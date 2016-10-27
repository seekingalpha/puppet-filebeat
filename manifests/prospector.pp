define filebeat::prospector (
  $ensure                = present,
  $service_name          = 'filebeat',
  $config_dir            = '/etc/filebeat/conf.d',
  $config_owner          = 'root',
  $config_group          = 'root',
  $config_file_mode      = '0644',
  $paths                 = [],
  $exclude_files         = [],
  $encoding              = 'plain',
  $input_type            = 'log',
  $fields                = {},
  $fields_under_root     = false,
  $ignore_older          = undef,
  $close_older           = undef,
  $doc_type              = 'log',
  $scan_frequency        = '10s',
  $harvester_buffer_size = 16384,
  $tail_files            = false,
  $backoff               = '1s',
  $max_backoff           = '10s',
  $backoff_factor        = 2,
  $force_close_files     = false,
  $include_lines         = [],
  $exclude_lines         = [],
  $max_bytes             = '10485760',
  $multiline             = {},
  #### v5 only ####
  $json_message_key      = undef,
  $json_keys_under_root  = false,
  $json_overwrite_keys   = false,
  $json_add_error_key    = false,
  #### End v5 only ####
) {

  validate_hash($fields, $multiline)
  validate_array($paths, $exclude_files, $include_lines, $exclude_lines)
  validate_string($service_name, $config_dir, $config_owner, $config_group, $config_file_mode)
  validate_bool($json_keys_under_root, $json_overwrite_keys, $json_add_error_key)

  file { "filebeat-${name}":
    ensure  => $ensure,
    path    => "${config_dir}/${name}.yml",
    owner   => $config_owner,
    group   => $config_group,
    mode    => $config_file_mode,
    content => template("${module_name}/prospector.yml.erb"),
    notify  => Service[$service_name],
  }
}
