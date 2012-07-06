require 'maestro_agent'

module MaestroDev
  class BambooWorker < Maestro::MaestroWorker

    def validate_fields
      
      set_error('')
      
      raise 'Invalid Field Set, Missing host' if get_field('host').nil?
      raise 'Invalid Field Set, Missing port' if get_field('port').nil?
      raise 'Invalid Field Set, Missing username' if get_field('username').nil?
      raise 'Invalid Field Set, Missing password' if get_field('password').nil?
      raise 'Invalid Field Set, Missing plan key' if get_field('plan_key').nil?     
      raise 'Invalid Field Set, Missing project key' if get_field('project_key').nil?      
      raise 'Invalid Field Set, Missing use_ssl' if get_field('use_ssl').nil?            
      
      @scheme = get_field('use_ssl') ? 'https' : 'http'
      set_field("web_path", "/#{get_field("web_path").andand.gsub(/^\//, '')}") unless get_field('web_path').nil? or get_field('web_path').empty?
    end
    
    def parse_response(response)
      body = response.body
      begin
        result = JSON.parse(body)
      rescue Exception => e
        #not json try xml
        result = XmlSimple.xml_in(body)
      end
      result      
    end
    
    def queue_plan
      queued_data = nil
      retryable(:tries => 5, :on => Exception) do
        Net::HTTP.start(get_field('host'), get_field('port')) {|http|
          http.use_ssl = get_field('use_ssl')
          req = Net::HTTP::Post.new("/rest/api/latest/queue/#{get_field('project_key')}-#{get_field('plan_key')}.json", initheader = {'Accept' => 'json'})
          req.basic_auth get_field('username'), get_field('password')
          response = http.request(req)
          case response.code
            when '200'
              queued_data = parse_response(response)
            when '401'
              raise "Authentication Failed"
            else
              raise Exception.new(parse_response(response)["message"])
          end
        }
      end
      
      queued_data
    end
    
    def get_results_for_build(build)
      result = nil
      retryable(:tries => 5, :on => Exception) do
        Net::HTTP.start(get_field('host'), get_field('port')) {|http|
          http.use_ssl = get_field('use_ssl')
          req = Net::HTTP::Get.new("/rest/api/latest/result/#{get_field('project_key')}-#{get_field('plan_key')}-#{build}.json", initheader = {'Accept' => 'json'})
          req.basic_auth get_field('username'), get_field('password')
          response = http.request(req)
          
          case response.code
            when '200'
              result = parse_response(response)
            when '401'
              raise "Authenitcation Failed"
            else
             raise Exception.new(parse_response(response)["message"])
          end
        }
      end
      result  
    end
    
    def wait_for_job
      result = get_results_for_build @queued_data['buildNumber']
      write_output "Waiting For Bamboo Build #{@queued_data['buildNumber']} Of Plan #{get_field('plan_key')}\n"

      while(result.nil? or result['lifeCycleState'].downcase != "finished" )
        sleep 5
        result = get_results_for_build @queued_data['buildNumber']
      end
      write_output "Bamboo Build #{result['number']} For #{result['key']} Has LifeCycle [#{result['lifeCycleState']}] State [#{result['state']}]\n"
      result
    end
    
    def build
      begin
        Maestro.log.info "Starting Bamboo Worker"
        validate_fields

        @queued_data = queue_plan        
        Maestro.log.debug "Queued Bamboo Job With Result #{@queued_data.to_json}"
        write_output "Bamboo Build Triggered With Reason #{@queued_data["triggerReason"]}\n"
        
        result = wait_for_job

        if result["state"].downcase == "failed"
          set_error( "Bamboo Job Returned Failed" )
        end
        
      rescue Exception => e
        set_error(e.message)
      end
      
      Maestro.log.debug "Maestro::BambooParticipant::work complete!"
      Maestro.log.info "***********************Completed Bamboo***************************"
    end
    
  end
end
