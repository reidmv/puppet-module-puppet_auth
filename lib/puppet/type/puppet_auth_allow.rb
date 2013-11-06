# Manages allow arrays in Puppet's auth.conf file
#
# Copyright (c) 2012 Raphaël Pinson
# Licensed under the Apache License, Version 2.0

Puppet::Type.newtype(:puppet_auth_allow) do
  @doc = "Manages allow arrays in Puppet's auth.conf."

  ensurable

  newparam(:allow) do
    desc "The string defining the allow entry."
    isnamevar
  end

  newparam(:path) do
    desc "The path for the auth rule."
    isnamevar
  end

  newparam(:name) do
    desc "The name of the resource."
    munge do |_|
      path  = @resource.original_parameters[:path]
      allow = @resource.original_parameters[:allow]
      "#{path.to_s}: allow #{allow.to_s}"
    end
  end

  newparam(:target) do
    desc "The file in which to store the settings, defaults to
      `/etc/puppetlabs/puppet/auth.conf`."
  end

  autorequire(:file) do
    self[:target]
  end

  def self.title_patterns
    identity = lambda {|x| x}
    path     = lambda {|x| x.gsub(/^(.*): allow .*$/, '\1') }
    allow    = lambda {|x| x.gsub(/^.*: allow (.*)$/, '\1') }
    [
      [
        /^((.*): allow (.*))$/,
        [
          [ :name,  identity ],
          [ :path,  path     ],
          [ :allow, allow    ]
        ]
      ],
      [
        /^(.+)$/,
        [
          [ :name, identity ]
        ]
      ]
    ]
  end

end
