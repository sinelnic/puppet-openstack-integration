class openstack_integration::repos {

  case $::osfamily {
    'Debian': {
      include ::apt
      class { '::openstack_extras::repo::debian::ubuntu':
        release         => 'mitaka',
        package_require => true,
      }
      # Ceph is both packaged on UCA & ceph.com
      # Official packages are on ceph.com so we want to make sure
      # Ceph will be installed from there.
      apt::pin { 'ceph':
        priority => 1001,
        origin   => 'download.ceph.com',
      }
    }
    'RedHat': {
      class { '::openstack_extras::repo::redhat::redhat':
        manage_rdo  => false,
        manage_epel => false,
        repo_hash   => {
          'newton-current' => {
            'baseurl'  => 'https://trunk.rdoproject.org/centos7-master/ac/73/ac73adf839501ecdbb4aa3af8e1e624c0d3116b1_5c24f657/',
            'descr'    => 'Newton current',
            'gpgcheck' => 'no',
            'priority' => 1,
          },
          'delorean-deps'  => {
            'baseurl'  => 'http://buildlogs.centos.org/centos/7/cloud/$basearch/openstack-mitaka/',
            'descr'    => 'Mitaka delorean-deps',
            'gpgcheck' => 'no',
            'priority' => 2,
          },
        }
      }
    }
    default: {
      fail("Unsupported osfamily (${::osfamily})")
    }
  }

  # On CentOS, deploy Ceph using SIG repository and get rid of EPEL.
  # https://wiki.centos.org/SpecialInterestGroup/Storage/
  if $::operatingsystem == 'CentOS' {
    $enable_sig  = true
    $enable_epel = false
  } else {
    $enable_sig  = false
    $enable_epel = true
  }

  class { '::ceph::repo':
    enable_sig  => $enable_sig,
    enable_epel => $enable_epel,
  }

}
