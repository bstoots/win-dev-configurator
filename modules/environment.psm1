# 
# author    Brian Stoots
# email     bstoots@gmail.com
# date      2013-10-20
# summary   The purpose of this module is to handle validation, parsing, and setting
#           configuration settings as defined in a specified XML file.
#

#
#
#
Function setUserEnvironmentVariable($key, $value) {
  [Environment]::SetEnvironmentVariable($key, $value, "User")
}
# Public
Export-ModuleMember setUserEnvironmentVariable

#
#
#
Function getUserEnvironmentVariable($key) {
  [Environment]::GetEnvironmentVariable($key, "User")
}
# Public
Export-ModuleMember getUserEnvironmentVariable

#
#
#
Function userEnvironmentVariableExists($key) {
  if ((getUserEnvironmentVariable $key)) {
    return $true
  }
  else {
    return $false
  }
}
# Public
Export-ModuleMember userEnvironmentVariableExists

#
#
#
Function deleteUserEnvironmentVariable($key) {
  setUserEnvironmentVariable $key $null
}
# Public
Export-ModuleMember deleteUserEnvironmentVariable

#
#
#
Function setSystemEnvironmentVariable($key, $value) {
  [Environment]::SetEnvironmentVariable($key, $value, "System")
}
# Public
Export-ModuleMember setSystemEnvironmentVariable

#
#
#
Function getSystemEnvironmentVariable($key) {
  [Environment]::GetEnvironmentVariable($key, "System")
}
# Public
Export-ModuleMember getSystemEnvironmentVariable

#
#
#
Function systemEnvironmentVariableExists($key) {
  if ((getSystemEnvironmentVariable $key)) {
    return $true
  }
  else {
    return $false
  }
}
# Public
Export-ModuleMember systemEnvironmentVariableExists

#
#
#
Function deleteSystemEnvironmentVariable($key) {
  setSystemEnvironmentVariable $key $null
}
# Public
Export-ModuleMember deleteSystemEnvironmentVariable

#
#
#
Function addUserEnvironmentPath($value) {
  # Before adding to the path, make sure the value doesn't already exist
  if ((userEnvironmentPathExists $value) -eq $true) {
    return
  }
  # Not found so add it
  else {
    # Add the semicolon if need be
    (appendSemicolonToUserEnvironmentPath)
    $path = (getUserEnvironmentPath)
    $path += $value
    Set-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Environment' -Name PATH -Value $path
  }
}
# Public
Export-ModuleMember addUserEnvironmentPath

#
#
#
Function getUserEnvironmentPath() {
  return (Get-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Environment' -Name PATH).Path
}
# Public
Export-ModuleMember getUserEnvironmentPath

#
#
#
Function userEnvironmentPathExists($value) {
  $path = (getUserEnvironmentPath)
  # This regex is designed to hit on either semicolons or string beginning or endings
  # The goal here is to make sure we aren't partially matching on path values
  $regex = $("(\A|;)(" + ([regex]::escape($value)) + ")(\Z|;)")
  if ($path -match $regex) {
    return $true
  }
  else {
    return $false
  }
}
# Public
Export-ModuleMember userEnvironmentPathExists

#
#
#
Function deleteUserEnvironmentPath($value) {
  # Before deleting from the path, make sure the value exists
  if ((userEnvironmentPathExists $value) -eq $false) {
    return
  }
  # Found so remove it
  else {
    $path = (getUserEnvironmentPath)
    $regex = $("(\A|;)(" + ([regex]::escape($value)) + ")(\Z|;)")
    $path = $path -replace $regex, ""
    Set-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Environment' -Name PATH -Value $path
  }
}
# Public
Export-ModuleMember deleteUserEnvironmentPath

#
#
#
Function appendSemicolonToUserEnvironmentPath() {
  # 
  $path = (getUserEnvironmentPath)
  if ($path -notmatch ";$") {
    $path += ";"
    Set-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Environment' -Name PATH -Value $path
  }
}
# Protected