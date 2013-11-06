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

  newparam(:path_regex, :boolean => true) do
    desc "Whether the path is specified as a regex."

    newvalues(:true, :false)

    munge do |value|
      @resource.munge_boolean(value)
    end
  end

  newproperty(:environments, :array_matching => :all) do
    desc "The list of environments the rule applies to."
  end

  newproperty(:methods, :array_matching => :all) do
    isnamevar
    desc <<-EOS
      The list of methods the rule applies to. Possible values are:

        - find;
        - search;
        - save;
        - destroy.
    EOS
  end

  newproperty(:allow_ip, :array_matching => :all) do
    desc <<-EOS
      The list of IPs allowed for this rule.
      Requires Puppet 3.0.0 or greater."
    EOS
  end

  newproperty(:priority) do
    desc <<-EOS
      The priority by which to order the rule. Numeric. Greater than zero.
      The smaller the number the earlier in the list the rule will be inserted.
    EOS
    validate do |val|
      val.to_i != 0
    end
  end

  newparam(:allow, :array_matching => :all) do
    desc <<-EOS
      A list of certnames allowed for this rule.
      Note that these can also be managed seperately. Setting this
      parameter creates appropriate puppet_auth_allow resources.
    EOS
    munge { |allow| [allow].flatten }
  end

  newproperty(:authenticated) do
    desc <<-EOS
      The type of authentication for the rule. Possible values are:

        - yes;
        - no;
        - on;
        - off;
        - any.
    EOS
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

  def generate
    allows = []
    if parameters[:allow]
      [parameters[:allow].value].flatten.each do |allow|
        allows << Puppet::Type.type(:puppet_auth_allow).new({
          :ensure => :present,
          :name   => "#{parameters[:path].value}: allow #{allow}",
          :path   => parameters[:path].value,
          :allow  => allow
        })
      end
    end
    allows
  end

  def self.title_patterns
    identity   = lambda {|x| x}
    methods    = lambda {|x| x.gsub(/^Auth rule (?:for|matching) [^ ]* \((.*)\)$/, '\1').split(', ') }
    path       = lambda {|x| x.gsub(/^Auth rule (?:for|matching) ([^ ]*) \(.*\)$/, '\1') }
    path_regex = lambda {|x| x =~ /^Auth rule matching / ? :true : :false }
    [
      [
        /^(Auth rule (for|matching) ([^ ]*) \((.*)\))$/,
        [
          [ :name,       identity   ],
          [ :path_regex, path_regex ],
          [ :path,       path       ],
          [ :methods,    methods    ]
        ]
      ],
      [
        /^(Auth rule (for|matching) ([^ ]*))$/,
        [
          [ :name,       identity   ],
          [ :path_regex, path_regex ],
          [ :path,       path       ]
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
