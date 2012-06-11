require 'spec_helper'


# {"planKey"=>"CENTREPOINT-CP",
#    "buildNumber"=>4,
#    "buildResultKey"=>"CENTREPOINT-CP-4",
#    "triggerReason"=>"Manual build",
#    "link"=>
#     {"href"=>"http://127.0.0.1:8085/rest/api/latest/result/CENTREPOINT-CP-4",
#      "rel"=>"self"}}

# {"expand":"changes,metadata,vcsRevisions,artifacts,comments,labels,jiraIssues,stages","link":{"href":"http://127.0.0.1:8085/rest/api/latest/result/CENTREPOINT-CP-4","rel":"self"},"planName":"CP","projectName":"Centrepoint","key":"CENTREPOINT-CP-4","state":"Unknown","lifeCycleState":"InProgress","number":4,"id":851969,"buildStartedTime":"2011-11-10T16:52:42.892+01:00","prettyBuildStartedTime":"Thu, 10 Nov, 04:52 PM","buildDurationInSeconds":0,"buildDuration":0,"buildDurationDescription":"Unknown","buildRelativeTime":"","vcsRevisionKey":"2bcf66b4fdd4bb44c6bf48bc37761bf6271fe937","vcsRevisions":{"start-index":0,"max-result":1,"size":1},"continuable":false,"restartable":false,"buildReason":"Manual build by <a href=\"http://0:0:0:0:0:0:0:1:8085/browse/user/bamboo\">bamboo</a>","artifacts":{"start-index":0,"max-result":0,"size":0},"comments":{"start-index":0,"max-result":0,"size":0},"labels":{"start-index":0,"max-result":0,"size":0},"jiraIssues":{"start-index":0,"max-result":0,"size":0},"stages":{"start-index":0,"max-result":1,"size":1},"changes":{"start-index":0,"max-result":0,"size":0},"metadata":{"start-index":0,"max-result":1,"size":1},"progress":{"isValid":true,"isUnderAverageTime":false,"percentageCompleted":1.2251635206855696,"percentageCompletedPretty":"122%","prettyTimeRemaining":"13 secs slower than usual","prettyTimeRemainingLong":"13 seconds slower than usual","averageBuildDuration":61613,"prettyAverageBuildDuration":"1 min","buildTime":75487,"prettyBuildTime":"1 min","startedTime":"10 Nov 2011, 4:52:42 PM","startedTimeFormatted":"2011-11-10T16:52:42","prettyStartedTime":"1 minute ago"}}
# {"expand":"changes,metadata,vcsRevisions,artifacts,comments,labels,jiraIssues,stages","link":{"href":"http://127.0.0.1:8085/rest/api/latest/result/CENTREPOINT-CP-4","rel":"self"},"planName":"CP","projectName":"Centrepoint","key":"CENTREPOINT-CP-4","state":"Failed","lifeCycleState":"Finished","number":4,"id":851969,"buildStartedTime":"2011-11-10T16:52:42.892+01:00","prettyBuildStartedTime":"Thu, 10 Nov, 04:52 PM","buildCompletedTime":"2011-11-10T17:02:20.442+01:00","prettyBuildCompletedTime":"Thu, 10 Nov, 05:02 PM","buildDurationInSeconds":577,"buildDuration":577550,"buildDurationDescription":"9 minutes","buildRelativeTime":"8 minutes ago","vcsRevisionKey":"2bcf66b4fdd4bb44c6bf48bc37761bf6271fe937","vcsRevisions":{"start-index":0,"max-result":1,"size":1},"buildTestSummary":"No tests found","successfulTestCount":0,"failedTestCount":0,"continuable":false,"restartable":true,"buildReason":"Manual build by <a href=\"http://0:0:0:0:0:0:0:1:8085/browse/user/bamboo\">bamboo</a>","artifacts":{"start-index":0,"max-result":0,"size":0},"comments":{"start-index":0,"max-result":0,"size":0},"labels":{"start-index":0,"max-result":0,"size":0},"jiraIssues":{"start-index":0,"max-result":0,"size":0},"stages":{"start-index":0,"max-result":1,"size":1},"changes":{"start-index":0,"max-result":0,"size":0},"metadata":{"start-index":0,"max-result":1,"size":1}}

# http://localhost:8085/download/CENTREPOINT-CP-JOB1/build_logs/CENTREPOINT-CP-JOB1-7.log

describe MaestroDev::BambooWorker do
  before :all do
    @test_participant = MaestroDev::BambooWorker.new
  end
  
  it "should queue a build" do
    wi = Ruote::Workitem.new({'fields' => { 
                              'host' => '127.0.0.1',
                              'port' => '8085',
                              'username' => 'bamboo',
                              'password' => 'bamboo',
                              'plan' => 'CP',
                              'project' => 'Centrepoint',
                              'use_ssl' => false,
                              'web_path' => '/'
                              }})
                              
    @test_participant.expects(:workitem => wi.to_h).at_least_once
    @test_participant.expects(:connect => true).at_least_once
  
    
    @test_participant.expects(:queue_plan)
    @test_participant.expects(:get_result_log)
    state = mock(:state => "Hello", :url => "google.com")
    @test_participant.expects(:wait_for_job => state)
  
    @test_participant.build
    
    wi.fields['__error__'].should eql('')
  end
  
  it "should set error on error" do
    wi = Ruote::Workitem.new({'fields' => { 
                              'host' => 'google.com',
                              'port' => '8085',
                              'username' => 'bamboo',
                              'password' => 'bamboo',
                              'plan' => 'CP',
                              'project' => 'Centrepoint',
                              'use_ssl' => false
                              }})
    @test_participant.expects(:workitem => wi.to_h).at_least_once

    @test_participant.expects(:connect => false)
    
    # expect {@test_participant.connect}.to raise_error
    @test_participant.build
  
    wi.fields['__error__'].should eql("Connection refused - Connection refused")
  end
  
end
