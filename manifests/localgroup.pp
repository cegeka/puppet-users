define users::localgroup ($gid='undef', $ensure='present') {

  if $title !~ /^[a-zA-Z0-9_-]+$/ {
    fail("Users::Localgroup[${title}]: namevar must be alphanumeric")
  }

  if $gid !~ /^[0-9]+$/ {
    fail("Users::Localgroup[${title}]: parameter gid must be numeric")
  }

  if $ensure in [ present, absent ] {
    $ensure_real = $ensure
  }
  else {
    fail("Users::Localgroup[${title}: parameter ensure must be present or absent")
  }

  group { $title:
    gid    => $gid,
    ensure => $ensure_real,
    name   => $title,
  }
}
