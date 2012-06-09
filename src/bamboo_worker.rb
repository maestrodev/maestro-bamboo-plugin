
require 'maestro_agent'
require 'bamboo-client'
require 'open-uri'

module Bamboo
  module Client
    class Rest < Abstract
      def builds
        get("result/").auto_expand Build, @http
      end
    end
  end
end


module MaestroDev
  class BambooWorker < Maestro::MaestroWorker

    def validate_fields
      fields = workitem['fields']
      fields['__error__'] = ''
      
      raise 'Invalid Field Set, Missing host' if fields['host'].nil?
      raise 'Invalid Field Set, Missing port' if fields['port'].nil?
      raise 'Invalid Field Set, Missing username' if fields['username'].nil?
      raise 'Invalid Field Set, Missing password' if fields['password'].nil?
      raise 'Invalid Field Set, Missing project' if fields['project'].nil?
      raise 'Invalid Field Set, Missing plan' if fields['plan'].nil?            
      
      fields["web_path"] = "/#{fields["web_path"].andand.gsub(/^\//, '')}" unless fields['web_path'].nil? or fields['web_path'].empty?
      
      fields 
    end
    
    def queue_plan
      retryable(:tries => 5, :on => Exception) do
        @queued_data = @plan.queue.data
      end
      
      Maestro.log.debug "Queued Bamboo Job With Result #{@queued_data.to_json}"
      write_output "Bamboo Build Triggered With Reason #{@queued_data["triggerReason"]}\n"
    end
    
    def wait_for_job
      build = @client.results.last
      write_output "Waiting For Bamboo Build #{@queued_data['buildNumber']}\n"
      while(build.life_cycle_state == "InProgress" or build.number != @queued_data['buildNumber'])
        sleep 5
        build = @client.results.last
      end
      write_output "Bamboo Build #{build.number} LifeCycle [#{build.life_cycle_state}] State [#{build.state}]\n"
      @client.results.last
    end
    
    def get_result_log
      build = @client.results.last      
      url = "http://#{@fields['username']}:#{@fields['password']}@#{@fields['host']}:#{@fields['port']}#{@fields['web_path']}/download/#{@plan.key}-JOB1/build_logs/#{@plan.key}-JOB1-#{build.number}.log"
      open(url) do |f|
        write_output f.read
      end
    end
    
    def connect
      @client = Bamboo::Client.for :rest, "http://#{@fields['username']}:#{@fields['password']}@#{@fields['host']}:#{@fields['port']}#{@fields['web_path']}"

      @plan = @client.plans.first
      
      true
    end
    
    def build
      begin
        Maestro.log.info "Starting Bamboo participant"
        @fields = validate_fields
        
        raise "Connection refused - Connection refused" if !connect
                
        queue_plan

        if wait_for_job.state == "Failed"
          set_error( "Bamboo Job Returned Failed" )
        end
        get_result_log
        
      rescue Exception => e
        puts e, e.backtrace
        set_error(e.message)
      end
      
      Maestro.log.debug "Maestro::BambooParticipant::work complete!"
      Maestro.log.info "***********************Completed Bamboo***************************"
    end
    
  end
end
