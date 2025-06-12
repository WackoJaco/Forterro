trigger AssignmentTrigger on pse__Assignment__c (before delete, after delete) 
{
    AssignmentTriggerHandler.handleDelete();
}