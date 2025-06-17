trigger ProjectTaskAssignment on pse__Project_Task_Assignment__c (after update) 
{
    ProjectTaskAssignmentTriggerHandler.handleUpdate();
}