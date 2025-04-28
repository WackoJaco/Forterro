trigger TaskTime on pse__Task_Time__c (after insert, after update, before delete) 
{
    TaskTimeHelper.TriggerHandler();
}