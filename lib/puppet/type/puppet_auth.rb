# Manages settings in Puppet's auth.conf file
#
# Copyright (c) 2012 Raphaël Pinson
# Licensed under the Apache License, Version 2.0

Puppet::Type.newtype(:puppet_auth) do
  @doc = "Manages settings in Puppet's auth.conf."

  ensurable

  def munge_boolean(value)
    case value
    when true, "true", :true
      :true
    when false, "false", :false
      :false
    else
      fail("munge_boolean only takes booleans")
    end
  end

  newparam(:path) do
    desc "The path for the auth rule."
    isnamevar
  end

  newproperty(:path_regex, :boolean => true) do
    desc "Whether the path is specified as a regex."

    newvalues(:true, :false)

    munge do |value|
      @resource.munge_boolean(value)
    end
  end

  newparam(:ins_before) do
    desc "Optional XPath expression to specify where to insert the auth rule.

This parameter takes special values working as aliases:

- `first allow`, mapping to `path[allow][1]`;
- `last allow`, mapping to `path[allow][last()]`;
- `first deny`, mapping to `path[count(allow)=0][1]`;
- `last deny`, mapping to path[count(allow)=0][last()]`"
  end

  newparam(:ins_after) do
    desc "Optional XPath expression to specify where to insert the auth rule.

This parameter takes special values working as aliases:

- `first allow`, mapping to `path[allow][1]`;
- `last allow`, mapping to `path[allow][last()]`;
- `first deny`, mapping to `path[count(allow)=0][1]`;
- `last deny`, mapping to path[count(allow)=0][last()]`"
  end

  newproperty(:environments, :array_matching => :all) do
    desc "The list of environments the rule applies to."
  end

  newproperty(:methods, :array_matching => :all) do
    isnamevar
    desc "The list of methods the rule applies to. Possible values are:

- find;
- search;
- save;
- destroy."
  end

  newproperty(:allow_ip, :array_matching => :all) do
    desc "The list of IPs allowed for this rule.
Requires Puppet 3.0.0 or greater."
  end

  newproperty(:authenticated) do
    desc "The type of authentication for the rule. Possible values are:

- yes;
- no;
- on;
- off;
- any."
  end

  newparam(:target) do
    desc "The file in which to store the settings, defaults to
      `#{Puppet[:rest_authconfig]}`."
  end

  newparam(:name) do
    desc "The name of the resource."
    munge do |name|
      path       = @resource[:path]
      path_regex = @resource[:path_regex]
      methods    = @resource[:methods]
      if (path and path_regex and methods)
        Puppet::Type::Puppet_auth.generate_name(path, path_regex, methods)
      else
        name
      end
    end
  end

  autorequire(:file) do
    self[:target]
  end

  def self.title_patterns
    identity = lambda {|x| x}
    methods  = lambda {|x| x.gsub(/^Auth rule (?:for|matching) [^ ]* \((.*)\)$/, '\1').split(', ') }
    path     = lambda {|x| x.gsub(/^Auth rule (?:for|matching) ([^ ]*) \(.*\)$/, '\1') }
    [
      [
        /^(Auth rule (?:for|matching) ([^ ]*) \((.*)\))$/,
        [
          [ :name,    identity ],
          [ :path,    path     ],
          [ :methods, methods  ]
        ]
      ],
      [
        /^(Auth rule (?:for|matching) ([^ ]*))$/,
        [
          [ :name,    identity ],
          [ :path,    path     ],
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

  def self.generate_name(path, path_regex, methods)
    methods_string = methods.empty? ? '' : " (#{methods.join(', ')})"
    pathmethods = "#{path}#{methods_string}"
    formatching = (path_regex == :false) ? 'for' : 'matching'
    name = "Auth rule #{formatching} #{pathmethods}"
  end

end
