# == Definition: users::localuser
#
# Adds the specified user on the local system, adds a dir bin to the homedir and
# adds a public key to the ~/.ssh/authorized_keys file, if provided.
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
# [*env_class*] The name of an optional Puppet Class that contains code for
#               the environment setup of the user. This class has 3 parameters:
#               owner, group and home. These will be used when creating
#               files (no default).
#               - Required: no
#               - Content: String
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
#     shell      => '/bin/ksh',
#     env_class  => 'users::env::bar'
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
define users::localuser ( $ensure='present',$uid=undef, $logingroup=undef, $groups=[], $password='!',
                          $comment='',  $sshkey='', $sshkeytype='',
                          $managehome=true,
                          $home="/home/${title}", $shell='/bin/bash',
                          $env_class=undef) {

  if $title !~ /^[a-zA-Z][a-zA-Z0-9_-]*$/ {
    fail("Users::Localuser[${title}]: namevar must be alphanumeric")
  }

  if $ensure in [ present, absent ] {
    $ensure_real = $ensure
  }
  else {
    fail("Users::Localgroup[${title}]:
    parameter ensure must be present or absent")
  }

  case $managehome {
    true, false: { $managehome_real = $managehome }
    default: {
      fail("Users::Localuser[${title}]: parameter managehome must be a boolean")
    }
  }

  case $ensure_real {
    'absent': {
      user { $title:
        ensure      => $ensure_real,
        managehome  => $managehome
      }

      file { "${home}/bin":
        ensure => $ensure_real,
        before => User[$title]
      }
    }
    default: {
      if $uid !~ /^[0-9]+$/ {
        fail("Users::Localuser[${title}]: parameter uid must be numeric")
      }

      if $logingroup !~ /^[a-zA-Z][a-zA-Z0-9_-]*$/ {
        fail("Users::Localuser[${title}]:
          parameter logingroup must be alphanumeric")
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
        ensure  => directory,
        owner   => $uid,
        group   => $logingroup,
        require => User[$title],
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

      if $env_class {
        class { $env_class:
          owner => $title,
          group => $logingroup,
          home  => $home
        }
        User[$title] -> Class[$env_class]
      }

      file { "${home}/.bash_profile":
        ensure  => present,
        owner   => $uid,
        group   => $logingroup,
        path    => "${home}/.bash_profile",
        require => User[$title]
      }
      file { "${home}/.bashrc":
        ensure  => present,
        owner   => $uid,
        group   => $logingroup,
        path    => "${home}/.bashrc",
        require => User[$title]
      }

      # remove existing lines
      file_line { "remove old ${home}/.bash_profile":
        path    => "${home}/.bash_profile",
        line    => '[ -d .profile.d ] && [ -f .profile.d/*.sh ] && source .profile.d/*.sh',
        require => [User[$title],File["${home}/.bash_profile"]],
        ensure  => absent
      }
      file_line { "remove old ${home}/.bashrc":
        path    => "${home}/.bashrc",
        line    => '[ -d .profile.d ] && [ -z "$PS1" ] && [ -f .profile.d/*.sh ] && source .profile.d/*.sh',
        require => [User[$title],File["${home}/.bashrc"]],
        ensure  => absent
      }
      # add new lines
      file_line { "${home}/.bash_profile":
        path    => "${home}/.bash_profile",
        line    => '[ -d .profile.d ] && for file in ./.profile.d/*.sh; do [ -e "$file" ] && source $file || true; done',
        require => [User[$title],File["${home}/.bash_profile"]]
      }
      file_line { "${home}/.bashrc":
        path    => "${home}/.bashrc",
        line    => '[ -d .profile.d ] && [ -z "$PS1" ] && for file in ./.profile.d/*.sh; do [ -e "$file" ] && source $file || true; done',
        require => [User[$title],File["${home}/.bashrc"]]
      }

      file { "${home}/.profile.d":
        ensure  => directory,
        owner   => $uid,
        group   => $logingroup,
        mode    => '0750',
        require => User[$title]
      }

    }
  }
}
