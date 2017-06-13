# New-HypervisorPXESetup
Automated Installation of XenServer and ESXi through PXE

This script will automatically download, configure & start a FTP/TFTP service used to automatically install Citrix XenServer and VMware ESXi complete hands off through PXE boot. At the moment only XenServer works 100% because there's no public download URL for ESXi.

The parameters Servername, Macaddress, IPAddress, Subnet and Gateway is the configuration for the XenServer or ESXi Hypervisor.

The script can be editied directly or run .\New-HypervisorPXESetup-v1.ps1 -Servername LOCALHOST

For any questions please reach me at @xenappblog on Twitter or visit my blog https://xenappblog.com