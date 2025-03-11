#!/opt/puppetlabs/puppet/bin/ruby
#
# A note on logging:
#   This script's stderr and stdout are only shown at the DEBUG level
#   of the server's logs. This means you won't see the error messages
#   in puppetserver.log by default. All you'll see is the exit code.
#
#   https://docs.puppet.com/puppet/latest/ssl_autosign.html#policy-executable-api
#
# Exit Codes:
#   0 - A matching challengePassword was found.
#   1 - No challengePassword was found.
#   2 - The wrong challengePassword was found.
#
require 'puppet/ssl'

csr = Puppet::SSL::CertificateRequest.from_s(STDIN.read)
psk = File.read('/etc/puppetlabs/puppet/psk').chomp.strip

if pass = csr.custom_attributes.find do |attribute|
     ['challengePassword', '1.2.840.113549.1.9.7'].include? attribute['oid']
   end
else
  puts 'No challengePassword found. Rejecting certificate request.'
  exit 1
end

if pass['value'] == psk
  exit 0
else
  puts "challengePassword does not match: #{pass['value']}"
  exit 2
end