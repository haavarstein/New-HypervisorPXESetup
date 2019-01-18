# New-HypervisorPXESetup
Automated Installation of XenServer and ESXi through PXE
 boot.
This script will automatically download, configure & start FTP/TFTP services used to automatically install Citrix XenServer and VMware ESXi completly hands off through PXE boot.

The parameters Servername, Macaddress, IPAddress, Subnet and Gateway is the Hypervisor configuration.

The script can be editied directly or run as .\New-HypervisorPXESetup-v1.ps1 -Servername LOCALHOST

For any questions please reach me at @xenappblog on Twitter or visit my blog https://xenappblog.com
