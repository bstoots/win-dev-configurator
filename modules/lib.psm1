# 
# author    Brian Stoots
# email     bstoots@gmail.com
# date      2013-10-20
# summary   The purpose of this module is to handle validation, parsing, and setting
#           configuration settings as defined in a specified XML file.
#

# TODO - Change this to relative to this script's path
Import-Module .\modules\environment.psm1

#
#
#
Function validateConfigXml ($xml) {
  # Check that <DevDestination> is defined and doesn't already exist
  if ($xml.config.devdestination -eq $null -or (Test-Path $xml.config.devdestination) -eq $true) {
    Throw "DevDestination must be defined and cannot already exist: " + $xml.config.devdestination
  }
  # Check all of the Environment values
  foreach ($variable in $xml.config.environment.variables.variable) {
    #
    if ($variable.location -eq "User" -and (userEnvironmentVariableExists $variable.name) -eq $true) {
      Throw "User variable: " + $variable.name + ", already exists"
    }
    #
    elseif ($variable.location -eq "System" -and (systemEnvironmentVariableExists $variable.name) -eq $true) {
      Throw "System variable: " + $variable.name + ", already exists"
    }
  }
  # Check that Path entries don't already exist
  foreach ($path in $xml.config.environment.path.variable) {
    if ((userEnvironmentPathExists (expandRelativePath $path ($xml.config.devdestination))) -eq $true) {
      Throw "Path entry: " + (expandRelativePath $path ($xml.config.devdestination)) + ", already exists"
    }
  }
  # Check all of the Folder values
  foreach ($folder in $xml.config.folders.folder) {
    if ((Test-Path (expandRelativePath $folder $xml.config.rootdestination)) -eq $true) {
      Throw "Folder: " + (expandRelativePath $folder ($xml.config.devdestination)) + ", already exists"
    }
  }
}
# Public
Export-ModuleMember validateConfigXml

#
# Sets a script global that contains the full path of the config\installers
# directory.  This is used to construct full path constructs from relatives.
#
# @param string $dev_install_path Path to the installers\ directory by default this
#                                 is the script's working dir + \installers
# @return void
#
Function setGlobalDevInstallPath([string]$dev_install_path) {
  $global:dev_install_path = $dev_install_path
}
# Public
Export-ModuleMember setGlobalDevInstallPath

#
# Gets the value of the global containing the dev_install_path.  This will be the location
# of all the installers\ needed to deploy the dev environment
#
# @param void
# @return string
#
Function getGlobalDevInstallPath() {
  return $global:dev_install_path
}
# Public
Export-ModuleMember getGlobalDevInstallPath

#
# Sets a script global that contains the full path of the dev destination directory
# this will almost always be the same as what getDevDestinationConfigFromXml() returns
#
# @param string $dev_destination_path Path to the dev destination directory
# @return void
#
Function setGlobalDevDestinationPath([string]$dev_destination_path) {
  $global:dev_destination_path = $dev_destination_path
}
# Public
Export-ModuleMember setGlobalDevDestinationPath

#
# Gets the value of the global containing the dev_destination_path.  This will be the 
# destination location that installers are deployed to
#
# @param void
# @return string
#
Function getGlobalDevDestinationPath() {
  return $global:dev_destination_path
}
# Public
Export-ModuleMember getGlobalDevDestinationPath

#
# Extracts the <DevDestination> element value from the config XML
#
# This directory is the basedir into which all dev utils will be installed
#
# @param xml $xml Full XML element object of the config file
# @return value of <DevDestination>
#
Function getDevDestinationConfigFromXml($xml) {
  return $xml.config.devdestination
}
# Public
Export-ModuleMember getDevDestinationConfigFromXml

#
# Gets a list of environment variables for a given location (User|System) from the config XML
#
Function getEnvironmentVariableConfigFromXml($xml, $location = "Both") {
  $variables = @()
  # If there's not <Environment> element at all just return $null
  if ($xml.config.environment -eq $null) {
    return $variables
  }
  # If <Variables> exists and has child elements then loop on it
  if ($xml.config.environment.variables -ne $null -and `
      $xml.config.environment.item("Variables").haschildnodes `
  ) {
    foreach ($variable in $xml.config.environment.variables.variable) {
      # If $location is User only process the User variables
      if ($location -eq "User") {
        Write-Output "User"
        $variables += $variable
      }
      # If $location is System only process the System variables
      elseif ($location -eq "System") {
        Write-Output "System"
        $variables += $variable
      }
      # If $location is Both get User and System variables
      elseif ($location -eq "Both") {
        Write-Output "Both"
        $variables += $variable
      }
    }
  }
  return $variables
}
# Public
Export-ModuleMember getEnvironmentVariableConfigFromXml

#
#
# @param array $variables
#
Function applyEnvironmentVariableConfig($variables) {
  #
  if ($variables.count -eq 0) {
    return
  }
  foreach ($variable in $variables) {
    # First figure out the Type and modify the value accordingly
    # Type is Path means we want to make it relative to the <DevDestination>
    if ($variable.type -eq "Path") {
      $var_value = (expandRelativePath $variable.'#text' (getGlobalDevDestinationPath))
    }
    # Type is Constant means just store whatever is in the config to the Environment
    elseif ($variable.type -eq "Constant") {
      $var_value = $variable.'#text'
    }
    # These are the only defined Types at the moment, throw if it's not known
    else {
      # Throw
    }
    
    # Now, get on with actually storing the values in the Env variables
    # If $location is User store to User variable
    if ($variable.location -eq "User") {
      setUserEnvironmentVariable $variable.name $var_value
    }
    # If $location is System store to System variable
    elseif ($variable.location -eq "System") {
      setSystemEnvironmentVariable $variable.name $var_value
    }
  }
}
# Public
Export-ModuleMember applyEnvironmentVariableConfig

#
#
# @param array $variables
#
Function revertEnvironmentVariableConfig($variables) {
  #
  if ($variables.count -eq 0) {
    return
  }
  foreach ($variable in $variables) {
    # If $location is User trash a User variable
    if ($variable.location -eq "User") {
      deleteUserEnvironmentVariable $variable.name
    }
    # If $location is System trash a System variable
    elseif ($variable.location -eq "System") {
      deleteSystemEnvironmentVariable $variable.name
    }
  }
}
# Public
Export-ModuleMember revertEnvironmentVariableConfig

#
#
#
Function getEnvironmentPathConfigFromXml ($xml) {
  $paths = @()
  if ($xml.config.environment -eq $null) {
    return $paths
  }
  #
  if ($xml.config.environment.path -ne $null -and `
      $xml.config.environment.item("Path").haschildnodes `
  ) {
    foreach ($path in $xml.config.environment.path.variable) {
      $paths += $path
    }
  }
  return $paths
}
# Public
Export-ModuleMember getEnvironmentPathConfigFromXml

#
#
#
Function applyEnvironmentPathConfig ($paths) {
  #
  if ($paths.count -eq 0) {
    return
  }
  foreach ($path in $paths) {
    addUserEnvironmentPath (expandRelativePath $path (getGlobalDevDestinationPath))
  }
}
# Public
Export-ModuleMember applyEnvironmentPathConfig

#
#
#
Function revertEnvironmentPathConfig ($paths) {
  #
  if ($paths.count -eq 0) {
    return
  }
  foreach ($path in $paths) {
    deleteUserEnvironmentPath (expandRelativePath $path (getGlobalDevDestinationPath))
  }
}
# Public
Export-ModuleMember revertEnvironmentPathConfig

#
#
#
Function getFolderConfigFromXml ($xml) {
  # At the very least we'll need to create the RootDestination directory
  $folders = @()
  $folders += (getGlobalDevDestinationPath)
  #
  if ($xml.config.folders -ne $null -and `
      $xml.config.item("Folders").haschildnodes `
  ) {
    foreach ($folder in $xml.config.folders.folder) {
      # Add folder to the array
      $folders += (expandRelativePath $folder (getGlobalDevDestinationPath))
    }
  }
  return $folders
}
# Public
Export-ModuleMember getFolderConfigFromXml

#
#
#
Function applyFolderConfig ($folders) {
  if ($folders.count -eq 0) {
    return
  }
  foreach ($folder in $folders) {
    # Make the folders
    md ($folder) | Out-Null
  }
}
# Public
Export-ModuleMember applyFolderConfig

#
#
#
Function revertFolderConfig ($folders) {
  # Hrm ... what should this do?
  # Automating this probably isn't a good idea
  # Remove-Item -Recurse -Force some_dir
}
# Public
Export-ModuleMember revertFolderConfig

#
#
#
Function getInstallerConfigFromXml ($xml) {
  $installers = @()
  #
  if ($xml.config.folders -ne $null -and `
      $xml.config.item("Folders").haschildnodes `
  ) {
    foreach ($installer in $xml.config.installers.installer) {
      $installers += $installer
    }
  }
  return $installers
}
# Public
Export-ModuleMember getInstallerConfigFromXml

#
#
#
Function applyInstallerConfig ($installers) {
  if ($installers.count -eq 0) {
    return
  }
  foreach ($installer in $installers) {
    # Check the type to determine how this installation needs to happen
    # Folder just copies a specified folder to the dev environment
    if ($installer.type -eq "Folder") {
      $source = (expandRelativePath $installer.source (getGlobalDevInstallPath))
      $destination = (expandRelativePath $installer.destination (getGlobalDevDestinationPath))
      installFolder $source $destination
    }
    # Zip
    elseif ($installer.type -eq "Zip") {
      $source = (expandRelativePath $installer.source (getGlobalDevInstallPath))
      $destination = (expandRelativePath $installer.destination (getGlobalDevDestinationPath))
      # For zip files we may want to extract some arbitrary file / folder
      # from inside so split and directory suffix off the zip file path
      if ($source -match "(.+\.zip)(.*)") {
        if ($Matches[1] -ne $null) {
          $source = $Matches[1]
        }
        if ($Matches[2] -ne $null) {
          $inner_source = $Matches[2]
        }
        else {
          $inner_source = $null
        }
      }
      else {
        # This probably isn't a valid zip file ... wtf
      }
      installZip $source $inner_source $destination
    }
    # Binary
    elseif ($installer.type -eq "Binary") {
      $source = (expandRelativePath $installer.source (getGlobalDevInstallPath))
      # Destination is optional for Binary installers
      if ($installer.destination -ne $null) {
        $destination = (expandRelativePath $installer.destination (getGlobalDevDestinationPath))
      }
      else {
        $destination = $null
      }
      installBinary $source $destination
    }
  }
}
# Public
Export-ModuleMember applyInstallerConfig

#
#
#
Function revertInstallerConfig ($installers) {
  # Run registered uninstallers, remove files, etc
}
# Public
Export-ModuleMember revertInstallerConfig

#
# TODO - Refactor these into their own modules
#
Function installFolder([string]$source, [string]$destination) {
  if ((Test-Path $source) -eq $false) {
    Throw "installFolder could not find source path: " + $source
  }
  if ((Test-Path $destination) -eq $true) {
    Throw "installFolder destination path already exists: " + $destination
  }
  # Create the destination directory first so we can get arbitrary depths in one command
  New-Item -path $destination -type directory | Out-Null
  Copy-Item $($source + "*") $destination -recurse
}

#
# TODO - Refactor these into their own modules
#
Function installZip([string]$source, [string]$inner_source, [string]$destination) {
  if ((Test-Path $source) -eq $false) {
    Throw "installZip could not find source zip file: " + $source
  }
  if ((Test-Path $destination) -eq $true) {
    Throw "installZip destination path already exists: " + $destination
  }
  # Create the destination directory first so we can get arbitrary depths in one command
  New-Item -path $destination -type directory | Out-Null
  #Copy-Item $($source + "*") $destination -recurse
  unzip $source $destination $inner_source
}

#
# TODO - Refactor these into their own modules
#
Function installBinary($binary_path, $destination) {
  if ($destination -ne $null) {
    if ((Test-Path $destination) -eq $true) {
      Throw "installBinary destination path already exists: " + $destination
    }
    New-Item -path $destination -type directory | Out-Null
  }
  
  $list = 
  @(
      "/I `"$msi`"",                     # Install this MSI
      "/QN",                             # Quietly, without a UI
      "/L*V `"$ENV:TEMP\$name.log`""     # Verbose output to this log
  )

  $p = Start-Process -FilePath $binary_path -ArgumentList $list -Wait
  if($p.ExitCode -ne 0) {
    #Throw "Installation process returned error code: $($p.ExitCode)"
  }
}

#
# Utility methods that should go somewhere else at some point
#

#
# If $path is relative this function will expand it out into the full path by
# appending it to $prefix.  If the given $path isn't relative it will be returned
# intact.  Also handles short-hand ".\" meaning $prefix
#
# @param string $path
# @param string $prefix
# @return string
#
Function expandRelativePath([string]$path, [string]$prefix) {
  # If the passed path wasn't relative then just return it intact
  if ($path -match "^.+:\\|^\\.+") {
    return $path
  }
  # If $path is \ that means the same as prefix
  elseif ($path -eq ".\") {
    return $prefix
  }
  else {
    # Little helper to make sure the trailing \ is set on prefix if it was passed but
    # not when $path is empty which signifies the root path
    if ($prefix -notmatch "\\$") {
      $prefix += "\"
    }
    return $prefix + $path
  }
}

#
#
#
Function unzip($zip_path, $destination, $inner_path = "") {
  if ((Test-Path $zip_path) -ne $true) {
    Throw $("Failed to unzip: " + $zip_path)
  }
  if ((Test-Path $destination) -ne $true) {
    Throw $("Failed to unzip files into: " + $destination)
  }
  $shell_app = New-Object -com shell.application
  $zip = $shell_app.namespace($($zip_path + $inner_path))
  $destination = $shell_app.namespace($destination)
  $destination.Copyhere($zip.items(), 0x14)
}