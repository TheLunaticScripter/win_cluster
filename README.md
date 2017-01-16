# win_cluster
Windows Failover Clustering Cookbook
===========================

Requirements
------------
#### Platforms
* Windows Server 2012 (R1, R2)

#### Chef
* Chef 12+

Usage
-----
This is a Custom Resource cookbook that can be used to install and configure Windows Failover Cluster in Active Directory.

Custom Resources
----------------
### win_cluster_server
Installs Windows Failover-Clustering Features and creates a new Cluster

#### Actions
- 'create' - Creates A new Cluster if it doesn't exisit in AD
- 'join' - Join a Cluster that has already been created

#### Properties
- 'name - Name of the cluster to be created
- 'creator' - Boolean whether the specified node is the creator of the cluster.
- 'ip_address' - IP address of the new cluster
- 'attach_storage' - Boolean whether or not to have include attached storage as part of the cluster or not

#### Examples
Create new 'SQLClst' with an ip of 192.168.1.1

```
win_cluster_server 'SQLClst' do
  ip_address '192.168.1.1'
end
```

Join cluster 'SQLClst'

```
win_cluster_server 'SQLClst' do
  action :join
  creator false
end
```

License & Author
----------------
- Author:: John Snow (thelunaticscripter@outlook.com)

```text
Copyright 2016, TheLunaticScripter.com

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License
