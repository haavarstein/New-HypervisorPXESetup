# Set Params
Param(
  [string]$computerName,
  [string]$folder = "xenappblog",
  [string]$path = "$env:SystemDrive" + "\$folder",
  [string]$ftppath = "$path" + "\ftp",
  [string]$tftppath = "$path" + "\tftp",
  [string]$tftpconfig = "$tftppath" + "\Serva.ini",
  [string]$localip = (Get-NetIPAddress -PrefixOrigin Dhcp | Select-Object -ExpandProperty IPaddress),
  [string]$servername = "NUC-01",
  [string]$macaddress = "06-91-c9-1d-21-01",
  [string]$ipaddress = "192.168.2.200",
  [string]$subnet = "255.255.255.0",
  [string]$gateway = "192.168.2.1",
  [string]$xsver = "7.2",
  [string]$esxver = "6.5",
  [string]$configLocation = "C:\TFTP\TFTP\pxelinux.cfg\config.csv",
  [string]$pxeConfig = "$tftppath" + "\pxelinux.cfg\default",
  [string]$pxeConfigLocation = "$tftppath" + "\pxelinux.cfg\",
  [string]$xmlTemplate = "$ftppath" + "\xenserver\config\staticip.xml",
  [string]$xmlLocation = "$ftppath" + "\xenserver\config\",
  [string]$ksTemplate = "$ftppath" + "\esxi\config\ks.cfg",
  [string]$kslocation = "$ftppath" + "\esxi\config\",
  [string]$bootcfg = "$ftppath" + "\esxi" + "\$esxver\BOOT.CFG"

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
New-Item $path\ftp\esxi\$esxver -type directory -Force | Out-Null

# Download Latest XenServer ISO Image
$url = "https://downloads.citrix.com/12613/XenServer-$xsver.0-install-cd.iso?__gda__=1496024608_351c83940a40af689aa4275cb3e65a3d"
$output = "$path" + "\XenServer-$xsver.iso"
Invoke-WebRequest -Uri $url -OutFile $output

# Copy The XenServer Content Of The ISO Image
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
$url = "https://download2.vmware.com/software/esx/65/VMware-VMvisor-Installer-201701001-4887370.x86_64.iso?HashKey=af8ed9955fc71b6e07e605cd0f1451c9&params=%7B%22custnumber%22%3A%22cHRoZXAlaGRodA%3D%3D%22%2C%22sourcefilesize%22%3A%22328.26+MB%22%2C%22dlgcode%22%3A%22ESXI650A%22%2C%22evaldlgcode%22%3A%22EVAL-FREE-ESXI6-EN-2084%22%2C%22languagecode%22%3A%22en%22%2C%22source%22%3A%22EVALS%22%2C%22downloadtype%22%3A%22manual%22%2C%22downloaduuid%22%3A%2267b5a253-e4f7-404e-8c90-79f9c4bbeafc%22%7D&AuthKey=1496007727_8002110980c58b0f83fceb74d8a18cf0"
$output = "$path" + "\ESXi-$esxver.iso"
Invoke-WebRequest -Uri $url -OutFile $output

# Copy The ESXi Content Of The ISO Image
$mountResult = Mount-DiskImage $output -PassThru
$ISODrive = (Get-DiskImage -ImagePath $output | Get-Volume).DriveLetter
$ISODriveLetter = "$ISODrive" + ":\"
cd $ISODriveLetter
copy-item -Recurse * -Destination "$path\ftp\esxi\$esxver\" -Force
Dismount-DiskImage $output

# Downlaod FTP/TFTP Program
$urltftp = "http://www.vercot.com/~serva/download/Serva_Community_64_v3.0.0.zip"
$outputtftp = "$path" + "\tftp\Serva.zip"
Invoke-WebRequest -Uri $urltftp -OutFile $outputtftp
$shell = new-object -com shell.application
$zip = $shell.NameSpace("$path\tftp\Serva.zip”)
foreach($item in $zip.items())
{
$shell.Namespace("$path\tftp”).copyhere($item)
}

# Download Custom Configuration
Invoke-WebRequest -Uri https://xenappblog.s3.amazonaws.com/download/autohv/Serva.ini -OutFile $tftppath\Serva.ini
Invoke-WebRequest -Uri https://xenappblog.s3.amazonaws.com/download/autohv/staticip.xml -OutFile $xmlTemplate
Invoke-WebRequest -Uri https://xenappblog.s3.amazonaws.com/download/autohv/ks.cfg -OutFile $ksTemplate
Invoke-WebRequest -Uri https://xenappblog.s3.amazonaws.com/download/autohv/default -OutFile $tftppath\pxelinux.cfg\default

# Creating XML for XenServer Unattended Installation
$default = Get-Content $pxeConfig
$default.replace("mdt-01.ctxlab.local", $localip) | Out-File ($pxeConfig)
$default = Get-Content $pxeConfig
$default.replace("version", $esxver) | Out-File ($pxeConfig)
$default = Get-Content $pxeConfig
$default.replace("unattend", $servername) | Out-File ($pxeConfigLocation + "01-" + $macaddress)
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
(Get-Content "$bootcfg") `
    -Replace("/", "/esxi/$esxver/") |
Out-File "$path\BOOT.CFG"
Rename-Item $bootcfg BOOT.OLD
Copy-Item $path\BOOT.CFG -Destination $path\ftp\esxi\$esxver
remove-item $path\BOOT.CFG

$default = Get-Content $kstemplate
$default.replace("localhost", $servername) | Out-File $kstemplate
$default = Get-Content $kstemplate
$default.replace("0.0.0.0", $ipaddress) | Out-File $kstemplate
$default = Get-Content $kstemplate
$default.replace("255.255.255.0", $subnet) | Out-File $kstemplate
$default = Get-Content $kstemplate
$default.replace("192.168.1.1", $gateway) | Out-File $kstemplate
copy-item $kstemplate -Destination $kslocation\$servername.cfg

# FTP/TFTP Configuration with Local IP Address
$default = Get-Content $tftpconfig
$default.replace("0.0.0.0", $localip) | Out-File ($tftpconfig)
$default = Get-Content $tftpconfig
$default.replace("C:\xenappblog", $path) | Out-File ($tftpconfig)

# Start FTP/TFTP Program
# Start-Process $tftppath\Serva64.exe
