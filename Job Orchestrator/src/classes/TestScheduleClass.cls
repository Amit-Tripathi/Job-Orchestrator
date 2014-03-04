/**
 *	Summary: This class is created to test Batch Orchestration (CRMGPS 4280).
 *	16 Jan 2014:		Dinesh M:	Created
**/

global class TestScheduleClass implements Schedulable{     
	global void execute(SchedulableContext sc) {
		Database.executeBatch(new TestBatchClass(), 3);
	}
}