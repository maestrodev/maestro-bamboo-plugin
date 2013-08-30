require 'spec_helper'

describe MaestroDev::Plugin::BambooWorker do
  before(:each) do
    @wi = {'fields' => {
        'host' => 'example.com',
        'port' => '80',
        'username' => 'bamboo',
        'password' => 'bamboo',
        'plan_key' => 'CP',
        'project_key' => 'PROJECTKEY',
        'use_ssl' => false,
        'web_path' => '/'
    }}
  end

  it "should queue a build" do
    stub_request(:post, "http://bamboo:bamboo@example.com/rest/api/latest/queue/PROJECTKEY-CP.json").to_return(:body => "{\"build_number\":2}")    
    stub_request(:get, "http://bamboo:bamboo@example.com/rest/api/latest/result/PROJECTKEY-CP-.json").to_return(:body => {"number" => 2, "lifeCycleState" => "Finished", "state" => "Successful"}.to_json)

    subject.perform(:build, @wi)     
       
    @wi['fields']['__error__'].should be_nil
  end
     
  it "should set error on error" do
  puts "t2"
    stub_request(:post, "http://bamboo:bamboo@example.com/rest/api/latest/queue/PROJECTKEY-CP.json").to_return(:body => "{\"build_number\":2}")    
    stub_request(:get, "http://bamboo:bamboo@example.com/rest/api/latest/result/PROJECTKEY-CP-.json").to_return(:body => {"number" => 2, "lifeCycleState" => "Finished", "state" => "Failed"}.to_json)
     
    subject.perform(:build, @wi)
       
    @wi['fields']['__error__'].should eql("Bamboo Job Returned Failed")
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
  #   @test_participant = MaestroDev::BambooPlugin::BambooWorker.new                              
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
  #   @test_participant = MaestroDev::BambooPlugin::BambooWorker.new                              
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
  #   @test_participant = MaestroDev::BambooPlugin::BambooWorker.new                              
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
  #   @test_participant = MaestroDev::BambooPlugin::BambooWorker.new                              
  #   @test_participant.expects(:workitem => wi.to_h).at_least_once
  # 
  #   @test_participant.build
  #   
  #   wi.fields['__error__'].should eql('Authentication Failed')    
  #     
  # end
  
end
