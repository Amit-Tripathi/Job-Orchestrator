/**
 *	Summary: This class is created to test Batch Orchestration (CRMGPS 4280).
 *	16 Jan 2014:		Dinesh M:	Created
**/

global class TestBatchClass implements Database.Batchable<SObject>{
	global Database.QueryLocator start(Database.BatchableContext bc) {
		String query = 'SELECT ID FROM USER LIMIT 1';
		return database.getQueryLocator(query);
	}
     
     global void execute(Database.BatchableContext BC,  List<sObject> userLstobjectList){}
     
     global void finish(Database.BatchableContext BC){}
}