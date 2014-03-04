/**
 *  Summary: This class is working as a handler of trigger BatchManagerLogTrigger
 *
 *  17 Jan 2014:    Dinesh M:   Created
**/

public class BatchManagerLogTriggerHandler{
    static String errorLogStatus = 'Failed';
    static List<BatchManager_Log__c> batchManagerLogList = null;
    
    public static void onAfterInsert(List<BatchManager_Log__c> createdLogList){
        try{
            System.debug(createdLogList);
            
            if(createdLogList[0].Status__c == errorLogStatus){
                Boolean isConsecutiveLogFailed = getConsecutiveLogStatus(createdLogList[0]);     
                
                if(isConsecutiveLogFailed){
                    inactivatFailedJobs(batchManagerLogList[0].job__r);
                    sendErrorEmail(batchManagerLogList[0]);
                }
            }   
        }catch(Exception ex){
            system.debug('Custom Exception : ' + ex.getMessage());
        }
    }
    
    /********This Method identify consecutive failed status***************/
    static Boolean getConsecutiveLogStatus(BatchManager_Log__c jobLog){
        Integer noOfFailedLog = 0;
        
        batchManagerLogList = [Select Id,Status__c, job__r.Id, job__r.Active__c, job__r.Apex_Class__c, Error__c from BatchManager_Log__c WHERE Job__c =: jobLog.Job__c order by createddate Desc Limit 2];                                 
                                             
        if(batchManagerLogList != null && batchManagerLogList.size() > 1){          
            for(BatchManager_Log__c currentBatchManagerLog : batchManagerLogList){
                if(currentBatchManagerLog.Status__c.equalsIgnoreCase(errorLogStatus)){
                    noOfFailedLog++;
                }
            }
        }
        
        if(noOfFailedLog == 2){
            return true;
        }
        
        return false;
    }
    
    /******************This method inactived the Job***********************/
    static void inactivatFailedJobs(Job_Detail__c failedJob){
        failedJob.Active__c = false;
        
        update failedJob;
    }
    
    /******************Send email with error message***********************/
    static void sendErrorEmail(BatchManager_Log__c failedJob){
        String errorMessage = failedJob.job__r.Apex_Class__c + ' Has been deactivated due to consecutive failed status in Batch Manager Log. \n Error Message : ' + failedJob.Error__c;

        SchedulerManagerUtil.sendEmail(errorMessage);
    }
}