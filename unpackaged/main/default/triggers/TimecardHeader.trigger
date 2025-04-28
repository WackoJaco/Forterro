trigger TimecardHeader on pse__Timecard_Header__c (before delete, after update) 
{
    TaskTimeHelper.TimecardHeaderTriggerHandler();
}