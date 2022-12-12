# == Definition: users::localgroup
#
# Adds the specified group on the local system.
#
# === Parameters:
#
# [*name*] The groupname (no default).
#          - Required: yes
#          - Content: String
#
# [*gid*] The numeric id for the group (no default).
#         - Required: no
#         - Content: Integer
#
# [*ensure*] The desired state for the group (default: 'present').
#            - Required: no
#            - Content: 'present' | 'absent'
#
# === Sample Usage:
#
# Groups can be created using:
#
#   users::localgroup { 'foo':
#     gid => 10001
#   }
#
# Existing groups can be removed using:
#
#   users::localgroup { 'foo':
#     ensure => 'absent',
#     gid    => 10001
#   }
#
define users::localgroup (
  Variant[Pattern[/^(\d*)/],Integer,Undef] $gid  = undef,
  Pattern[/^([a-z][a-z0-9_-]*)/] $group = $title,
  Enum['present', 'absent'] $ensure   = 'present'
) {

  group { $group:
    ensure => $ensure,
    gid    => $gid,
    name   => $title,
  }
}
