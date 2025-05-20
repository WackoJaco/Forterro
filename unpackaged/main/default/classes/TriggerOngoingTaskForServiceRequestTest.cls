@isTest
public class TriggerOngoingTaskForServiceRequestTest 
{
    @isTest static void MainTest()
    {
        ffps_forterro__ServiceRequest__c req = new ffps_forterro__ServiceRequest__c(
            Trigger_Ongoing_Task__c = false,
            ffps_forterro__Type__c = 'SupportBillable'
        );
        insert req;

        Test.startTest();

        TriggerOngoingTaskForServiceRequestBatch batch = new TriggerOngoingTaskForServiceRequestBatch();
        Database.executeBatch( batch, 1 );

        Test.stopTest();

        req = [Select Id, Trigger_Ongoing_Task__c from ffps_forterro__ServiceRequest__c where Id = :req.Id];
        system.assert( req.Trigger_Ongoing_Task__c == true );
    }

    @isTest static void ScheduleTest()
    {
        TriggerOngoingTaskForServiceRequestBatch.scheduleEveryFiveMinutes();
    }
}