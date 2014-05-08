#!/usr/bin/env ruby
require 'net/https'
require 'uri'
require 'json'

class Dynect
  class Client
    
    def self.set_dns(customer_name, user_name, password, tld, record, new_address)
# Set up our HTTP object with the required host and path
      url = URI.parse('https://api2.dynect.net/REST/Session/')
      headers = { "Content-Type" => 'application/json' }
      http = Net::HTTP.new(url.host, url.port)
      if ENV['DEBUG']
        http.set_debug_output $stderr
      end
      http.use_ssl = true
#http.verify_mode = OpenSSL::SSL::VERIFY_CLIENT_ONCE

# Login and get an authentication token that will be used for all subsequent requests.
      session_data = { :customer_name => customer_name, :user_name => user_name, :password => password }
      resp, data = http.post(url.path, session_data.to_json, headers)
      result = JSON.parse(resp.body)

      auth_token = ''
      if result['status'] == 'success'
        auth_token = result['data']['token']
      else
# the messages returned from a failed command are a list
        result['msgs'][0].each{|key, value| print key, " : ", value, "\n"}
      end

# New headers to use from here on with the auth-token set
      headers = { "Content-Type" => 'application/json', 'Auth-Token' => auth_token }

# Create the A record
      url = URI.parse("https://api2.dynect.net/REST/ARecord/#{tld}/#{record}/")
      record_data = { :rdata => { :address => new_address }, :ttl => "30" }
      resp, data = http.post(url.path, record_data.to_json, headers)

# Publish the changes
      url = URI.parse("https://api2.dynect.net/REST/Zone/#{tld}/")
      publish_data = { "publish" => "true" }
      resp, data = http.put(url.path, publish_data.to_json, headers)
    end
  end
end
