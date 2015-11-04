require 'xn/error'

module XN
  class Api
    CONFIG_FILE_PATH = ENV['CONFIG_FILE_PATH'] || '/opt/xn_apps/api_config.json'
    ADMIN_TOKEN_PATH = ENV['ADMIN_TOKEN_PATH'] || '/opt/xn_apps/admin_token'

    class << self
      # Starts a XN API session with the provided token.
      def start(xn_token, &block)
        fail ApiError, 'A block is required to start an API session' unless block_given?
        yield Api.new xn_token
      end

      def authenticator_for(user)
        client_conf = client_config(user.client)
        if client_conf
          token = client_conf['authenticator_token']
          yield Api.new token
        end
      end

      def admin_for(user)
        client_conf = client_config(user.client)
        if client_conf
          token = client_conf['admin_token']
          yield Api.new token
        end
      end

      def config
        if File.exists?(CONFIG_FILE_PATH)
          File.open( CONFIG_FILE_PATH, 'r') do |f|
            JSON.parse(f.read)
          end
        else
          {"api_ip" => ENV.fetch('PRODAPI_PORT_8080_TCP_ADDR', ENV.fetch('API_PORT_8080_TCP_ADDR', "192.168.168.168")),
           "api_port" => ENV.fetch('PRODAPI_PORT_8080_TCP_PORT', ENV.fetch('API_PORT_8080_TCP_PORT', '80')),
           "api_prefix" => ENV.fetch('XN_API_PREFIX', "/v1"),
           "default_client" => "dev",
           "sample_passwords" => [
             "Enrique Chan",
             "Hugo Boss",
             "Juan Ostler",
             "Mel Gibson",
             "Penny Pincher",
             "Senor Manager",
             "Sir Lancelot",
             "SGDC Support",
             "IPAM Admin"
           ]}
        end
      end

      def create_users!
        each_client do |authenticator_api|
          puts "Loading client data: #{ authenticator_api.client }"
          result = User.create_users_from_api authenticator_api
          puts JSON.pretty_generate result
        end
      end

      def default_client
        config['default_client']
      end

      def sample_password?(name)
        list = config['sample_passwords']
        list.include? name if list
      end

      def admin_token
        ENV.fetch 'ADMIN_TOKEN' do
          if File.exist? ADMIN_TOKEN_PATH
            File.read(ADMIN_TOKEN_PATH).match(/'(.*)'$/)[1]
          else
            'admin' # May work if the API is in dev mode
          end
        end
      end

      def client_config(client)
        Api.new(admin_token).get("/is/client/filter/name/report/app_tokens?name=#{client}") do |data|
          data = data['app_tokens']
          data.first if data
        end
      end

      def each_client
        Api.new(admin_token).get("/is/client/properties/name") do |clients|
          clients.each do |(id, client)|
            begin
              client_conf = client_config(client)
            rescue Error::ApiError
            end
            if client_conf
              token = client_conf['authenticator_token']
              yield Api.new(token) unless token.blank?
            end
          end
        end
      end

      def client_tokens(client_name)
        admin_api=XN::Api.new(XN::Api.admin_token)
        client=admin_api.get("/is/client/unique/filters/name~1?name~1=#{client_name}").first
        raise XN::Error::NotFoundError("Could not find client with name: #{client_name}") unless client
        client_tokens=admin_api.get("/is/client/id/#{client["id"]}/report/app_tokens")
      end
    end

    def initialize(token)
      fail "Can't connect to the API without a token" if token.blank?
      @token = token
    end

    # Yes, this reloads the config on every request, but our traffic is low
    # enough it's not a concern and it makes it easy to adjust the config.
    def client_config(client)
      Api.client_config(client) or fail "Unknown client #{ client }"
    end

    def get(resource_url, &block)
      call_http_server Net::HTTP::Get.new("#{ api_prefix }#{ resource_url }"), &block
    end

    def pull(resource_url, body, &block)
      post("#{resource_url}/pull", body, &block)
    end

    def post(resource_url, body = nil, &block)
      req = Net::HTTP::Post.new("#{ api_prefix }#{ resource_url }")
      req.body = body.to_json unless body.nil?
      call_http_server req, &block
    end

    def delete(resource_url, &block)
      call_http_server Net::HTTP::Delete.new("#{ api_prefix }#{ resource_url }"), &block
    end

    def put(resource_url, body = nil, &block)
      req = Net::HTTP::Put.new("#{ api_prefix }#{ resource_url }")
      req.body = body.to_json unless body.nil?
      call_http_server req, &block
    end

    def patch(resource_url, body = nil, &block)
      req = Net::HTTP::Patch.new("#{ api_prefix }#{ resource_url }")
      req.body = body.to_json unless body.nil?
      call_http_server req, &block
    end

    def client
      @token.split(' ').first
    end

    private

    def api_server_url
      URI("http://#{Api.config['api_ip']}:#{Api.config['api_port']}")
    end

    def api_prefix
      Api.config['api_prefix']
    end

    def call_http_server(request, &block)
      request['AUTHORIZATION'] = @token
      url = api_server_url
      Net::HTTP.start(url.host, url.port, use_ssl: url.scheme == 'https') do |http|
        response = http.request request
        status_code, json = parse_response response
        puts "RESPONSE: #{ status_code } - #{ json.inspect }"
        raise_if_error status_code, json
        if block
          block.call json
        else
          json
        end
      end
    rescue Errno::ECONNREFUSED => e
      raise Error::ApiError.new e.message
    end

    def parse_response(response)
      [response.code.to_i, JSON.parse(response.body)]
    end

    def raise_if_error(status_code, json)
      return if status_code < 300
      exception_class =
        case status_code
        when 400
          Error::BadRequestError
        when 401, 403
          Error::UnauthorizedError
        when 404
          Error::NotFoundError
        else
          Error::ApiError
        end
      message = json['message'] rescue json
      fail exception_class.new(message, status_code)
    end


  end
end
