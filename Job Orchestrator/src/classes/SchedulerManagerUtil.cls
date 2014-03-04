/*
Author:Amit Tripathi

Util class for Job SchedulerManager/JobScheduler class.


*/


public class SchedulerManagerUtil {
	
	
	//Get all the Active Jobs scheduled to run within next run or are due to run.  

  public static List<Job_Detail__c> getJobs(Integer size){   
    
    JobSchedulerSetting__c j= JobSchedulerSetting__c.getInstance('Default');
    
    DateTime dt=DateTime.Now();
    DateTime ndt=null;
    ndt=dt.addMinutes(Integer.ValueOf(j.Frequency__c));
    DateTime sdt=DateTime.newInstance(ndt.year(),ndt.month(),ndt.day(),ndt.hour(),ndt.minute(),ndt.second());
    String query;
    Integer count=[Select Count() from Job_Detail__c where Active__c=true and Next_Run__c<:sdt];
//If there are less slot open then put the high priority job in front.
//    
    if(size<count){    	
    
      Query='Select Name,Active__c,Apex_Class__c,Recurrence_Number__c,'
                   +'Recurrence_Unit__c,Last_Run__c,Next_Run__c,Scope_Size__c from Job_Detail__c where '
                   +'Active__c=true and Next_Run__c<:sdt order by Priority__c asc Nulls Last ';    	
    }
    else{
    	
    	 Query='Select Name,Active__c,Apex_Class__c,Recurrence_Number__c,'
                  +'Recurrence_Unit__c,Last_Run__c,Next_Run__c,Scope_Size__c from Job_Detail__c where ' 
                  +'Active__c=true and Next_Run__c<:sdt order by Next_Run__c asc ';    	
    }

    query+=' Limit '+size;
    
    return Database.Query(query);

  }
  
  //Get Next Run Time for Job.While running the Job update Next Run time as well.
  
  public static DateTime getNextRun(string unit,integer increment){
    
    system.debug('Params+++ '+unit+''+increment);
    DateTime dt=DateTime.Now();
    DateTime ndt=null;
    if(unit=='Min'){
      ndt=dt.addMinutes(increment);     
    }
    if(unit=='Hrs'){
      ndt=dt.addHours(increment);
    }
    if(unit=='Days'){
      ndt=dt.addDays(increment);
    }
    if(unit=='Months'){
      ndt=dt.addMonths(increment);
    }
    if(unit=='Weeks'){
      ndt=dt.addDays(increment*7);
    }
    system.debug('return date='+dt);
    return ndt;
    
  }
  
  // Returns cron expression for date supplied.
  
  public static String getCronExpression(DateTime dt){
    
    return ('' + dt.second() + ' ' + dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year());    
    
  }
  
  // Method to return the type of class.Used to instantiate class by name.  
  public static System.Type GetTypeForClassName(String name) {
        System.Type t;
        
        
        t = System.Type.forName(name);
        
        if ((t == null) && (!name.contains('.'))) {
          t = System.Type.forName(null,name);
        }    
//For managed package classes use nameSpace to instantiate class.       
        if ((t == null) && (name.indexOf('.')!=-1)){
          String className = name.substring(name.indexOf('.')+1);
          String nameSpace= name.substring(0,name.indexOf('.'));
          
          t = System.Type.forName(nameSpace,className);
        }
        return t;
  }
  
//Exception mails. Used to debug can be extended for other purpose. 
  public static void sendEmail(String message){
  
  	JobSchedulerSetting__c j= JobSchedulerSetting__c.getInstance('Default');  	
    
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    
    String[] toAddresses = new String[] {j.Admin_Email__c};
    
    mail.setToAddresses(toAddresses);
    mail.setSubject('Exception has occured while scheduling Job');
    mail.setPlainTextBody('Exception Details are: '+message);
    mail.setHtmlbody('Exception Details are: '+message);
    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
  }
// Return Class Name in case of managed package.  
  public static string className(String clsName){
  	
  	if(clsName.indexOf('.')!=-1){
  		clsName=clsName.substring(clsName.indexOf('.')+1).trim();
  	}
  	return clsName;  	
  	
  }
  
// Schedule JobScheduler class.Called from Job scheduler class itself.

  public static string scheduleJobScheduler(String jobName){
  	
  	JobSchedulerSetting__c j= JobSchedulerSetting__c.getInstance('Default');
  	Datetime sysTime = System.now();
    sysTime = sysTime.addminutes(Integer.ValueOf(j.Frequency__c));
    
    String schedule_Time = ' '+sysTime.second()+' '+ sysTime.minute() + ' ' + sysTime.hour() + 
            ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
            
    JobScheduler jb=new JobScheduler();
    String Jobid=System.schedule(jobName,schedule_Time,jb);
    return jobId;
  	
  	
  }

// Create JobScheduler Log.  
  public static void createJSlog(string jobId,string status,String message){
  	
  	Job_Scheduler_Log__c jbLog=new Job_Scheduler_Log__c();
  	jbLog.Run_Time__c=System.Now();
  	jbLog.Status__c=status;
  	jbLog.Description_of_Error__c=message;
  	jbLog.Job_Id__c=Jobid;
  	
  	insert jbLog;
  	
  }
// Create Message Body from Exception object.  
  public static string createExceptionMessage(Exception e){
  	
  	String LineNumber='Line Number='+e.getLineNumber();
    String stackTrace=' /n Stack Trace='+e.getStackTraceString();
    String cause='Cause=='+e.getMessage();
    String eType='Type='+e.getTypeName();
    String message= LineNUmber+ '/n' + stackTrace+'/n'+cause+'/n'+etype;
    
    return message;
  }

// get all running Jobs information.  
  public static List<AsyncApexJob>getAllRunningJobs(){
  	
  	List<AsyncApexJob> runningJobs=new List<AsyncApexJob>();
  	runningJobs=[SELECT Id,ApexClassId,ApexClass.Name FROM AsyncApexJob WHERE Status in ('Queued','Processing','Preparing')];
  	
  	return runningJobs;		
  	
  }
// Instantiate batch Log.  
  Public static BatchManager_Log__c createjobLog(Id jobId,Id batchId){
  	
  	 BatchManager_Log__c bmLog= new BatchManager_Log__c();
  	 bmLog.Job__c=jobId;
     bmLog.Trigger_Job_Id__c=batchid;
     bmLog.Status__c='Running';
     
     
     return bmLog;  	 
  	 
  }
//Returns Logs in Running status.  
  public static List<BatchManager_Log__c> getBatchLogs(){
  	
  	List<BatchManager_Log__c> bmLogs=new List<BatchManager_Log__c>();
  	bmLogs=[Select Id,Trigger_Job_Id__c,Status__c,Job__r.Last_Run__c,Job__r.Apex_Class__c,
            Error__c,Completion_Date__c from BatchManager_Log__c 
            where Status__c!='Completed' AND status__c!='Aborted' AND Trigger_Job_Id__c !='' AND Trigger_Job_Id__c!=Null];
    
    return bmLogs;
  }

// Returns completed JObs for status updated in logs.  
  public static List<AsyncApexJob> getcompletedJobInformation(Set<Id> batchIds,Set <String> classNames){
  	
  	List<AsyncApexJob> listAsyncJob=new List<AsyncApexJob>();
  	listAsyncJob=[SELECT Id, CreatedDate, CreatedById, JobType, ApexClassId,ApexClass.Name, Status, JobItemsProcessed, 
                  TotalJobItems, NumberOfErrors, CompletedDate, MethodName, ExtendedStatus, ParentJobId,
                  LastProcessed, LastProcessedOffset from AsyncApexJob where Id In:batchIds Or ApexClass.Name In:classNames order by CreatedDate Desc];
    return listAsyncJob;	
  	
  	
  }

// Method to update Logs list.  
  Public static void updateJobLog(AsyncApexJob job,BatchManager_Log__c bmLog){
  	
  	bmLog.Completion_Date__c=job.CompletedDate;
    bmLog.Status__c=job.Status;
    bmLog.Error__c=job.ExtendedStatus;
   
  	
  }

// Method to delete Logs.  
  /*public static void delLogs() {
  	
  	JobSchedulerSetting__c js= JobSchedulerSetting__c.getInstance('Default');
  	
  	DateTime dt= system.now().addDays(-Integer.ValueOf(js.Days__c));
  	
  	List<Job_Scheduler_Log__c> delJslog=new List<Job_Scheduler_Log__c>();
    List<BatchManager_Log__c> delBmlog=new List<BatchManager_Log__c>();
    
    delJslog= [Select Id from Job_Scheduler_Log__c where Run_Time__c<:dt];
    delBmlog= [Select Id from BatchManager_Log__c where createdDate<:dt];
    
    if(delJslog.size()>0)
		  delete delJslog;
		
		if(delBmlog.size()>0)		
		delete delBmlog;
  	
  }*/
  
  
  

}