property :name, name_attribute: true, kind_of: String, required: true
property :creator, kind_of: [TrueClass, FalseClass], default: true
property :ip_address, kind_of: String, required: true
property :attach_storage, kind_of: [TrueClass, FalseClass], default: false

default_action :create

def whyrun_supported?
  true
end

def load_current_resource
  @current_resource = Chef::Resource::WinClusterServer.new(@new_resource.name)
end

action :create do
  if !creator
    Chef::Log.fatal('The action to create the cluster and this node to not be the creator is illogical. Try creator true or action join')
  else
    if clstr_exists?
      @new_resource.updated_by_last_action(false)
    else
      [
        'Failover-Clustering',
        'RSAT-Clustering',
        'RSAT-Clustering-CmdInterface'
      ].each do |feature|
        dsc_resource "#{feature}" do
          resource :windowsfeature
          property :ensure, 'Present'
          property :name, feature
          reboot_action :reboot_now
        end
      end
      cmd = ''
      cmd << 'New-Cluster'
      cmd << " -Name #{name}"
      cmd << ' -Node $env:COMPUTERNAME'
      cmd << " -StaticAddress #{ip_address}"
      cmd << ' -NoStorage' if !attach_storage
      cmd << ' -Force;'
      powershell_script "Create cluster #{name}" do
        code cmd
      end
    end
  end
end

action :join do
  if creator
    Chef::Log.fatal('The action to join the cluster and this node be the creator is illogical. Try creator false or action create')
  else
    if node_exists?
      @new_resource.updated_by_last_action(false)
    else
      [
        'Failover-Clustering',
        'RSAT-Clustering',
        'RSAT-Clustering-CmdInterface'
      ].each do |feature|
        dsc_resource "#{feature}" do
          resource :windowsfeature
          property :ensure, 'Present'
          property :name, feature
          reboot_action :reboot_now
        end
      end
      cmd = ''
      cmd << 'Add-ClusterNode'
      cmd << ' -Name $env:COMPUTERNAME'
      cmd << " -Cluster #{name}"
      cmd << ' -NoStorage' if !attach_storage
      powershell_script "Add current node to cluster #{name}" do
        code cmd
      end
    end
  end
end

def clstr_exists?
  cmd = create_cmd
  cmd << "($cluster -ne $null)"
  check = Mixlib::ShellOut.new("powershell.exe -command \"& {#{cmd}}\"").run_command
  check.stdout.match('True')
end

def node_exists?
  cmd = create_cmd
  cmd << "$clusternodes = Get-ClusterNode -Cluster #{name};"
  cmd << "($cluster -ne $null) -and ($clusternodes.Contains($env:COMPUTERNAME))"
  check = Mixlib::ShellOut.new("powershell.exe -command \"& {#{cmd}}\"").run_command
  check.stdout.match('True')
end

def create_cmd
  cmd = ''
  cmd << "$cluster = Get-Cluster"
  cmd << " -Name #{name}"
  cmd << " -Domain ((Get-WmiObject Win32_ComputerSystem).Domain);"
end
