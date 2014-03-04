/**
 *	Summary: This class is working as a handler of trigger JobSchedulerTrigger
 *
 *	09 Jan 2014:	Dinesh M:	Created
**/

public with sharing class JobSchedulerTriggerHandler {
	static String errorLogStatus = 'Failed';	
	
	public static void onAfterInsert(List<Job_Scheduler_Log__c> createdLogList){
	
	System.debug(createdLogList);
		if(createdLogList[0].Status__c==errorLogStatus){
		
		
		
			JobSchedulerSetting__c j= JobSchedulerSetting__c.getInstance('Default');			
			Integer freq=Integer.ValueOf(j.Frequency__c);
			
			//DateTime dt=createdLogList[0].Run_Time__c.addMinutes(-freq);
			List<Job_Scheduler_Log__c> jLog=[Select Id,Status__c,Run_Time__c from Job_Scheduler_Log__c where Status__c=:errorLogStatus
								  			 order by  Run_Time__c Desc Limit 1];
					  			 
								  			 
			if(jLog.size()>0 && createdLogList[0].Run_Time__c.minute()-jLog[0].Run_Time__c.minute()==freq){
			
				System.debug('Aborting Job'==createdLogList[0].Job_Id__c);
				
				system.abortJob(createdLogList[0].Job_Id__c);			
			
			
			}
		
		}	
		
	}
	
}