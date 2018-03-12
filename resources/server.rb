property :creator, [true, false], default: true
property :ip_address, String, required: true
property :attach_storage, [true, false], default: false

action :create do
  if !new_resource.creator
    Chef::Log.fatal('The action to create the cluster and this node to not be the creator is illogical. Try creator true or action join')
  elsif clstr_exists?
    Chef::Log.info('The cluster already exsists no action taken.')
  else
    [
      'Failover-Clustering',
      'RSAT-Clustering',
      'RSAT-Clustering-CmdInterface',
    ].each do |feature|
      dsc_resource feature do
        resource :windowsfeature
        property :ensure, 'Present'
        property :name, feature
        reboot_action :reboot_now
      end
    end
    cmd = ''
    cmd << 'New-Cluster'
    cmd << " -Name #{new_resource.name}"
    cmd << ' -Node $env:COMPUTERNAME'
    cmd << " -StaticAddress #{new_resource.ip_address}"
    cmd << ' -NoStorage' unless new_resource.attach_storage
    cmd << ' -Force;'
    powershell_script "Create cluster #{new_resource.name}" do
      code cmd
    end
  end
end

action :join do
  if creator
    Chef::Log.fatal('The action to join the cluster and this node be the creator is illogical. Try creator false or action create')
  elsif node_exists?
    Chef::Log.info('The node is already a member of this cluster no action taken.')
  else
    [
      'Failover-Clustering',
      'RSAT-Clustering',
      'RSAT-Clustering-CmdInterface',
    ].each do |feature|
      dsc_resource feature do
        resource :windowsfeature
        property :ensure, 'Present'
        property :name, feature
        reboot_action :reboot_now
      end
    end
    cmd = ''
    cmd << 'Add-ClusterNode'
    cmd << ' -Name $env:COMPUTERNAME'
    cmd << " -Cluster #{new_resource.name}"
    cmd << ' -NoStorage' unless new_resource.attach_storage
    powershell_script "Add current node to cluster #{new_resource.name}" do
      code cmd
    end
  end
end

action_class do
  def clstr_exists?
    cmd = create_cmd
    cmd << '($cluster -ne $null)'
    check = Mixlib::ShellOut.new("powershell.exe -command \"& {#{cmd}}\"").run_command
    check.stdout.match('True')
  end

  def node_exists?
    cmd = create_cmd
    cmd << "$clusternodes = Get-ClusterNode -Cluster #{new_resource.name};"
    cmd << '($cluster -ne $null) -and ($clusternodes.Contains($env:COMPUTERNAME))'
    check = Mixlib::ShellOut.new("powershell.exe -command \"& {#{cmd}}\"").run_command
    check.stdout.match('True')
  end

  def create_cmd
    cmd = ''
    cmd << '$cluster = Get-Cluster'
    cmd << " -Name #{new_resource.name}"
    cmd << ' -Domain ((Get-WmiObject Win32_ComputerSystem).Domain);'
  end
end
