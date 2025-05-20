public class RoleBudgetHelper 
{
    public static Set<Id> GetMaxedOutTasks( Set<Id> taskIds )
    {
        List<pse__Project_Task_Assignment__c> ptas = new List<pse__Project_Task_Assignment__c>();
        Set<Id> roleBudgetIds = new Set<Id>();

        for( pse__Project_Task_Assignment__c pta : 
            [Select 
                Id, 
                pse__Assignment__c,
                pse__Resource_Role__c,
                Role_Budget__c,
                pse__Project_Task__c
            from 
                pse__Project_Task_Assignment__c 
            where 
                pse__Project_Task__c in :taskIds] )
        {
            ptas.add( pta );

            if( pta.Role_Budget__c != null )
            {
                roleBudgetIds.add( pta.Role_Budget__c );
            }
        }

        Set<Id> maxedRoleBudgetIds = new Set<Id>();

        for( Role_Budget__c roleBudget : 
            [Select 
                Id,
                Hours_Budget__c,
                (Select Id, pse__Estimated_Hours__c from Project_Task_Assignments__r) 
            from 
                Role_Budget__c 
            where 
                Id in :roleBudgetIds] )
        {
            decimal totalEstimatedHours = 0.0;
            for( pse__Project_Task_Assignment__c pta : roleBudget.Project_Task_Assignments__r )
            {
                if( pta.pse__Estimated_Hours__c != null )
                {
                    totalEstimatedHours += pta.pse__Estimated_Hours__c;
                }
            }

            if( totalEstimatedHours > roleBudget.Hours_Budget__c )
            {
                maxedRoleBudgetIds.add( roleBudget.Id );
            }
        }

        Set<Id> maxedOutTaskIds = new Set<Id>();

        for( pse__Project_Task_Assignment__c pta : ptas )
        {
            if( maxedRoleBudgetIds.contains( pta.Role_Budget__c ) )
            {
                maxedOutTaskIds.add( pta.pse__Project_Task__c );
            }
        }

        return maxedOutTaskIds;
    }
}