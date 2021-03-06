# == Define dns::record::a
#
# Wrapper for dns::record to set an A record, optionally
# also setting a PTR at the same time.
#
define bind::record::a (
  $zone,
  $data,
  $ttl = '',
  $ptr = false,
  $host = $name ) {

  $alias = "${host},A,${zone}"

  bind::record { $alias:
    zone => $zone,
    host => $host,
    ttl  => $ttl,
    data => $data
  }

  if $ptr {
    $ip = inline_template('<%= @data.kind_of?(Array) ? @data.first : @data %>')
    $reverse_zone = inline_template('<%= @ip.split(".")[0..-2].reverse.join(".") %>.in-addr.arpa')
    $octet = inline_template('<%= @ip.split(".")[-1] %>')

    bind::record::ptr { "${octet}.${reverse_zone}":
      host => $octet,
      zone => $reverse_zone,
      data => "${host}.${zone}"
    }
  }
}
