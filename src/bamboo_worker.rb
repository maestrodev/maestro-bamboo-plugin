
require 'maestro_agent'
require 'bamboo-client'
require 'open-uri'


module MaestroDev
  class BambooWorker < Maestro::MaestroWorker

    def validate_fields
      set_error('')
      
      raise 'Invalid Field Set, Missing host' if get_field('host').nil?
      raise 'Invalid Field Set, Missing port' if get_field('port').nil?
      raise 'Invalid Field Set, Missing username' if get_field('username').nil?
      raise 'Invalid Field Set, Missing password' if get_field('password').nil?
      raise 'Invalid Field Set, Missing project' if get_field('project').nil?
      raise 'Invalid Field Set, Missing plan' if get_field('plan').nil?      
      raise 'Invalid Field Set, Missing use_ssl' if get_field('use_ssl').nil?            
      
      set_field("web_path", "/#{get_field("web_path").andand.gsub(/^\//, '')}") unless get_field('web_path').nil? or get_field('web_path').empty?
    end
    
    def queue_plan
      @queued_data = @plan.queue.data
      Maestro.log.debug "Queued Bamboo Job With Result #{@queued_data.to_json}"
      write_output "Bamboo Build Triggered With Reason #{@queued_data["triggerReason"]}\n"
    end
    
    def wait_for_job
      build = @client.results.last
      write_output "Waiting For Bamboo Build #{@queued_data['buildNumber']}\n"
      
      while(build.nil? or build.life_cycle_state == "InProgress" or build.number != @queued_data['buildNumber'])
        sleep 5
        build = @client.results.last
      end
      write_output "Bamboo Build #{build.number} LifeCycle [#{build.life_cycle_state}] State [#{build.state}]\n"
      @client.results.last
    end
    
    def connect
      @scheme = get_field('use_ssl') ? 'https' : 'http'
      @client = Bamboo::Client.for :rest, "#{@scheme}://#{get_field('host')}:#{get_field('port')}#{get_field('web_path')}"
      @client.login get_field('username'), get_field('password')
      
      @plan = @client.plans.find{|plan| plan.name.match(/#{get_field('plan')}/) and plan.name.match(/#{get_field('project')}/) }
      raise "Plan #{get_field('plan')}  Not Found" if @plan.nil?
      write_output "Found Plan #{@plan.name}\n"
      true
    end
    
    def build
      begin
        Maestro.log.info "Starting Bamboo Worker"
        validate_fields
        
        raise "Connection refused - Connection refused" if !connect
                
        queue_plan

        result = wait_for_job

        write_output("View Results At #{result.url}\n")
        if result.state == :failed
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
