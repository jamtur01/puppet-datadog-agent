# fork of git://github.com/jamtur01/puppet-datadog.git
# by jkoppe: make it work with the newer datadogapi and dogapi-rb
#            add configuration_version
#            don't send the entire log to datadog
#            NOTE: you only need this on your masters; not all of
#                  my agents have the dogapi-rb gem
require 'puppet'
require 'yaml'

begin
  require 'dogapi'
rescue LoadError => e
  Puppet.info "You need the `dogapi` gem to use the DataDog report"
end

Puppet::Reports.register_report(:datadog) do

  configfile = File.join([File.dirname(Puppet.settings[:config]), "datadog.yaml"])
  raise(Puppet::ParseError, "DataDog report config file #{configfile} not readable") unless File.exist?(configfile)
  config = YAML.load_file(configfile)
  API_KEY = config[:datadog_api_key]
  ENV['DATADOG_HOST'] = 'https://app.datadoghq.com/'

  desc <<-DESC
  Send notification of metrics to DataDog
  DESC

  def process
    @status = self.status

    # we only care about the hostname, so split on the host in the report transaction since it might be the fqdn
    @msg_host = self.host.split('.')[0]

    # we add SVN and environment information here, so this is very useful to us
    @configuration_version = self.configuration_version

    Puppet.debug "Sending metrics for #{@msg_host} to DataDog"
    @dog = Dogapi::Client.new(API_KEY)
    self.metrics.each { |metric,data|
      data.values.each { |val|
        name = "puppet.#{val[1].gsub(/ /, '_')}.#{metric}".downcase
        value = val[2]
        @dog.emit_point("#{name}", value, :host => "#{@msg_host}")
      }
    }
    Puppet.debug "Done sending metrics for #{@msg_host} to DataDog"


    # don't bother sending the agent log to datadog -- we'll get the detailed information from foreman or dashboard
    Puppet.debug "Sending events for #{@msg_host} to DataDog"
    output = "Puppet agent run on #{@msg_host} for version #{@configuration_version} (status: #{@status})"
    @dog.emit_event(Dogapi::Event.new(output), :host => "#{@msg_host}", :msg_title => "Puppet agent run on #{@msg_host}", :event_type => 'Puppet')
    Puppet.debug "Done sending events for #{@msg_host} to DataDog"
  end
end
