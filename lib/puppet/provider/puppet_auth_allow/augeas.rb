# Alternative Augeas-based providers for Puppet
#
# Copyright (c) 2012 Raphaël Pinson
# Licensed under the Apache License, Version 2.0

require 'puppetx/augeasprovider/provider'

Puppet::Type.type(:puppet_auth_allow).provide(:augeas) do
  desc "Uses Augeas API to update an allow entry in Puppet's auth.conf."

  include PuppetX::AugeasProvider::Provider

  default_file { Puppet[:rest_authconfig] }

  lens { 'Puppet_Auth.lns' }

  confine :feature => :augeas
  confine :exists => target

  resource_path do |resource|
    path  = resource[:path]
    allow = resource[:allow]
    "$target/path[.='#{path}']/allow/*[.='#{allow}']"
  end

  def self.instances
    resources = []
    augopen do |aug|
      settings = aug.match("$target/path")

      settings.each do |pathnode|
        # Set $resource for each
        setvars(aug)

        path   = aug.get(pathnode)
        allows = attr_aug_reader_allow(aug)

        # Define a resource for each allow
        allows.each do |allow|
          resources << new(
            :name   => "#{path}: allow #{allow}",
            :ensure => :present,
            :path   => path,
            :allow  => allow
          )
        end
      end
    end
    resources
  end

  def create
    augopen! do |aug|
      #aug.defvar('allow', "$target/path[.='#{resource[:path]}']/allow")
      allow = "$target/path[.='#{resource[:path]}']/allow"
      aug.set(allow, nil) if aug.match("#{allow}/*").empty?

      last_allow = aug.match("#{allow}/*[last()]").last
      last_index = last_allow ? last_allow.split('/').last : '0'
      next_index = (last_index.to_i + 1).to_s

      aug.set("#{allow}/#{next_index}", resource[:allow])
    end
  end

  def destroy
    augopen! do |aug|
      aug.rm('$resource')
      aug.defvar('allow', "$target/path[.='#{resource[:path]}']/allow")
      aug.rm('$allow') if aug.match('$allow/*').empty?
    end
  end

  attr_aug_accessor(:allow,
    :type        => :array,
    :sublabel    => :seq
  )

end
