actions :create, :delete
default_action :create

attribute :name, :kind_of => String, :name_attribute => true
attribute :sites, :kind_of => Array
attribute :options, :kind_of => Hash, :default => {}

attr_accessor :exists, :guid, :distinguished_name
