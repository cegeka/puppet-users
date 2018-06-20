# == Definition: users::localsshkey
#
#  Usage:
#
#  this define is called from the IAC usermanagement profiles.
#  it can fetch a public key from pim.
#  - if 'key_secret_id' is defined, the public key will be fetched from PIM.
#  - if 'key' is defined, the value of the field will be used.
#
#  Please note that a 'normal' public key file containing keytype, key and comment will not work when stored in pim:
#  Only the key can exist in the pim file or pim field!
#
#  Hiera Example with 'key':
#  profile::iac::usermanagement::publickeys:
#    'puppetestuser':
#      user: 'puppettestuser'
#      type: 'ssh-rsa'
#      key: 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCxm55LSBPNjFNnNY/e2iqw1aYD6DVN83tuph4+4CCwQAn9XUcg4UVriUdf5BsBlcpUsLVFrmZB3rnH4ANiKiYOmWgPL+NWDOr4o71eTLm7eD1lwDvGtitiDbfamkm7Q3Y5ZG3Iv2fOquGqNKB1E/5fFY6kr477FGIHE5GqXgBtiHWQ5ajQPm/hpKVx8xANHMaX4gkF9gKb3cDDEq8w/mBfrc/iNDlMbQ0YnUK8v+FApVjqhJ6NYvLaLlUVBlWy3oCy//NCzSTzFv+8za4okGZt6Vh7ynbO3/v8XXZZLXIDhBsekqdH+8huI2dg2JSMTkqZlMw7lEbOZoo0uMPshMCv'
#
#  Hiera Example with 'key_secret_id':
#  profile::iac::usermanagement::publickeys:
#    'puppetestuser':
#      user: 'puppettestuser'
#      type: 'ssh-rsa'
#      key_secret_id: '101611'

define users::localsshkey(
  $user,
  $type,
  $ensure = undef,
  $key_secret_id = undef,
  $key = undef,
  $options = undef,
  $target = undef,
){

  if $key == undef and $key_secret_id != undef {
    $realkey = regsubst(getsecret($key_secret_id, 'Public Key'),'\n$','')
  }
  elsif $key != undef {
    $realkey = $key
  }

  ssh_authorized_key { $title:
    user     =>  $user,
    type     =>  $type,
    ensure   =>  $ensure,
    key      =>  $realkey,
    options  =>  $options,
    target   =>  $target,
  }

}
