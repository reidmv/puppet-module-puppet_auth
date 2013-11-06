class puppet_auth::purge {

  resources { 'puppet_auth':
    purge => true,
  }
  resources { 'puppet_auth_allow':
    purge => true,
  }

}
