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
    converge_by("Create AD site #{@new_resource}") do
      # New-ADReplicationSite [-Name] <String> [-AuthType <ADAuthType> {Negotiate | Basic} ] [-AutomaticInterSiteTopologyGenerationEnabled <Boolean> ] [-AutomaticTopologyGenerationEnabled <Boolean> ] [-Credential <PSCredential> ] [-Description <String> ] [-Instance <ADReplicationSite> ] [-InterSiteTopologyGenerator <ADDirectoryServer> ] [-ManagedBy <ADPrincipal> ] [-OtherAttributes <Hashtable> ] [-PassThru] [-ProtectedFromAccidentalDeletion <Boolean> ] [-RedundantServerTopologyEnabled <Boolean> ] [-ReplicationSchedule <ActiveDirectorySchedule> ] [-ScheduleHashingEnabled <Boolean> ] [-Server <String> ] [-TopologyCleanupEnabled <Boolean> ] [-TopologyDetectStaleEnabled <Boolean> ] [-TopologyMinimumHopsEnabled <Boolean> ] [-UniversalGroupCachingEnabled <Boolean> ] [-UniversalGroupCachingRefreshSite <ADReplicationSite> ] [-WindowsServer2000BridgeheadSelectionMethodEnabled <Boolean> ] [-WindowsServer2000KCCISTGSelectionBehaviorEnabled <Boolean> ] [-WindowsServer2003KCCBehaviorEnabled <Boolean> ] [-WindowsServer2003KCCIgnoreScheduleEnabled <Boolean> ] [-WindowsServer2003KCCSiteLinkBridgingEnabled <Boolean> ] [-Confirm] [-WhatIf] [ <CommonParameters>]
      cmd_text = "New-ADReplicationSite #{@new_resource.name}"

      cmd = powershell_out(cmd_text)
      Chef::Log.debug("#{@new_resource} create site output: #{cmd.stdout}")
      if !cmd.stderr.empty?
        Chef::Log.error("Error creating new site: #{cmd.stderr}")
      else
        Chef::Log.info("#{@new_resource} created successfully.")
        new_resource.updated_by_last_action(true)
      end
    end
  end
end

action :rename do
  if !@current_resource.exists
    Chef::Log.error("#{@new_resource} doesn't exist.")
  elsif @current_resource.name == @new_resource.new_name
    Chef::Log.debug("#{@new_resource} already renamed.")
  else
    converge_by("Rename AD site #{@new_resource}") do
      # Rename-ADObject -Identity "CN=HQ,CN=Sites,CN=Configuration,DC=FABRIKAM,DC=COM" -NewName UnitedKingdomHQ
      cmd_text = "Rename-ADObject '#{@current_resource.distinguished_name}' -NewName '#{@new_resource.new_name}'"

      cmd = powershell_out(cmd_text)
      Chef::Log.debug("#{@new_resource} rename site output: #{cmd.stdout}")
      if !cmd.stderr.empty?
        Chef::Log.error("Error renaming site: #{cmd.stderr}")
      else
        Chef::Log.info("#{@new_resource} renamed successfully.")
        new_resource.updated_by_last_action(true)
      end
    end
  end
end

action :delete do
  if !@current_resource.exists
    Chef::Log.debug("#{@new_resource} doesn't exist.")
  else
    converge_by("Delete AD site #{@new_resource}") do
      # Remove-ADReplicationSite [-Identity] <ADReplicationSite> [-AuthType <ADAuthType> {Negotiate | Basic} ] [-Credential <PSCredential> ] [-Server <String> ] [-Confirm] [-WhatIf] [ <CommonParameters>]
      cmd_text = "Remove-ADReplicationSite '#{@current_resource.distinguished_name}' -Confirm:$false"

      cmd = powershell_out(cmd_text)
      Chef::Log.debug("#{@new_resource} delete site output: #{cmd.stdout}")
      if !cmd.stderr.empty?
        Chef::Log.error("Error deleting site: #{cmd.stderr}")
      else
        Chef::Log.info("#{@new_resource} deleted successfully.")
        new_resource.updated_by_last_action(true)
      end
    end
  end
end

def load_current_resource
  @current_resource = Chef::Resource::WindowsAdSite.new(@new_resource.name)
  @current_resource.exists = false

  cmd = powershell_out("Get-ADReplicationSite -Filter { Name -eq '#{@current_resource.name}' } | Select-Object Name, ObjectGUID, DistinguishedName | ConvertTo-Json")
  Chef::Log.debug("#{@new_resource} get site output: #{strip_carriage_returns(cmd.stdout)}")
  if !cmd.stderr.empty?
    Chef::Log.error("#{@current_resource} get site threw an error: #{strip_carriage_returns(cmd.stderr)}")
  elsif !cmd.stdout.empty?
    site = JSON.parse(strip_carriage_returns(cmd.stdout))
  else
    Chef::Log.debug("#{@current_resource} not found.")
  end

  if site
    @current_resource.name(site['Name'])
    @current_resource.guid = site['ObjectGUID']
    @current_resource.distinguished_name = site['DistinguishedName']
    @current_resource.exists = true
  end
end
