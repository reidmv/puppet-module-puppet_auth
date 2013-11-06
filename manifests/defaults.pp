class puppet_auth::defaults {

  puppet_auth { 'Auth rule matching ^/catalog/([^/]+)$ (find)':
    ensure  => 'present',
    methods => ['find'],
    allow   => '$1',
  } ->
  puppet_auth { 'Auth rule matching ^/node/([^/]+)$ (find)':
    ensure  => 'present',
    methods => ['find'],
    allow   => '$1',
  } ->
  puppet_auth { 'Auth rule for /file':
    ensure => 'present',
    allow  => '*',
  } ->
  puppet_auth { 'Auth rule for /certificate_revocation_list/ca (find)':
    ensure  => 'present',
    methods => ['find'],
    allow   => '*',
  } ->
  puppet_auth { 'Auth rule for /report (save)':
    ensure  => 'present',
    methods => ['save'],
    allow   => '*',
  } ->
  puppet_auth { 'Auth rule for /certificate/ca (find)':
    ensure        => 'present',
    authenticated => 'no',
    methods       => ['find'],
    allow         => '*',
  } ->
  puppet_auth { 'Auth rule for /certificate/ (find)':
    ensure        => 'present',
    authenticated => 'no',
    methods       => ['find'],
    allow         => '*',
  } ->
  puppet_auth { 'Auth rule for /certificate_request (find, save)':
    ensure        => 'present',
    authenticated => 'no',
    methods       => ['find', 'save'],
    allow         => '*',
  }

}
