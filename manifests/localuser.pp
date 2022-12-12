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
define users::localuser (
  Enum['present', 'absent'] $ensure = 'present',
  Pattern[/^([a-z][a-z0-9_-]*)/] $user = $title,
  Variant[Pattern[/^(\d*)/],Integer,Undef] $uid = undef,
  Pattern[/^([a-z][a-z0-9_-]*)/] $logingroup = undef,
  Array[String] $groups = [],
  String $password = '!',
  String $comment = '',
  Optional $sshkey = undef,
  Optional $sshkeytype = undef,
  Boolean $managehome = true,
  String $home = "/home/${user}",
  Boolean $managebashrc = true,
  String $shell = '/bin/bash',
  Optional $env_class = undef,
  Optional $secret_id = undef) {

  case $ensure {
    'absent': {
      user { $user:
        ensure      => $ensure,
        managehome  => $managehome
      }

      file { "${home}/bin":
        ensure  => $ensure,
        recurse => true,
        force   => true,
        before  => User[$user]
      }
    }
    'present': {
      if $secret_id == undef {
        user { $user:
          ensure     => $ensure,
          uid        => $uid,
          gid        => $logingroup,
          groups     => $groups,
          shell      => $shell,
          comment    => $comment,
          home       => $home,
          password   => $password,
          managehome => $managehome,
          require    => Group[$logingroup]
        }
      }
      else {
        user { $user:
          ensure     => $ensure,
          uid        => $uid,
          gid        => $logingroup,
          groups     => $groups,
          shell      => $shell,
          comment    => $comment,
          home       => $home,
          password   => pw_hash(getsecret($secret_id, 'Password'),'SHA-512',getsecret($secret_id, 'SALT')),
          managehome => $managehome,
          require    => Group[$logingroup]
        }
      }

      file { "${home}/bin":
        ensure  => directory,
        owner   => $uid,
        group   => $logingroup,
        require => User[$user],
      }

      if $sshkey {
        ssh_authorized_key { $user:
          ensure  => $ensure,
          key     => $sshkey,
          type    => $sshkeytype,
          user    => $user,
          require => User[$user]
        }
      }

      if $env_class {
        class { $env_class:
          owner => $user,
          group => $logingroup,
          home  => $home
        }
        User[$user] -> Class[$env_class]
      }

      file { "${home}/.bash_profile":
        ensure  => present,
        owner   => $uid,
        group   => $logingroup,
        path    => "${home}/.bash_profile",
        require => User[$user]
      }
      file { "${home}/.bashrc":
        ensure  => present,
        owner   => $uid,
        group   => $logingroup,
        path    => "${home}/.bashrc",
        require => User[$user]
      }

      # remove existing lines
      file_line { "remove old ${home}/.bash_profile":
        path    => "${home}/.bash_profile",
        line    => '[ -d .profile.d ] && [ -f .profile.d/*.sh ] && source .profile.d/*.sh',
        require => [User[$user],File["${home}/.bash_profile"]],
        ensure  => absent
      }
      file_line { "remove old ${home}/.bashrc":
        path    => "${home}/.bashrc",
        line    => '[ -d .profile.d ] && [ -z "$PS1" ] && [ -f .profile.d/*.sh ] && source .profile.d/*.sh',
        require => [User[$user],File["${home}/.bashrc"]],
        ensure  => absent
      }
      # add new lines
      file_line { "${home}/.bash_profile":
        path    => "${home}/.bash_profile",
        line    => '[ -d .profile.d ] && for file in ./.profile.d/*.sh; do [ -e "$file" ] && source $file || true; done',
        require => [User[$user],File["${home}/.bash_profile"]]
      }
      if $managebashrc {
        file_line { "${home}/.bashrc":
          path    => "${home}/.bashrc",
          line    => '[ -d .profile.d ] && [ -z "$PS1" ] && for file in ./.profile.d/*.sh; do [ -e "$file" ] && source $file || true; done',
          require => [User[$user],File["${home}/.bashrc"]]
        }
      }

      file { "${home}/.profile.d":
        ensure  => directory,
        owner   => $uid,
        group   => $logingroup,
        mode    => '0750',
        require => User[$user]
      }
      file { "${home}/.ssh":
        ensure  => directory,
        owner   => $uid,
        group   => $logingroup,
        mode    => '0700',
        require => User[$user]
      }

    }
  }
}
