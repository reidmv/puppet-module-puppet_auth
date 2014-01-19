# Alternative Augeas-based providers for Puppet
#
# Copyright (c) 2012 Raphaël Pinson
# Licensed under the Apache License, Version 2.0

require 'puppetx/augeasprovider/provider'

Puppet::Type.type(:puppet_auth).provide(:augeas) do
  desc "Uses Augeas API to update a rule in Puppet's auth.conf."

  include PuppetX::AugeasProvider::Provider

  default_file { Puppet[:rest_authconfig] }

  lens { 'Puppet_Auth.lns' }

  confine :feature => :augeas
  confine :exists => target

  resource_path do |resource|
    path = resource[:path]
    "$target/path[.='#{path}']"
  end

  def path_regex
    augopen do |aug|
      aug.match("#{resource_path}/operator").empty? ? :false : :true
    end
  end

  def path_regex=(val)
    augopen! do |aug|
      case val
      when :true
        aug.insert('$resource/*[1]', 'operator', true)
        aug.set('$resource/operator', '~')
      when :false
        aug.rm('$resource/operator')
      end
    end
  end

  def priority
    result = nil
    augopen do |aug|
      paths    = aug.match("$target/path")
      resource = aug.match('$resource').first
      default  = Puppet::Type::Puppet_auth.default_priority
      max      = 0

      paths.each do |path|
        tagged_priority = aug.get("#{path}/#comment[.=~regexp('^Priority: [0-9]+$')]")
        tagged_priority.gsub!(/Priority: ([0-9]+)/, '\1') if tagged_priority

        if !tagged_priority
          localmax = [(max or 0), default].max
        else
          localmax = tagged_priority
        end

        current_priority = [max, localmax.to_i, (tagged_priority or 0).to_i].max
        if path == resource
          result = current_priority
          break
        else
          max = current_priority
        end
      end
    end
    result.to_s
  end

  def priority=(should)
    augopen! do |aug|
      set_priority(aug, should)
    end
  end

  def set_priority(aug, should)
    insert_before_node = nil
    nodes         = aug.match("$target/path")
    resource      = aug.match('$resource').first
    default       = Puppet::Type::Puppet_auth.default_priority
    max           = 0
    priority      = "#comment[.=~regexp('^Priority: [0-9]+$')]"

    if aug.match('$resource/#comment').empty? or aug.match("$resource/#{priority}").empty?
      # We can't insert the comment into the tree above the operator
      i = aug.match('$resource/*[1]').first =~ %r{/operator$} ? '2' : '1'
      aug.insert("$resource/*[#{i}]", '#comment', true)
      aug.set("$resource/*[#{i}]", "Priority: #{should}")
    else
      aug.set("$resource/#{priority}", "Priority: #{should}")
    end

    nodes.each do |node|
      tagged_priority = aug.get("#{node}/#{priority}")
      tagged_priority.gsub!(/Priority: ([0-9]+)/, '\1') if tagged_priority

      if !tagged_priority
        localmax = [(max or 0), default].max
      else
        localmax = tagged_priority
      end

      current_priority = [max, localmax.to_i, (tagged_priority or 0).to_i].max
      if current_priority > should.to_i
        insert_before_node = node
        break
      else
        max = current_priority
      end
    end

    if insert_before_node
      aug.insert(insert_before_node, 'path', true)
      aug.mv("$resource", insert_before_node)
    else
      aug.insert("$target/path[last()]", 'path', false)
      aug.mv('$resource', '$target/path[last()]')
    end
  end

  def self.instances
    resources = []
    augopen do |aug|
      settings = aug.match("$target/path")

      settings.each do |node|
        # Set $resource for getters
        aug.defvar('resource', node)

        path = aug.get(node)
        path_regex = aug.match("#{node}/operator").empty? ? :false : :true
        environments = attr_aug_reader_environments(aug)
        methods = attr_aug_reader_methods(aug)
        allow_ip = attr_aug_reader_allow_ip(aug)
        authenticated = attr_aug_reader_authenticated(aug)
        name = Puppet::Type::Puppet_auth.generate_name(path, path_regex, methods)
        priority_comment = aug.get("#{node}/#comment[.=~regexp('^Priority: [0-9]+$')]")
        priority = priority_comment ? priority_comment.gsub(/[^\d]*(\d+)/, '\1').to_i : 10

        entry = {
          :ensure        => :present,
          :name          => name,
          :path          => path,
          :path_regex    => path_regex,
          :environments  => environments,
          :methods       => methods,
          :allow_ip      => allow_ip,
          :authenticated => authenticated,
          :priority      => priority
        }

        resources << new(entry) if entry[:path]
      end
    end
    resources
  end

  def create
    apath         = resource[:path]
    apath_regex   = resource[:path_regex]
    environments  = resource[:environments]
    methods       = resource[:methods]
    allow_ip      = resource[:allow_ip]
    allow         = resource[:allow]
    authenticated = resource[:authenticated]
    priority      = resource[:priority]

    augopen! do |aug|
      aug.insert('$target/path', 'path', false)
      aug.set("$target/path[.='']", apath)

      ## Refresh $resource
      setvars(aug)

      aug.set('$resource/operator', "~") if apath_regex == :true
      attr_aug_writer_environments(aug, environments) if environments
      attr_aug_writer_methods(aug, methods) if methods
      attr_aug_writer_allow_ip(aug, allow_ip) if allow_ip
      attr_aug_writer_allow(aug, allow) if allow
      attr_aug_writer_authenticated(aug, authenticated) if authenticated
      set_priority(aug, priority) if priority
    end
  end

  attr_aug_accessor(:environments,
    :label       => 'environment',
    :type        => :array,
    :sublabel    => :seq,
    :purge_ident => true
  )

  attr_aug_accessor(:methods,
    :label       => 'method',
    :type        => :array,
    :sublabel    => :seq,
    :purge_ident => true
  )

  attr_aug_accessor(:allow_ip,
    :type        => :array,
    :sublabel    => :seq,
    :purge_ident => true
  )

  attr_aug_accessor(:allow,
    :type        => :array,
    :sublabel    => :seq,
    :purge_ident => true
  )

  attr_aug_accessor(:authenticated,
    :label       => 'auth',
    :purge_ident => true
  )

end
