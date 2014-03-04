/*
Methods: ProcessJob: Read object and properties and run jobs, also checks if it is from managed package by checking "." in class name.

If so runs any schedule jobs with NOW() parameter and abort it later in updateLogs metod if status is "Deleted" in Cron Trigger Object.




*/

public class JobSchedulerManager {
	
// Process batches, called from Scheduler.
// Schedule batch,update Next Run,Create Logs
	
	public void processJobs(List<AsyncApexJob> runningApexJobs){
		
		List<Job_Detail__c> jobs=SchedulerManagerUtil.getJobs(5-runningApexJobs.size());
		
		List<Job_Detail__c> updateJobs=new List<Job_Detail__c>();
		
		List<BatchManager_Log__c> logs= new List<BatchManager_Log__c>();
		
		Set<String> classNames=new Set<String>();
		
		for(AsyncApexJob a:SchedulerManagerUtil.getAllRunningJobs()){			
			
			classNames.add(a.ApexClass.Name.trim().toUpperCase());
			
		}
		
		for(Job_Detail__c j:jobs){
			
		
			//Condtion to check if there is a class which is already scheduled then it should not be scheduled
		
			if(classNames.contains(SchedulerManagerUtil.className(j.Apex_Class__c).toUpperCase())){
				
				j.Next_Run__c=SchedulerManagerUtil.getNextRun(j.Recurrence_Unit__c,Integer.valueof(j.Recurrence_Number__c));
				updateJobs.add(j);

				continue;
			}
			
		  	Schedulable cls;
			Id batchid;
			system.Type t;
				
			try{
				// Instantiate class from name to be executed.
				t=SchedulerManagerUtil.GetTypeForClassName(j.Apex_Class__c);
				//batchable context if not will throw a system.type exception   
				batchid=database.executebatch((Database.Batchable<sObject>)t.newInstance(),integer.valueof(j.Scope_Size__c));
				BatchManager_Log__c bmLog=SchedulerManagerUtil.createjobLog(j.id,batchid);
				logs.add(bmLog);	
				
	      
			  }  
			
			// If exception is of type System.Type then class must be schedulable.
			catch(Exception e){
				try{
					if(e.getTypeName()=='System.TypeException')
					{
						t=SchedulerManagerUtil.GetTypeForClassName(j.Apex_Class__c);
						cls=(Schedulable)t.newinstance();
						system.debug('New Class Schedulable='+cls);
						batchid=System.schedule(j.Name,SchedulerManagerUtil.getCronExpression(DateTime.now().addMinutes(1)),cls);
						BatchManager_Log__c bmLog=SchedulerManagerUtil.createjobLog(j.id,batchid);
            			logs.add(bmLog);
					}
					else{
						String message=SchedulerManagerUtil.createExceptionMessage(e);
						
						SchedulerManagerUtil.sendEmail(message);
					}
				}
				catch(Exception ex){
					
					String message=SchedulerManagerUtil.createExceptionMessage(ex);
        
          			SchedulerManagerUtil.sendEmail(message);
				}

				}         

	      j.Next_Run__c=SchedulerManagerUtil.getNextRun(j.Recurrence_Unit__c,Integer.valueof(j.Recurrence_Number__c));
	      j.Last_Run__c=system.now();
	      updateJobs.add(j);	
			
		}
		  update updateJobs;
		  insert logs;
		
	}

//Method to update Logs status,Last Run time of Jobs and other information.
//This method will run always irrespective of how many batches are running in parallel.
 	
	public void updateLogs(){
		
		//Get the List of Logs to be updated.
		List<BatchManager_Log__c> bmLogs=new List<BatchManager_Log__c>();
		
		bmLogs=SchedulerManagerUtil.getBatchLogs();
		
		Set<Id> abortJobs= new Set<id>();
		
		if(bmLogs.size()>0){
			
			Set<Id> batchIds= new Set<Id>();
			
			Set <String> classNames= new Set<String>();
			
			for(BatchManager_Log__c bml:bmLogs){
	
				batchIds.add(bml.Trigger_Job_Id__c);
				
				classNames.add(SchedulerManagerUtil.className(bml.Job__r.Apex_Class__c));

			}
			//Map to hold Batch Job information.
			List<AsyncApexJob> listAsyncJob=new List<AsyncApexJob>();
			
			listAsyncJob=SchedulerManagerUtil.getcompletedJobInformation(batchIds,classNames);
                                     
                                     
			//Map with Key as job id. To be used for batch jobs.
			Map<Id,AsyncApexJob> mapAsyncJob=new Map<Id,AsyncApexJob>(listAsyncJob);
			
			//Map to Hold Scheduled Job information with Key as class Name. To be used to update scheduled jobs.

			
			Map<String,AsyncApexJob> mapClasstoJob=new Map<String,AsyncApexJob>();
			String classNamefrKey;
			
			for(AsyncApexJob a:listAsyncJob){

				if(!mapClasstoJob.containsKey(a.ApexClass.Name.trim().toUpperCase())){
					
					system.debug('Prev Class Name='+a.ApexClass.Name);
					
					mapClasstoJob.put(a.ApexClass.Name.trim().toUpperCase(),a);
					
					system.debug('Map Key for class='+a.ApexClass.Name.trim().toUpperCase());
					system.debug('Map value===='+mapClasstoJob.get(a.ApexClass.Name.trim().toUpperCase()));
					system.debug('value in List='+a);
					
				}
							
			}
			
			system.debug('Map Size==='+mapAsyncJob.size());
			
			system.debug('CronMap Size==='+mapClasstoJob.size());
			
			
			for(Integer I=0;i<bmLogs.size();i++){
				
				System.Debug('++++++'+bmLogs[i]);
				if(mapAsyncJob.containsKey(bmLogs[i].Trigger_Job_Id__c)){
					
					AsyncApexJob job=mapAsyncJob.get(bmLogs[i].Trigger_Job_Id__c);
					SchedulerManagerUtil.updateJobLog(job,bmLogs[i]);

				}
				// Below portion caters to update logs for scheduled job.
				else{
					//If class name contains "." then it is from managed package.
					
					classNamefrKey=SchedulerManagerUtil.className(bmLogs[i].Job__r.Apex_Class__c).toUppercase();
					system.debug('classNamefrKey==='+classnamefrKey);

					//Get the ApexAsyncJob object from the map.
					AsyncApexJob j=mapClasstoJob.get(classNamefrKey);
					if(j!=null){
					  	system.debug('Class Name for Log='+bmLogs[i].Job__r.Apex_Class__c.trim().toUpperCase());
	          			system.debug('Async Object=='+j);
	          			SchedulerManagerUtil.updateJobLog(j,bmLogs[i]);
	          			abortJobs.add(bmLogs[i].Trigger_Job_Id__c);
					}
     
				}				
			}
			  // Abort jobs which are finished but still cluttered in Cron Table.
			  if(abortJobs.size()>0){
			   for(crontrigger c:[Select Id,State from crontrigger where Id in:abortJobs ]){
          
		          if(c.state=='DELETED'){
		            system.abortJob(c.Id);
		            }
          
          		}	
			  }
	
		}
		update bmLogs;

	}
	
//Delete Logs.Currently Not being Used.
	/*public void deleteLogs(){
		
		SchedulerManagerUtil.delLogs();
		
	}*/

}