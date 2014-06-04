require 'xmlrpc/client'

module BacklogII
  class Client
    include API
    attr_reader :host, :user, :password, :client

    PATH         = '/XML-RPC'
    PORT         = 443
    PROXY_HOST   = nil
    PROXY_PORT   = nil
    USE_SSL      = true
    TIMEOUT      = 60

    MAX_ATTEMPTS = 3
    DELAY_TIME   = 1

    def initialize(space, user, password)
      @host     = space + '.backlog.jp'
      @user     = user
      @password = password
      @client   = XMLRPC::Client.new(@host, PATH, PORT, PROXY_HOST, PROXY_PORT, @user, @password, USE_SSL, TIMEOUT)
    end

    def call(method, args=nil)
      if args
        num_attempts = 0
        begin
          num_attempts += 1
          @client.call(method, args)
        rescue XMLRPC::FaultException => e
          if num_attempts <= MAX_ATTEMPTS
            sleep DELAY_TIME
            retry
          else
            puts "Error #{e.faultCode}: #{e.faultString}"
            raise
          end
        end
      else
        @client.call(method)
      end
    end
  end
end
