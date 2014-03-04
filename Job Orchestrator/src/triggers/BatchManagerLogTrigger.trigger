/**
 *  Summary:
 *  This trigger has below functionalities
 *      1. It will abort job in case of consecutive errors in batch manager log.
 *
 *  17 Jan 2014:    Dinesh M:   Created
**/

trigger BatchManagerLogTrigger on BatchManager_Log__c (After Insert) {
    /*TODO: Implement trigger switch*/
    
    if(Trigger.isAfter && Trigger.isInsert ){
        BatchManagerLogTriggerHandler.onAfterInsert(trigger.new);
    }
}