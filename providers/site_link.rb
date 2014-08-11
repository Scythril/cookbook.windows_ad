include Chef::Mixin::PowershellOut
include WindowsAd::Helper

use_inline_resources

def whyrun_supported?
  true
end

action :create do
  if @current_resource.exists
    Chef::Log.debug("#{@new_resource} already exists.")
  else
    converge_by("Create AD site link #{@new_resource}") do
      # New-ADReplicationSiteLink [-Name] <String> [[-SitesIncluded] <ADReplicationSite[]> ] [-AuthType <ADAuthType> {Negotiate | Basic} ] [-Cost <Int32> ] [-Credential <PSCredential> ] [-Description <String> ] [-Instance <ADReplicationSiteLink> ] [-InterSiteTransportProtocol <ADInterSiteTransportProtocolType> {IP | SMTP} ] [-OtherAttributes <Hashtable> ] [-PassThru] [-ReplicationFrequencyInMinutes <Int32> ] [-ReplicationSchedule <ActiveDirectorySchedule> ] [-Server <String> ] [-Confirm] [-WhatIf] [ <CommonParameters>]
      cmd_text = "New-ADReplicationSiteLink #{@new_resource.name}"

      if !@new_resource.sites.nil? && !@new_resource.sites.empty?
        cmd_text << " -SitesIncluded #{@new_resource.sites.join(',')}"
      end

      @new_resource.options.each do |option, value|
        if value.nil?
          cmd_text << " -#{option}"
        else
          cmd_text << " -#{option} '#{value}'"
        end
      end

      cmd = powershell_out(cmd_text)
      Chef::Log.debug("#{@new_resource} create site link output: #{cmd.stdout}")
      if !cmd.stderr.empty?
        Chef::Log.error("Error creating site link: #{cmd.stderr}")
      else
        Chef::Log.info("#{@new_resource} created successfully.")
        new_resource.updated_by_last_action(true)
      end
    end
  end
end

action :delete do
  if !@current_resource.exists
    Chef::Log.debug("#{@new_resource} doesn't exist.")
  else
    converge_by("Delete AD site link #{@new_resource}") do
      # Remove-ADReplicationSiteLink [-Identity] <ADReplicationSiteLink> [-AuthType <ADAuthType> {Negotiate | Basic} ] [-Credential <PSCredential> ] [-Server <String> ] [-Confirm] [-WhatIf] [ <CommonParameters>]
      cmd_text = "Remove-ADReplicationSiteLink '#{@current_resource.distinguished_name}' -Confirm:$false"

      cmd = powershell_out(cmd_text)
      Chef::Log.debug("#{@new_resource} delete site link output: #{cmd.stdout}")
      if !cmd.stderr.empty?
        Chef::Log.error("Error deleting site link: #{cmd.stderr}")
      else
        Chef::Log.info("#{@new_resource} deleted successfully.")
        new_resource.updated_by_last_action(true)
      end
    end
  end
end

def load_current_resource
  @current_resource = Chef::Resource::WindowsAdSiteLink.new(@new_resource.name)
  @current_resource.exists = false

  # Get-ADReplicationSiteLink -Filter <String> [-AuthType <ADAuthType> {Negotiate | Basic} ] [-Credential <PSCredential> ] [-Properties <String[]> ] [-Server <String> ] [ <CommonParameters>]
  cmd = powershell_out("Get-ADReplicationSiteLink -Filter { Name -eq '#{@current_resource.name}' } | Select-Object Name, ObjectGUID, DistinguishedName | ConvertTo-Json")
  Chef::Log.debug("#{@new_resource} get site output: #{strip_carriage_returns(cmd.stdout)}")
  if !cmd.stderr.empty?
    Chef::Log.error("#{@current_resource} get site link threw an error: #{strip_carriage_returns(cmd.stderr)}")
  elsif !cmd.stdout.empty?
    site_link = JSON.parse(strip_carriage_returns(cmd.stdout))
  else
    Chef::Log.debug("#{@current_resource} not found.")
  end

  if site_link
    @current_resource.name(site_link['Name'])
    @current_resource.guid = site_link['ObjectGUID']
    @current_resource.distinguished_name = site_link['DistinguishedName']
    @current_resource.exists = true
  end
end
