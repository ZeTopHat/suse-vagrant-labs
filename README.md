# suse-vagrant-labs
Vagrant labs for SUSE-based environments

### Lab Overview

<p class="callout info">The VM names will start with the name of the directory you were in when you ran `vagrant up` followed by an underscore and the short hostname of the machine. Example if I ran `vagrant up` in the base directory of the project `./suse-vagrant-labs/`: suse-vagrant-labs_basic15sp6, suse-vagrant-labs_basic15sp7</p>

The `custom.yaml` in the same directory as the `Vagrantfile` you are using will determine several default values including `cpus`, `memory`, `primarysubnet`, etc. In this case, using the default `custom.yaml` file we might see:

|Servers|OS|Specs|IP|User|Password|
|---|---|---|---|---|---|
|basic15sp7.labs.suse.com|15 SP7|1 vCPU, 2GB RAM, 42GB Disk|192.168.0.7|root|vagrant|
|basic15sp6.labs.suse.com|15 SP6|1 vCPU, 2GB RAM, 42GB Disk|192.168.0.8|root|vagrant|


#### Minimum Hypervisor Requirements:

<p class="callout info">This has been tested most recently with no issues on OpenSUSE Leap 15.6. If you have a different hypervisor OS, make sure you test the deployment of the lab. Different labs may have different requirements.</p>

- Hypervisor: KVM
- Processors: 4 (basic lab example)
- RAM: 8GB (basic lab example)
- Available Disk space: 60GB (basic lab example)
- Access to SCC, download.opensuse.org, github, and internal "rabble.suse.cloud" for vagrant boxes (config/global.yaml can be edited to point to your own locations).
- Packages installed in addition to KVM stack: `vagrant`, `vagrant-libvirt` (or install libvirt plugin), `git`
- A vagrant network will be created using a `192.168.0.*` range by default. (see `custom.yaml` `primarysubnet` value)

### Lab Deployment

#### Pre-requisites

1. KVM's virtqemud virtinterfaced virtnetworkd virtnodedevd virtsecretd virtstoraged services are enabled and running:
   
   ```
   chamilton2:~ # systemctl is-enabled virtqemud virtinterfaced virtnetworkd virtnodedevd virtsecretd virtstoraged
   enabled
   [...]
   enabled
   chamilton2:~ # systemctl is-active virtqemud virtinterfaced virtnetworkd virtnodedevd virtsecretd virtstoraged
   active
   [...]
   active
   ```
   
2. `git`, `vagrant`, and `vagrant-libvirt` packages are installed (in place of `vagrant-libvirt` you can install the plugin if available).
   
   ```
   chamilton2:~ # rpm -q git vagrant vagrant-libvirt
   git-2.35.3-150300.10.18.1.x86_64
   vagrant-2.2.18-bp153.2.1.x86_64
   vagrant-libvirt-0.5.3-bp153.2.1.x86_64
   ```
   
3. run `git clone https://github.com/ZeTopHat/suse-vagrant-labs.git` in order to pull the project
   
   ```
   chamilton2:~ # git clone https://github.com/ZeTopHat/suse-vagrant-labs.git
   Cloning into 'suse-vagrant-labs'...
   remote: Enumerating objects: 562, done.
   remote: Counting objects: 100% (87/87), done.
   remote: Compressing objects: 100% (76/76), done.
   remote: Total 562 (delta 17), reused 37 (delta 4), pack-reused 475
   Receiving objects: 100% (562/562), 16.66 MiB | 20.48 MiB/s, done.
   Resolving deltas: 100% (218/218), done.
   ```
   
4. Change directories into the project and set the `config/secret.yaml` with your registration codes. For the basic lab a standard registration code is needed for SLE and SL Micro in the `sleregcode` and `microregcode` variables. If you don't plan to use one of those, you can simply set the parameter to `foobar` or some other random value for the unused code to proceed with deploying your valid machines. Here's an example for the HA labs or basic labs without using the Micro machines:
   
   ```
   chamilton2:~ # cd suse-vagrant-labs
   chamilton2:~/suse-vagrant-labs # cp config/secret_example.yaml config/secret.yaml
   chamilton2:~/suse-vagrant-labs # vim config/secret.yaml
   chamilton2:~/suse-vagrant-labs # cat config/secret.yaml
   rcregcode: ""
   sleregcode: "REALCODE"
   microregcode: "foobar"
   haregcode: "REALCODE2"
   sapregcode: ""
   sumaregcode: ""
   sumaproxyregcode: ""
   livepatchregcode: ""
   sccorguser: ""
   sccorgpass: ""
   ```
   
5. If you want to use a different lab, either change directories to the authentication Vagrantfile or make a new symbolic link in the primary directory (make sure there is desired custom.yaml configurations):
   
   Option 1 (example auth lab):
   
   ```
   chamilton2:~/suse-vagrant-labs # cd vagrantfiles/auth/
   chamilton2:~/suse-vagrant-labs/vagrantfiles/auth # ls Vagrantfile
   Vagrantfile
   ```
   
   Option 2 (example auth lab):
   
   ```
   chamilton2:~/suse-vagrant-labs # unlink Vagrantfile
   chamilton2:~/suse-vagrant-labs # ln -s vagrantfiles/auth/Vagrantfile Vagrantfile
   chamilton2:~/suse-vagrant-labs # diff vagrantfiles/auth/custom.yaml custom.yaml
   ```
   
6. Some labs may have multiple deployment options. The basic lab does not. You would change the `custom.yaml` file of your current working directory (established by the previous step) so that the variable (auth lab example) `deployment` is set to `"training"` instead of `"fulldeploy"` to follow training rather than having a fully deployed set of auth machines:
   
   ```
   chamilton2:~/suse-vagrant-labs # vim custom.yaml
   chamilton2:~/suse-vagrant-labs # cat custom.yaml
   ---
   wheredir: "./"
   deployment: "training"
   extra: false
   libvirt:
     cpus: 1
     memory: 2048
     machine_virtual_size: 42
   network:
     bridgename: "br0"
     nameserver: "192.168.0.1"
     primarysubnet: "192.168.0"
     secondarysubnet: "192.168.1"
   ```

7. If you don't have a bridged network and want the labs that would normally use it to disable their use of it (e.g. the cluster labs such as ha15 or hana15) simply set the `bridgename` variable in the `custom.yaml` to a null value:

   ```
     bridgename: ""
   ```

8. Install `vagrant-reload` plugin (this is also where you could attempt to install the `vagrant-libvirt` plugin)

   ```
   chamilton2:~/suse-vagrant-labs # vagrant plugin install vagrant-reload
   ```

#### Inititate

Run the following command:

```bash
# vagrant up
```
