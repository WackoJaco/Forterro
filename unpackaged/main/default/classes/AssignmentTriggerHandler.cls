public class AssignmentTriggerHandler 
{
    public AssignmentTriggerHandler() 
    {
    }

    private static Set<Id> ptIdsToRecalculate = new Set<Id>();

    public static void handleDelete()
    {
        if( trigger.isBefore )
        {
            ptIdsToRecalculate = new Set<Id>();
            
            // figure out the project tasks to recalculate before the links are deleted
            Set<Id> assignmentIds = new Set<Id>();
            for( pse__Assignment__c assignment : (List<pse__Assignment__c>)trigger.old )
            {
                assignmentIds.add( assignment.Id );
            }

            for( pse__Project_Task_Assignment__c pta : 
                [Select 
                    Id, 
                    pse__Project_Task__c 
                from 
                    pse__Project_Task_Assignment__c 
                where 
                    pse__Assignment__c in :assignmentIds] )
            {
                ptIdsToRecalculate.add( pta.pse__Project_Task__c );
            }
        }
        else
        {
            // now do the actual recalculation of the project tasks
            List<pse__Project_Task__c> ptsToUpdate = new List<pse__Project_Task__c>();
            for( pse__Project_Task__c pt : 
                [Select 
                    Id,
                    Number_of_Resource_Assignments__c,
                    (Select Id from pse__Project_Task_Assignments__r where pse__Assignment__c != null)
                from 
                    pse__Project_Task__c 
                where 
                    Id in :ptIdsToRecalculate] )
            {
                integer assignments = pt.pse__Project_Task_Assignments__r.size();
                if( pt.Number_of_Resource_Assignments__c != assignments )
                {
                    pt.Number_of_Resource_Assignments__c = assignments;
                    ptsToUpdate.add( pt );
                }
            }

            if( ptsToUpdate.size() > 0 )
            {
                update ptsToUpdate;
            }
        }
    }
}