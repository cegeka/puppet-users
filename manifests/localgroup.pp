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
#         - Required: yes
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
#     gid => '10001'
#   }
#
# Existing groups can be removed using:
#
#   users::localgroup { 'foo':
#     ensure => 'absent',
#     gid    => '10001'
#   }
#
define users::localgroup ($gid, $ensure='present') {

  if $title !~ /^[a-zA-Z][a-zA-Z0-9_-]*$/ {
    fail("Users::Localgroup[${title}]:
      namevar must be alphanumeric")
  }

  if $gid !~ /^[0-9]+$/ {
    fail("Users::Localgroup[${title}]:
      parameter gid must be numeric")
  }

  if $ensure in [ present, absent ] {
    $ensure_real = $ensure
  }
  else {
    fail("Users::Localgroup[${title}]:
      parameter ensure must be present or absent")
  }

  group { $title:
    ensure => $ensure_real,
    gid    => $gid,
    name   => $title,
  }
}
