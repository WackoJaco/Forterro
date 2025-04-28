@RestResource(urlMapping='/tasktimeapi/tasktimetest/resetsplits/*')
global with sharing class TaskTimeTestAPI 
{
    @HttpPost
    global static void HandlePost( string BUCode )
    {
        List<Task_Time_Split__c> splits = [Select Id, Sync_Status__c, SyncDate__c, ErrorMessage__c from Task_Time_Split__c where
            Task_Time__r.pse__Timecard__r.pse__Project__r.pse__Region__r.BU_Code__c = :BUCode and Sync_Status__c != 'New'];

        for( Task_Time_Split__c split : splits )
        {
            split.Sync_Status__c = 'New';
            split.SyncDate__c = null;
            split.ErrorMessage__c = '';
        }

        update splits;

        RestAPIHelper.SetRestReturn( splits.size(), true );
    }
}