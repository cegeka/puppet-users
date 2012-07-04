# == Definition: users::localuser
#
# Adds the specified user on the local system, adds a dir bin to the homedir and adds a public key to the
# ~/.ssh/authorized_keys file, if provided.
#
# === Parameters:
#
# [*name*] The username (no default).
#          - Required: yes
#          - Content: String
#
# [*uid*] The numeric id for the user (no default).
#         - Required: yes
#         - Content: Integer
#
# [*logingroup*] The primary group for the user (no default).
#                - Required: yes
#                - Content: String
#
# [*groups*] The auxiliary groups the user belongs to (default: []).
#            - Required: no
#            - Content: Array of Strings
#
# [*password*] The hashed password string, defaults to "locked" (default: '!').
#              - Required: no
#              - Content: String
#
# [*comment*] The GECOS field associated with this user (default: '').
#             - Required: no
#             - Content: String
#
# [*sshkey*] The public key to be copied to ~/.ssh/authorized_keys (no default).
#            - Required: no
#            - Content: String
#
# [*sshkeytype*] The ssh key encryption type: ssh-dsa/ssh-rsa (no default)
#                - required: yes
#                - content: String
#
# [*ensure*] The desired state for the user (default: 'present').
#            - Required: no
#            - Content: 'present' | 'absent'
#
# [*managehome*] Should the home directory be created automatically
#                (default: true).
#                - Required: no
#                - Content: Boolean
#
# [*home*] The home directory for the user (default: '/home/${name}').
#          - Required: no
#          - Content: String
#
# [*shell*] The login shell for the user (default: '/bin/bash').
#           - Required: no
#           - Content: String
#
# === Requires:
#
#   Group[$logingroup]
#
# === Sample Usage:
#
# Users can be created using:
#
#   users::localuser { 'foo':
#     uid        => '10001',
#     logingroup => 'testgrp'
#   }
#
#   users::localuser { 'bar':
#     uid        => '10002',
#     logingroup => 'testgrp',
#     password   => '$1$64hp6Ust$DGjSKcEXwmSZ4BTQe9idH0',
#     sshkey     => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA0mBONiRaPTqTaKfA1l==',
#     type       => 'ssh-rsa',
#     groups     => [ 'testgrp1', 'testgrp2'],
#     shell      => '/bin/ksh'
#   }
#
# Existing users can be removed using:
#
#   users::localuser { 'foo':
#     ensure     => 'absent',
#     uid        => '10001',
#     logingroup => 'testgrp'
#   }
#
define users::localuser ($uid, $logingroup, $groups=[], $password='!', $comment='',  $sshkey='', $sshkeytype='', $ensure='present', $managehome=true, $home="/home/${title}", $shell='/bin/bash') {

  if $title !~ /^[a-zA-Z][a-zA-Z0-9_-]*$/ {
    fail("Users::Localuser[${title}]: namevar must be alphanumeric")
  }

  if $uid !~ /^[0-9]+$/ {
    fail("Users::Localuser[${title}]: parameter uid must be numeric")
  }

  if $logingroup !~ /^[a-zA-Z][a-zA-Z0-9_-]*$/ {
    fail("Users::Localuser[${title}]: parameter logingroup must be alphanumeric")
  }

  if $ensure in [ present, absent ] {
    $ensure_real = $ensure
  }
  else {
    fail("Users::Localgroup[${title}]: parameter ensure must be present or absent")
  }

  case $managehome {
    true, false: { $managehome_real = $managehome }
    default: {
      fail("Users::Localuser[${title}]: parameter managehome must be a boolean")
    }
  }

  user { $title:
    ensure     => $ensure_real,
    uid        => $uid,
    gid        => $logingroup,
    groups     => $groups,
    shell      => $shell,
    comment    => $comment,
    home       => $home,
    password   => $password,
    managehome => $managehome_real,
    require    => Group[$logingroup]
  }

  file { "${home}/bin":
    ensure => 'directory'
    owner  => $uid,
    group  => $logingroup,
  }

  if $sshkey != '' {
    ssh_authorized_key { $title:
      ensure  => $ensure_real,
      key     => $sshkey,
      type    => $sshkeytype,
      user    => $title,
      require => User[$title]
    }
  }
}
