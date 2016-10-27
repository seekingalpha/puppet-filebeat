# This class installs the Elastic filebeat log shipper and
# helps manage which files are shipped
#
# @example
# just install Filebeat, no instance will run
# class { 'filebeat': }

# Create Filebeat instance, configured with at lease one output and prospector
# class { 'filebeat':
#   instances           => {
#     'my_filebeat_name'     => {
#       outputs                => {
#              'elasticsearch' =>
#                  'hosts'     => [ 'localhost:9200' ],
#                  'index'     => 'INDEX_NAME',
#       }
#       prospectors            => {
#              'syslog'    =>
#                  'fields_under_root' => true,
#                  'paths'             => ["/var/log/syslog"],
#       }
#     }
#   }
# }
#
# @param package_ensure [String] The ensure parameter for the filebeat package (default: present)
# @param manage_repo [Boolean] Whether or not the upstream (elastic) repo should be configured or not (default: true)
# @param conf_template [String] The configuration template to use to generate the main filebeat.yml config file
# @param download_url [String] The URL of the zip file that should be downloaded to install filebeat (windows only)
# @param install_dir [String] Where filebeat should be installed (windows only)
# @param tmp_dir [String] Where filebeat should be temporarily downloaded to so it can be installed (windows only)
# @param instances [Hash] Instances configuration(each containing at least one output and prospector)
class filebeat (
  $package_ensure   = $filebeat::params::package_ensure,
  $manage_repo      = $filebeat::params::manage_repo,
  $repo_version     = $filebeat::params::repo_version,
  $service_provider = $filebeat::params::service_provider,
  $conf_template    = $filebeat::params::conf_template,
  $download_url     = $filebeat::params::download_url,
  $install_dir      = $filebeat::params::install_dir,
  $tmp_dir          = $filebeat::params::tmp_dir,
  $instances        = {},
) inherits filebeat::params {

  $kernel_fail_message = "${::kernel} is not supported by filebeat."

  validate_bool($manage_repo)

  validate_string($package_ensure, $repo_version)

  if $package_ensure == '1.0.0-beta4' or $package_ensure == '1.0.0-rc1' {
    fail('Filebeat versions 1.0.0-rc1 and before are unsupported because they don\'t parse normal YAML headers')
  }

  anchor { 'filebeat::begin': } ->
  class { 'filebeat::install': } ->
  anchor { 'filebeat::end': }

  create_resources('filebeat::instance', $instances, { 'require' => 'Class[filebeat::install]' })
}
