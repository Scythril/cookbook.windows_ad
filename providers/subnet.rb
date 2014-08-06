include Chef::Mixin::PowershellOut

use_inline_resources

def whyrun_supported?
  true
end

action :create do
  if @current_resource.exists
    Chef::Log.debug("#{@new_resource} already exists.")
  else
    converge_by("Create AD subnet #{@new_resource}") do
      # New-ADReplicationSubnet [-Name] <String> [[-Site] <ADReplicationSite> ] [-AuthType <ADAuthType> {Negotiate | Basic} ] [-Credential <PSCredential> ] [-Description <String> ] [-Instance <ADReplicationSubnet> ] [-Location <String> ] [-OtherAttributes <Hashtable> ] [-PassThru] [-Server <String> ] [-Confirm] [-WhatIf] [ <CommonParameters>]
      cmd_text = "New-ADReplicationSubnet #{@new_resource.name}"

      if !@new_resource.domain_user.nil? && !@new_resource.domain_user.empty? &&
         !@new_resource.domain_pass.nil? && !@new_resource.domain_pass.empty?
        cmd_text = create_ps_credential(@new_resource.domain_user, @new_resource.domain_pass) + cmd_text + " -Credential $mycreds"
      end

      if !@new_resource.site.nil?
        cmd_text << " -Site '#{@new_resource.site}'"
      end

      @new_resource.options.each do |option, value|
        if value.nil?
          cmd_text << " -#{option}"
        else
          cmd_text << " -#{option} '#{value}'"
        end
      end

      cmd = powershell_out(cmd_text)
      Chef::Log.debug("#{@new_resource} create subnet output: #{cmd.stdout}")
      if !cmd.stderr.empty?
        Chef::Log.error("Error creating subnet site: #{cmd.stderr}")
      else
        Chef::Log.info("#{@new_resource} created successfully.")
        new_resource.updated_by_last_action(true)
      end
    end
  end
end

action :delete do

end

def load_current_resource
  @current_resource = Chef::Resource::WindowsAdSubnet.new(@new_resource.name)
  @current_resource.exists = false

  cmd = powershell_out("Get-ADReplicationSubnet -Filter { Name -eq '#{@current_resource.name}' } | Select-Object Name, DistinguishedName, ObjectGUID | ConvertTo-Json")
  Chef::Log.debug("#{@new_resource} get subnet output: #{strip_carriage_returns(cmd.stdout)}")
  if !cmd.stderr.empty?
    Chef::Log.error("#{@current_resource} get subnet threw an error: #{strip_carriage_returns(cmd.stderr)}")
  elsif !cmd.stdout.empty?
    subnet = JSON.parse(strip_carriage_returns(cmd.stdout))
  else
    Chef::Log.debug("#{@current_resource} subnet not found.")
  end

  if subnet
    @current_resource.name(subnet['Name'])
    @current_resource.guid = subnet['ObjectGUID']
    @current_resource.distinguished_name = subnet['DistinguishedName']
    @current_resource.exists = true
  end
end

private
def strip_carriage_returns (output)
  output.gsub(/\r/, '')
end

def create_ps_credential(user, pass)
  return <<-EOH
  $secpasswd = ConvertTo-SecureString '#{pass}' -AsPlainText -Force
  $mycreds = New-Object System.Management.Automation.PSCredential ('#{user}', $secpasswd)
  EOH
end