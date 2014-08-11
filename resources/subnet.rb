actions :create, :delete
default_action :create

attribute :name, :kind_of => String, :name_attribute => true
attribute :site, :kind_of => String
attribute :options, :kind_of => Hash, :default => {}

attr_accessor :exists, :guid, :distinguished_name
