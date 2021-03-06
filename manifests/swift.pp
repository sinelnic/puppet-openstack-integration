class openstack_integration::swift {

  include ::openstack_integration::config

  # TODO(emilien): deploy memcached in IPv6
  include ::memcached
  class { '::swift':
    swift_hash_path_suffix => 'secrete',
  }
  class { '::swift::proxy':
    proxy_local_net_ip => $::openstack_integration::config::host,
    workers            => '2',
    pipeline           => [
  'catch_errors', 'healthcheck', 'cache', 'tempurl', 'ratelimit',
  'authtoken', 'keystone', 'formpost', 'staticweb', 'container_quotas',
  'account_quotas', 'proxy-logging', 'proxy-server'
    ],
  }
  include ::swift::proxy::catch_errors
  include ::swift::proxy::healthcheck
  include ::swift::proxy::proxy_logging
  # TODO(emilien): deploy ::swift::proxy::cache in IPv6
  include ::swift::proxy::cache
  include ::swift::proxy::tempurl
  include ::swift::proxy::ratelimit
  class { '::swift::proxy::authtoken':
    auth_uri       => "${::openstack_integration::config::keystone_auth_uri}/v2.0",
    identity_uri   => "${::openstack_integration::config::keystone_admin_uri}/",
    admin_password => 'a_big_secret',
  }
  class { '::swift::proxy::keystone':
    operator_roles => ['Member', 'admin', 'SwiftOperator']
  }
  include ::swift::proxy::formpost
  include ::swift::proxy::staticweb
  include ::swift::proxy::container_quotas
  include ::swift::proxy::account_quotas
  include ::swift::proxy::tempauth
  class { '::swift::keystone::auth':
    public_url     => "http://${::openstack_integration::config::ip_for_url}:8080/v1/AUTH_%(tenant_id)s",
    admin_url      => "http://${::openstack_integration::config::ip_for_url}:8080",
    internal_url   => "http://${::openstack_integration::config::ip_for_url}:8080/v1/AUTH_%(tenant_id)s",
    password       => 'a_big_secret',
    operator_roles => ['admin', 'SwiftOperator', 'ResellerAdmin'],
  }
  file { '/srv/node':
    ensure  => directory,
    owner   => 'swift',
    group   => 'swift',
    require => Package['swift'],
  }
  include ::swift::ringbuilder
  class { '::swift::storage::all':
    storage_local_net_ip => $::openstack_integration::config::host,
    incoming_chmod       => 'Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r',
    outgoing_chmod       => 'Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r',
    mount_check          => false,
  }
  $swift_components = ['account', 'container', 'object']
  swift::storage::filter::recon { $swift_components : }
  swift::storage::filter::healthcheck { $swift_components : }
  # As of mitaka swift-ring-builder requires devices >= replica count
  # Default replica count is 3
  ring_object_device { ["${::openstack_integration::config::ip_for_url}:6000/1", "${::openstack_integration::config::ip_for_url}:6000/2", "${::openstack_integration::config::ip_for_url}:6000/3"]:
    zone   => 1,
    weight => 1,
  }
  ring_container_device { ["${::openstack_integration::config::ip_for_url}:6001/1", "${::openstack_integration::config::ip_for_url}:6001/2", "${::openstack_integration::config::ip_for_url}:6001/3"]:
    zone   => 1,
    weight => 1,
  }
  ring_account_device { ["${::openstack_integration::config::ip_for_url}:6002/1", "${::openstack_integration::config::ip_for_url}:6002/2", "${::openstack_integration::config::ip_for_url}:6002/3"]:
    zone   => 1,
    weight => 1,
  }
}
