actions :create, :rename, :delete
default_action :create

attribute :name, :kind_of => String, :name_attribute => true
attribute :new_name, :kind_of => String
attribute :domain_user, :kind_of => String
attribute :domain_pass, :kind_of => String
attribute :options, :kind_of => Hash, :default => {}

attr_accessor :exists, :guid, :distinguished_name
