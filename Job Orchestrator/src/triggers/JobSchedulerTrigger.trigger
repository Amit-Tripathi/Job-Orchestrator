/**
 *  Summary:
 *  This trigger has below functionalities
 *      1. It will abort job in case of consecutive errors.
 *
 *  09 Jan 2014:    Dinesh M:   Created
**/

trigger JobSchedulerTrigger on Job_Scheduler_Log__c (Before Insert,Before Update) {
    /*TODO: Implement trigger switch*/
    
    if(trigger.isBefore ){
        JobSchedulerTriggerHandler.onAfterInsert(trigger.new);
    }
}