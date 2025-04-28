trigger ProjectTask on pse__Project_Task__c (after update) 
{
    ProjectTaskHelper.TriggerHandler();
}