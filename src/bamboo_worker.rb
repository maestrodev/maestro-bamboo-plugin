require 'maestro_plugin'
require 'maestro_common/common'#utils/retryable'

module MaestroDev
  module Plugin
    class BambooWorker < Maestro::MaestroWorker

      def build
        validate_fields

        @queued_data = queue_plan

        Maestro.log.debug "Queued Bamboo Job With Result #{@queued_data.to_json}"
        write_output "Bamboo Build Triggered With Reason #{@queued_data["triggerReason"]}\n"

        result = wait_for_job

        if result["state"].downcase == "failed"
          raise PluginError, "Bamboo Job Returned Failed"
        end
      end

      ###########
      # PRIVATE #
      ###########
      private

      def validate_fields
        errors = []

        @host = get_field('host', '')
        @port = get_int_field('port')
        @username = get_field('username', '')
        @password = get_field('password', '')
        @plan_key = get_field('plan_key', '')
        @project_key = get_field('project_key', '')
        @use_ssl = get_boolean_field('use_ssl')

        errors << 'Invalid Field Set, Missing host' if @host.empty?
        errors << 'Invalid Field Set, Missing port' if @port < 1
        errors << 'Invalid Field Set, Missing username' if @username.empty?
        errors << 'Invalid Field Set, Missing password' if @password.empty?
        errors << 'Invalid Field Set, Missing plan key' if @plan_key.empty?     
        errors << 'Invalid Field Set, Missing project key' if @project_key.empty?      
        
        @scheme = @use_ssl ? 'https' : 'http'
        @web_path = get_field('web_path', '')
        @web_path = "/#{@web_path.gsub(/^\//, '')}"

        raise ConfigError, "Config Errors: #{errors.join(', ')}" unless errors.empty?
      end
      
      def parse_response(response)
        body = response.body
        begin
          result = JSON.parse(body)
        rescue JSON::ParserError => e
          begin
            #not json try xml
            result = XmlSimple.xml_in(body)
          rescue ArgumentError => xml_error
            # not xml either, raise original exception
            raise e
          end
        end
        result      
      end
      
      def queue_plan
        queued_data = nil
        # Note - retryable block seems to mess with webmock if webmock wants to raise an exception.
        # Have not looked deeper, but if you find this code seemingly blocking @ the http.request
        # line, comment out the retryable wrapper and see if that displays an error
        Maestro::Utils::retryable(:tries => 5, :on => Exception) do
          Net::HTTP.start(@host, @port) {|http|
            http.use_ssl = @use_ssl
            req = Net::HTTP::Post.new("/rest/api/latest/queue/#{@project_key}-#{@plan_key}.json", initheader = {'Accept' => 'json'})
            req.basic_auth @username, @password
            response = http.request(req)
            case response.code
              when '200'
                queued_data = parse_response(response)
              when '401'
                raise PluginError, "Authentication Failed"
              else
                raise Exception.new("Error queuing plan: #{parse_response(response)["message"]}")
            end
          }
        end
        
        queued_data
      end
      
      def get_results_for_build(build)
        result = nil
        Maestro::Utils::retryable(:tries => 5, :on => Exception) do
          Net::HTTP.start(@host, @port) {|http|
            http.use_ssl = @use_ssl
            req = Net::HTTP::Get.new("/rest/api/latest/result/#{@project_key}-#{@plan_key}-#{build}.json", initheader = {'Accept' => 'json'})
            req.basic_auth @username, @password
            response = http.request(req)
            
            case response.code
              when '200'
                result = parse_response(response)
              when '401'
                raise "Authenitcation Failed"
              else
                raise Exception.new("Error getting results for build #{build}: #{parse_response(response)["message"]}")
            end
          }
        end
        result  
      end
      
      def wait_for_job
        result = get_results_for_build @queued_data['buildNumber']
        write_output "Waiting For Bamboo Build #{@queued_data['buildNumber']} Of Plan #{@plan_key}\n"
  
        while(result.nil? or result['lifeCycleState'].downcase != "finished" )
          sleep 5
          result = get_results_for_build @queued_data['buildNumber']
        end
        write_output "Bamboo Build #{result['number']} For #{result['key']} Has LifeCycle [#{result['lifeCycleState']}] State [#{result['state']}]\n"
        result
      end
      
    end
  end
end
