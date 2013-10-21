# 
# author    Brian Stoots
# email     bstoots@gmail.com
# date      2013-10-20
# summary   
#

# Define the parameters this script will accept and which if any are required
param (
  # -config specify the configuration XML file to use
  [string]$config = "config.xml",
  # -mode (install | uninstall)
  [string]$mode = $(throw "-mode is required."),
  # -validate-only flag
  [switch]$validate_only = $false
)

# Has to happen after param() apparently?
Import-Module .\modules\lib.psm1

# Well played Microsoft ... this is pretty hot
$xml = [xml](Get-Content $config)

# -validate_only takes precedence over other config options.  validateConfigXml always
# happens but if -validate_only is passed exit before doing anything else

# TODO - Validation needs to work for both install and uninstall.  Right now it can only
#        validate that things are sane for install
#validateConfigXml $xml
if ($validate_only -eq $true) {
  Exit 0
}

# Cheat and set a couple of widely used globals to make our life easier
setGlobalDevInstallPath((Split-Path $script:MyInvocation.MyCommand.Path) + "\installers")
setGlobalDevDestinationPath((getDevDestinationConfigFromXml $xml))

# Load all the config info from the XML file
$user_variables = getEnvironmentVariableConfigFromXml $xml "User"
$user_paths = getEnvironmentPathConfigFromXml $xml
$folders = getFolderConfigFromXml $xml
$installers = getInstallerConfigFromXml $xml

if ($mode -eq "install") {
  # TODO - Fix this, only validate on install for now
  validateConfigXml $xml
  # Install
  applyEnvironmentVariableConfig $user_variables
  applyEnvironmentPathConfig $user_paths
  applyFolderConfig $folders
  applyInstallerConfig $installers
}
elseif ($mode -eq "uninstall") {
  # Uninstall
  revertInstallerConfig $insallers
  revertFolderConfig $folders
  revertEnvironmentPathConfig $user_paths
  revertEnvironmentVariableConfig $user_variables
}
