class puppet_auth::defaults {

  # Note: default priority is 100

  puppet_auth { 'Auth rule for ^/catalog/([^/]+)$ (find)':
    path_regex => true,
    ensure     => 'present',
    methods    => ['find'],
    allow      => '$1',
    priority   => '50',
  }
  puppet_auth { 'Auth rule for ^/node/([^/]+)$ (find)':
    path_regex => true,
    ensure     => 'present',
    methods    => ['find'],
    allow      => '$1',
    priority   => '52',
  }
  puppet_auth { 'Auth rule for /file':
    ensure   => 'present',
    allow    => '*',
    priority => '54',
  }
  puppet_auth { 'Auth rule for /certificate_revocation_list/ca (find)':
    ensure   => 'present',
    methods  => ['find'],
    allow    => '*',
    priority => '56',
  }
  puppet_auth { 'Auth rule for /report (save)':
    ensure   => 'present',
    methods  => ['save'],
    allow    => '*',
    priority => '58',
  }
  puppet_auth { 'Auth rule for /certificate/ca (find)':
    ensure        => 'present',
    authenticated => 'no',
    methods       => ['find'],
    allow         => '*',
    priority      => '60',
  }
  puppet_auth { 'Auth rule for /certificate/ (find)':
    ensure        => 'present',
    authenticated => 'no',
    methods       => ['find'],
    allow         => '*',
    priority      => '62',
  }
  puppet_auth { 'Auth rule for /certificate_request (find, save)':
    ensure        => 'present',
    authenticated => 'no',
    methods       => ['find', 'save'],
    allow         => '*',
    priority      => '64',
  }

}
