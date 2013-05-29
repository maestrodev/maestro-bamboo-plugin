require 'spec_helper'

describe MaestroDev::BambooWorker do
  before :all do
    @test_participant = MaestroDev::BambooWorker.new
  end
  
  it "should queue a build" do
    wi = {'fields' => {
        'host' => 'localhost',
        'port' => '8085',
        'username' => 'bamboo',
        'password' => 'bamboo',
        'plan_key' => 'CP',
        'project_key' => 'PROJECTKEY',
        'use_ssl' => false,
        'web_path' => '/'
    }}
                                 
       @test_participant.expects(:workitem => wi).at_least_once
       
       @test_participant.expects(:queue_plan => {"buildNumber" => 2})
       @test_participant.expects(:get_results_for_build => {"number" => 2, "lifeCycleState" => "Finished", "state" => "Successful"})
       
       @test_participant.expects(:wait_for_job => {"number" => 2, "lifeCycleState" => "Finished", "state" => "Successful"})
     
       @test_participant.build
       
       wi['fields']['__error__'].should eql('')
     end
     
     it "should set error on error" do
       wi = {'fields' => {
           'host' => 'localhost',
           'port' => '8085',
           'username' => 'bamboo',
           'password' => 'bamboo',
           'plan_key' => 'CP',
           'project_key' => 'PROJECTKEY',
           'use_ssl' => false,
           'web_path' => '/'
       }}
                                 
       @test_participant.expects(:workitem => wi).at_least_once
       
       @test_participant.expects(:queue_plan => {"buildNumber" => 2})
       @test_participant.expects(:get_results_for_build => {"number" => 2, "lifeCycleState" => "Finished", "state" => "Failed"})
       
       @test_participant.expects(:wait_for_job => {"number" => 2, "lifeCycleState" => "Finished", "state" => "Failed"})
     
       @test_participant.build
       
       wi['fields']['__error__'].should eql("Bamboo Job Returned Failed")
     end
  
  # it "should queue a build for real" do
  #   wi = Ruote::Workitem.new({'fields' => { 
  #                             'host' => 'localhost',
  #                             'port' => '8085',
  #                             'username' => 'admin',
  #                             'password' => 'admin1',
  #                             'plan_key' => 'SOMEKEY',
  #                             'project_key' => 'TEST',
  #                             'use_ssl' => false,
  #                             'web_path' => '/'
  #                             }})
  # 
  #   @test_participant = MaestroDev::BambooWorker.new                              
  #   @test_participant.expects(:workitem => wi.to_h).at_least_once
  # 
  #   @test_participant.build
  #   
  #   wi.fields['__error__'].should eql('')
  # end
  # 
  # it "should queue another build for real" do
  #   wi = Ruote::Workitem.new({'fields' => { 
  #                             'host' => 'localhost',
  #                             'port' => '8085',
  #                             'username' => 'admin',
  #                             'password' => 'admin1',
  #                             'plan_key' => 'TEST',
  #                             'project_key' => 'TEST',
  #                             'use_ssl' => false,
  #                             'web_path' => '/'
  #                             }})
  # 
  #   @test_participant = MaestroDev::BambooWorker.new                              
  #   @test_participant.expects(:workitem => wi.to_h).at_least_once
  # 
  #   @test_participant.build
  #   
  #   wi.fields['__error__'].should eql('')  
  # end
  # 
  # it "should queue attempt to build a not found plan for real" do
  #   wi = Ruote::Workitem.new({'fields' => { 
  #                             'host' => 'localhost',
  #                             'port' => '8085',
  #                             'username' => 'admin',
  #                             'password' => 'admin1',
  #                             'plan_key' => 'NOTREAL',
  #                             'project_key' => 'TEST',
  #                             'use_ssl' => false,
  #                             'web_path' => '/'
  #                             }})
  # 
  #   @test_participant = MaestroDev::BambooWorker.new                              
  #   @test_participant.expects(:workitem => wi.to_h).at_least_once
  # 
  #   @test_participant.build
  #   
  #   wi.fields['__error__'].should eql('Plan TEST-NOTREAL not found.')    
  #     
  # end
  # 
  # it "should queue attempt to build and not authenticate" do
  #   wi = Ruote::Workitem.new({'fields' => { 
  #                             'host' => 'localhost',
  #                             'port' => '8085',
  #                             'username' => 'nonuser',
  #                             'password' => 'nonpassword',
  #                             'plan_key' => 'NOTREAL',
  #                             'project_key' => 'TEST',
  #                             'use_ssl' => false,
  #                             'web_path' => '/'
  #                             }})
  # 
  #   @test_participant = MaestroDev::BambooWorker.new                              
  #   @test_participant.expects(:workitem => wi.to_h).at_least_once
  # 
  #   @test_participant.build
  #   
  #   wi.fields['__error__'].should eql('Authentication Failed')    
  #     
  # end
  
end
