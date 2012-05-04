# this should be included in your puppet::master class; no need for this on the puppet agents
class datadog::install-puppet-report-processor {
    require datadog::params
    
    file{
        "/usr/lib/ruby/site_ruby/1.8/puppet/reports/datadog.rb":
            mode    => 444,
            owner   => root,
            group   => root,
            require => [Package["dogapi",File["/etc/puppet/datadog.yml"]],
            content => template("$module_name/reports/datadog.rb");
        "/etc/puppet/datadog.yml":
            mode    => 444,
            owner   => root,
            group   => root,
            content => template("$module_name/reports/datadog.yml");
    }
}
