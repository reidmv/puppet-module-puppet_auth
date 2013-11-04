class puppet_auth::defaults {

  puppet_auth { 'test':
    path       => '^/catalog/([^/]+)$',
    ensure     => 'present',
    methods    => ['find'],
    path_regex => 'true',
  }

}
