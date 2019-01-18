# Set Params
Param(
  [string]$servername = "NUC01",
  [string]$macaddress = "00-50-56-1d-21-01",
  [string]$ipaddress = "192.168.1.230",
  [string]$subnet = "255.255.255.0",
  [string]$gateway = "192.168.1.1",
  [string]$xsver = "7.6",
  [string]$esxver = "6.7U1",
  [string]$folder = "xenappblog",
  [string]$path = "$env:SystemDrive" + "\$folder",
  [string]$ftppath = "$path" + "\ftp",
  [string]$tftppath = "$path" + "\tftp",
  [string]$tftpconfig = "$tftppath" + "\Serva.ini",
  [string]$localip = (Get-NetIPAddress -PrefixOrigin Dhcp | Select-Object -ExpandProperty IPaddress),
  [string]$pxeConfig = "$tftppath" + "\pxelinux.cfg\default",
  [string]$pxeConfigLocation = "$tftppath" + "\pxelinux.cfg\",
  [string]$xmlTemplate = "$ftppath" + "\xenserver\config\staticip.xml",
  [string]$xmlLocation = "$ftppath" + "\xenserver\config\",
  [string]$ksTemplate = "$ftppath" + "\esxi\config\ks.cfg",
  [string]$kslocation = "$ftppath" + "\esxi\config\",
  [string]$bootcfg = "$tftppath" + "\esxi" + "\$esxver\BOOT.CFG"

  )

# Create Folder Structure
New-Item $path -type directory -Force | Out-Null
New-Item $path\tftp -type directory -Force | Out-Null
New-Item $path\tftp\xenserver -type directory -Force | Out-Null
New-Item $path\tftp\pxelinux.cfg -type directory -Force | Out-Null
New-Item $path\ftp -type directory -Force | Out-Null
New-Item $path\ftp\xenserver -type directory -Force | Out-Null
New-Item $path\ftp\esxi -type directory -Force | Out-Null
New-Item $path\ftp\xenserver\config -type directory -Force | Out-Null
New-Item $path\ftp\esxi\config -type directory -Force | Out-Null
New-Item $path\ftp\xenserver\scripts -type directory -Force | Out-Null
New-Item $path\ftp\xenserver\spack -type directory -Force | Out-Null
New-Item $path\ftp\xenserver\$xsver -type directory -Force | Out-Null

# Download Latest XenServer ISO Image
$ProgressPreference = 'SilentlyContinue'
$url = "http://xenapptraining.s3.amazonaws.com/ISO/XenServer-7.6.0-install-cd.iso"
$output = "$path" + "\XenServer-$xsver.iso"
Write-Verbose "Downloading Citrix Hypervisor $xsver" -Verbose
Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $output

# Copy The XenServer Content Of The ISO Image
Write-Verbose "Copying the content of Citrix Hypervisor $xsver ISO" -Verbose
$mountResult = Mount-DiskImage $output -PassThru
$ISODrive = (Get-DiskImage -ImagePath $output | Get-Volume).DriveLetter
$ISODriveLetter = "$ISODrive" + ":\"
cd $ISODriveLetter
copy-item -Recurse * -Destination "$path\ftp\xenserver\$xsver\" -Force
copy-item install.img -Destination "$path\tftp\xenserver\" -Force
cd boot
copy-item xen.gz -Destination "$path\tftp\xenserver\" -Force
copy-item vmlinuz -Destination "$path\tftp\xenserver\" -Force
cd pxelinux
copy-item -Recurse * -Destination "$path\tftp\" -Force
Dismount-DiskImage $output

# Download Latest ESXi ISO Image
$url = "http://xenapptraining.s3.amazonaws.com/ISO/VMware-VMvisor-Installer-6.7.0.update01-10302608.x86_64.iso"
$output = "$path" + "\ESXi-$esxver.iso"
Write-Verbose "Downloading VMware ESXi $esxver" -Verbose
Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $output

# Copy The ESXi Content Of The ISO Image
Write-Verbose "Copying the content of VMware ESXi $esxver ISO" -Verbose
$mountResult = Mount-DiskImage $output -PassThru
$ISODrive = (Get-DiskImage -ImagePath $output | Get-Volume).DriveLetter
$ISODriveLetter = "$ISODrive" + ":\"
cd $ISODriveLetter
xcopy *.* "$path\tftp\esxi\$esxver\" /y /e /q
Dismount-DiskImage $output

# Downlaod FTP/TFTP Program
$urltftp = "http://www.vercot.com/~serva/download/Serva_Community_64_v3.0.0.zip"
$outputtftp = "$path" + "\tftp\Serva.zip"
Invoke-WebRequest -UseBasicParsing -Uri $urltftp -OutFile $outputtftp
$shell = new-object -com shell.application
$zip = $shell.NameSpace("$path\tftp\Serva.zip”)
foreach($item in $zip.items())
{
$shell.Namespace("$path\tftp”).copyhere($item)
}

# Download Custom Configuration
Invoke-WebRequest -UseBasicParsing -Uri https://xenappblog.s3.amazonaws.com/download/autohv/Serva.ini -OutFile $tftpconfig
Invoke-WebRequest -UseBasicParsing -Uri https://xenappblog.s3.amazonaws.com/download/autohv/staticip.xml -OutFile $xmlTemplate
Invoke-WebRequest -UseBasicParsing -Uri https://xenappblog.s3.amazonaws.com/download/autohv/ks.cfg -OutFile $ksTemplate
# Invoke-WebRequest -UseBasicParsing -Uri https://xenappblog.s3.amazonaws.com/download/autohv/default -OutFile $pxeConfig

Write-Verbose "Creating PXE Configuration File" -Verbose
$Text += "default menu.c32" + "`n"
$Text += "prompt 0" + "`n"
$Text += "timeout 180" + "`n"
$Text += "ONTIMEOUT bootlocal" + "`n"
$Text += "" + "`n"
$Text += "menu title Automation Framework Master Class" + "`n"
$Text += "" + "`n"                                    
$Text += "label bootlocal" + "`n"
$Text += "menu label Boot Local OS" + "`n"
$Text += "localboot 0" + "`n"
$Text += "" + "`n"
$Text += "label xenserver" + "`n"
$Text += "menu label Install Citrix Hypervisor $xsver" + "`n"
$Text += "kernel mboot.c32" + "`n"
$Text += "append xenserver/xen.gz dom0_max_vcpus=2 dom0_mem=1024M,max:1024M com1=115200,8n1 console=com1,vga --- xenserver/vmlinuz xencons=hvc console=hvc0 console=tty0 answerfile=ftp://$localip/xenserver/config/$servername.xml install --- xenserver/install.img" + "`n"
$Text += "" + "`n"
$Text += "label esxi" + "`n"
$Text += "menu label Install VMware ESXi $esxver" + "`n"
$Text += "kernel /esxi/$esxver/mboot.c32" + "`n"
$Text += "append -c /esxi/$esxver/boot.cfg ks=ftp://$localip/esxi/config/$servername.cfg" + "`n"

Set-Content $pxeConfig -value ($Text) -Encoding ASCII

$default = Get-Content $xmlTemplate
$default.replace("mdt-01.ctxlab.local", $localip) | Out-File ($xmlTemplate)
$default = Get-Content $xmlTemplate
$default.replace("VERSION", $xsver) | Out-File ($xmlTemplate)
$xml = [xml](Get-Content $xmlTemplate)
$xml.installation.hostname = $servername
$xml.installation.'admin-interface'.ip = $ipaddress
$xml.installation.'admin-interface'.'subnet-mask' = $subnet
$xml.installation.'admin-interface'.gateway = $gateway
$xml.Save($xmlLocation + "\" + $servername + ".xml")


# Customize ESXi Boot File
((Get-Content $bootcfg) -join "`n") + "`n" | Set-Content $bootcfg
((Get-Content $bootcfg) -Replace "/", "/esxi/$esxver/") | Set-Content $bootcfg

$default = Get-Content $kstemplate
$default.replace("localhost", $servername) | Out-File $kstemplate -Encoding ASCII
$default = Get-Content $kstemplate
$default.replace("0.0.0.0", $ipaddress) | Out-File $kstemplate -Encoding ASCII
$default = Get-Content $kstemplate
$default.replace("255.255.255.0", $subnet) | Out-File $kstemplate -Encoding ASCII
$default = Get-Content $kstemplate
$default.replace("192.168.1.1", $gateway) | Out-File $kstemplate -Encoding ASCII
copy-item $kstemplate -Destination $kslocation\$servername.cfg

# FTP/TFTP Configuration with Local IP Address
$default = Get-Content $tftpconfig
$default.replace("0.0.0.0", $localip) | Out-File ($tftpconfig) -Encoding ASCII
$default = Get-Content $tftpconfig
$default.replace("C:\xenappblog", $path) | Out-File ($tftpconfig) -Encoding ASCII

# Start FTP/TFTP Program
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
Start-Process $tftppath\Serva64.exe
