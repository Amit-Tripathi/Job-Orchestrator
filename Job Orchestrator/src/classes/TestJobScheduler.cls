/**
 * 16 Jan 2014:     Dinesh M:   Created
**/

@isTest
public class TestJobScheduler{  
	static ID batchJobID = null;
    static ID scheduleJobID = null;
    static Integer noOfBatchToHandle = 10;
    static Integer maxConcurrentBatchLimit = 5;
    static List<Job_Detail__c> jobDetailList = null;
    static String COMPLETED = 'Completed';
    static String PROCESSING = 'Processing';
    static String RUNNING = 'Running';
    static String ABORTED = 'Aborted';
    static String SUCCESS = 'Success';
    static String FAILED = 'Failed';    
    static String TEST_BATCH_JOB_NAME = 'TestBatchJobName';
    static String TEST_SCHEDULE_JOB_NAME = 'TestScheduleJobName';
    static String TEST_BATCH_CLASS = 'TestBatchClass';
    static String TEST_SCHEDULE_CLASS = 'TestScheduleClass';
    static String JOB_SCHEDULER_SETTING_NAME = 'Default';   
    static String EMAIL = 'amit.tripathi@morganstanley.com';
    static String JOB_MANAGER_NAME = 'JobManager';  
    static String RECURRENCE_UNIT_IN_MIN = 'Min';
    static String RECURRENCE_UNIT_IN_HR = 'Hrs';
    static String RECURRENCE_UNIT_IN_DAY = 'Days';
    static String RECURRENCE_UNIT_IN_MONTH = 'Months';
    static String RECURRENCE_UNIT_IN_WEEK = 'Weeks';
    static Integer RECURRENCE_NUMBER = 5;
    static Integer SCOPE_SIZE = 3; 
    static Integer JOB_MANAGER_FREQUENCY = 5;
    
    /**************Keep Run Time of batches Different******************/
    static testMethod void runSeperateBatches(){
        insertCusttomSetting();
        insertBatchesDetail(false);     
        
        runJobManager();        
        checkCommonAssert();
    }
    
    /**************Keep Run Time of all batches same*******************/
    static testMethod void runConcurrentBatches(){
        insertCusttomSetting();
        insertBatchesDetail(true);  
        
        runJobManager();        
        checkCommonAssert();        
    }
    
    /**************Abort batch job if it fails consecutively***********/
    static testMethod void abortConsecutiveFailedJob(){
        insertCusttomSetting();
        insertBatchesDetail(false);
        //insertBatchManagerLog(false, false, PROCESSING);
        insertBatchManagerLog(false, false, FAILED);
        insertBatchManagerLog(false, false, FAILED);
        insertJobSchedulerLog(FAILED, 0);  
        insertJobSchedulerLog(FAILED, JOB_MANAGER_FREQUENCY); 
        
        runJobManager();
    }
    
    /***************Run batch having some namespace********************/
    static testMethod void runBatchWithNamespace(){
        insertCusttomSetting();
        insertJobDetailWithNamespace(); 
        
        runJobManager();
        checkCommonAssert();
    }
    
    /*******Run batch having Invalide Job ID in Batchmanager Log*******/
    static testMethod void runBatchWithInvalidID(){
        insertCusttomSetting();
        insertBatchesDetail(false);
        insertBatchManagerLog(true, false, PROCESSING);
        
        runJobManager();
        checkCommonAssert();
    }
    
    /******Run batch having Incorrect Job ID in Batchmanager Log*******/
    static testMethod void runBatchWithIncorrectID(){
        insertCusttomSetting();
        insertBatchesDetail(false);
        insertBatchManagerLog(true, true, PROCESSING);
        
        runJobManager();
        checkCommonAssert();
    }
    
    /***************Private static methods*****************************/
    static void runJobManager(){
        Datetime sysTime = System.now().addminutes(1);
        String schedule_Time = ' '+sysTime.second()+' '+ sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
        
        Test.startTest();
        system.schedule(JOB_MANAGER_NAME, schedule_Time, new JobScheduler());
        Test.stopTest();
    }
    
    static void checkCommonAssert(){
        Integer noOfScheduledJobs = [SELECT COUNT() FROM CronTrigger];
        System.assert(noOfScheduledJobs <= maxConcurrentBatchLimit);
        
        Integer jogLogSize = [SELECT COUNT() FROM Job_Scheduler_Log__c];
        System.assertEquals(jogLogSize, 1);
    }
    
    static void insertBatchesDetail(Boolean isConcurrentBatch){         
        jobDetailList = new  List<Job_Detail__c>();
        
        for(Integer i = 0 ; i < noOfBatchToHandle ; i++){
            Job_Detail__c currentBatchJobDetail = new Job_Detail__c();          
            currentBatchJobDetail.Name = TEST_BATCH_JOB_NAME + i;
            currentBatchJobDetail.Apex_Class__c = TEST_BATCH_CLASS;
            currentBatchJobDetail.Next_Run__c = isConcurrentBatch ? system.now() : system.now().addMinutes(i*10);
            currentBatchJobDetail.Recurrence_Unit__c = (i/2 == 0) ? RECURRENCE_UNIT_IN_MIN : RECURRENCE_UNIT_IN_DAY;
            currentBatchJobDetail.Recurrence_Number__c = RECURRENCE_NUMBER;
            currentBatchJobDetail.Scope_Size__c = SCOPE_SIZE;
            currentBatchJobDetail.Active__c = true;
            
            jobDetailList.add(currentBatchJobDetail);
            
            Job_Detail__c currentScheduleJobDetail = new Job_Detail__c();           
            currentScheduleJobDetail.Name = TEST_SCHEDULE_JOB_NAME + i;
            currentScheduleJobDetail.Apex_Class__c = TEST_SCHEDULE_CLASS;
            currentScheduleJobDetail.Next_Run__c = isConcurrentBatch ? system.now() : system.now().addMinutes(i*3);
            currentScheduleJobDetail.Recurrence_Unit__c = (i/2 == 0) ? RECURRENCE_UNIT_IN_HR : RECURRENCE_UNIT_IN_MONTH;
            currentScheduleJobDetail.Recurrence_Number__c = RECURRENCE_NUMBER;
            currentScheduleJobDetail.Scope_Size__c = SCOPE_SIZE;
            currentScheduleJobDetail.Active__c = true;
            
            jobDetailList.add(currentScheduleJobDetail);
        }
        
        insert jobDetailList;       
    } 
    
    static void insertCusttomSetting(){
        JobSchedulerSetting__c jobSchedulerSetting = new JobSchedulerSetting__c();
        jobSchedulerSetting.Name = JOB_SCHEDULER_SETTING_NAME;
        jobSchedulerSetting.Admin_Email__c = EMAIL;
        jobSchedulerSetting.Days__c = 7;
        jobSchedulerSetting.Frequency__c = JOB_MANAGER_FREQUENCY;
        
        upsert jobSchedulerSetting;
    }
    
    static void insertBatchManagerLog(Boolean isInvalidID, Boolean isIncorrectID, String status){
    	if(batchJobID == null && scheduleJobID == null){
	        batchJobID = Database.executeBatch(new TestBatchClass(),3);
	        
	        Datetime sysTime = System.now().addminutes(1);
	        String schedule_Time = ' '+sysTime.second()+' '+ sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
	        
	        scheduleJobID = system.schedule('TestScheduleClass', schedule_Time, new TestScheduleClass());
    	}
        
        List<BatchManager_Log__c> batchManagerLogList = new List<BatchManager_Log__c>();        
        
        for(Job_Detail__c currentJobDetail : jobDetailList){
            BatchManager_Log__c currentManagerLog = new BatchManager_Log__c();
            currentManagerLog.Status__c = status;
            currentManagerLog.Trigger_Job_Id__c = isInvalidID ? (isIncorrectID ? 'a5PQ0000000Cbkd' : 'InvalidID') : ((currentJobDetail.Apex_Class__c == TEST_SCHEDULE_CLASS) ? scheduleJobID : batchJobID);
            currentManagerLog.Job__c = currentJobDetail.Id;
            
            batchManagerLogList.add(currentManagerLog);
        }       
        
        insert batchManagerLogList;
    }   
    
    static void insertJobSchedulerLog(String status, Integer runTime){
        Job_Scheduler_Log__c currentJobLog = new Job_Scheduler_Log__c();
        currentJobLog.Status__c = status;
        currentJobLog.Run_Time__c = System.now().addMinutes(-runTime);
        
        insert currentJobLog;
    } 
    
    static void insertJobDetailWithNamespace(){
        Job_Detail__c currentBatchJobDetail = new Job_Detail__c();          
        currentBatchJobDetail.Name = TEST_BATCH_JOB_NAME;
        currentBatchJobDetail.Apex_Class__c = 'Namespace.TestBatch';
        currentBatchJobDetail.Next_Run__c = system.now();
        currentBatchJobDetail.Recurrence_Unit__c = RECURRENCE_UNIT_IN_WEEK;
        currentBatchJobDetail.Recurrence_Number__c = RECURRENCE_NUMBER;
        currentBatchJobDetail.Scope_Size__c = SCOPE_SIZE;
        currentBatchJobDetail.Active__c = true;
        
        insert currentBatchJobDetail;
    }
}