/*
Schedulebale class to iterate over Job Object and retrieve the information
regarding Jobs to be scheduled.It quries ApexAsync Object to check how
many batches are currntly scheduled if there is no slot open, it updates
the Next Run Time for the Job and schedules it self to run after 5 min.

To run from dev console:

Datetime sysTime = System.now().addminutes(1);
String schedule_Time = ' '+sysTime.second()+' '+ sysTime.minute() + ' ' + sysTime.hour() + 
            ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
system.schedule('JobManager', schedule_Time, new JobScheduler());

*/

global class JobScheduler implements schedulable {
	
	
//Schedulable Context.
	global void execute(SchedulableContext SC){
		
		JobSchedulerManager manager=new JobSchedulerManager();

		try{
			
		//Query Existing Jobs,previous scheduled jobs and update current status on logs.
			manager.updateLogs();
			
		    List<Job_Detail__c> activeJob=[Select Id from Job_Detail__c where Active__c=true limit 1];
		
		    Map<Id,AsyncApexJob> runningBatchApexJobs =new Map<Id,AsyncApexJob>([SELECT Id,ApexClassId,ApexClass.Name FROM AsyncApexJob WHERE
		                                                                      JobType='BatchApex' AND Status in ('Queued','Processing','Preparing')]);
		    if(runningBatchApexJobs.size()!=5 && !activeJob.isEmpty())
		     {
		
		       manager.processJobs(runningBatchApexJobs.values());       
		
		     } 
		      
		     String jobId=SchedulerManagerUtil.scheduleJobScheduler('ReScheduleJobSchedulerAt-'+system.now());
		        
		//Create JSlog for this instance.
		     SchedulerManagerUtil.createJSlog(jobId,'Success','');
		
		     system.abortJob(sc.getTriggerId());      

		}
		catch(Exception e) {

			
			String message=SchedulerManagerUtil.createExceptionMessage(e);
			
			SchedulerManagerUtil.sendEmail(string.valueof(message));
			
			system.debug('Exception'+e);
			
			system.abortJob(sc.getTriggerId());
			
			String jobId=SchedulerManagerUtil.scheduleJobScheduler('RetryingJobSchedulerAt-'+system.now());
//Create JSlog for this instance.			
			SchedulerManagerUtil.createJSlog(jobId,'Failed',message);
			 

		}
			

	}
	

}