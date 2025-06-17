public class ProjectTaskAssignmentTriggerHandler 
{
    public ProjectTaskAssignmentTriggerHandler() 
    {
    }

    public static void handleUpdate()
    {
        Set<Id> resourceRequestIds = new Set<Id>();

        for( pse__Project_Task_Assignment__c pta : (List<pse__Project_Task_Assignment__c>)trigger.new )
        {
            pse__Project_Task_Assignment__c old = (pse__Project_Task_Assignment__c)trigger.oldMap.get( pta.Id );

            if( pta.pse__Assignment__c == null && 
                pta.pse__Resource_Request__c != null &&
                (   pta.pse__Project_Task_Start_Date__c != old.pse__Project_Task_Start_Date__c ||
                    pta.pse__Project_Task_End_Date__c != old.pse__Project_Task_End_Date__c ||
                    pta.pse__Estimated_Hours__c != old.pse__Estimated_Hours__c ||
                    pta.pse__Allocation_Hours__c != old.pse__Allocation_Hours__c ) 
                )
            {
                resourceRequestIds.add( pta.pse__Resource_Request__c );
            }
        }

        if( trigger.isBefore || resourceRequestIds.size() == 0 )
        {
            return;
        }

        UpdateResourceRequestsFromPTAs( resourceRequestIds );
    }

    public static void UpdateResourceRequestsFromPTAs( Set<Id> resourceRequestIds )
    {
        List<pse__Resource_Request__c> resourceRequestsToUpdate = new List<pse__Resource_Request__c>();
        for( pse__Resource_Request__c rr : 
            [Select 
                Id,
                pse__SOW_Hours__c,
                pse__Start_Date__c,
                pse__End_Date__c,
                (Select 
                    Id,
                    pse__Estimated_Hours__c,
                    pse__Allocation_Hours__c,
                    pse__Project_Task_Start_Date__c,
                    pse__Project_Task_End_Date__c
                from 
                    pse__Project_Task_Assignments__r
                where
                    pse__Assignment__c = null)
            from 
                pse__Resource_Request__c 
            where 
                Id in :resourceRequestIds and
                pse__Resource_Held__c = false and
                pse__Preferred_Schedule__c = null and
                pse__Assignment__c = null] )
        {
            decimal totalHours = 0;
            date oldestStartDate = null;
            date newestEndDate = null;

            for( pse__Project_Task_Assignment__c pta : rr.pse__Project_Task_Assignments__r )
            {
                if( pta.pse__Allocation_Hours__c != null && pta.pse__Allocation_Hours__c > 0 )
                {
                    totalHours += pta.pse__Allocation_Hours__c;
                }
                else if( pta.pse__Estimated_Hours__c != null )
                {
                    totalHours += pta.pse__Estimated_Hours__c;
                }

                if( oldestStartDate == null || oldestStartDate > pta.pse__Project_Task_Start_Date__c )
                {
                    oldestStartDate = pta.pse__Project_Task_Start_Date__c;
                }
                if( newestEndDate == null || newestEndDate < pta.pse__Project_Task_End_Date__c )
                {
                    newestEndDate = pta.pse__Project_Task_End_Date__c;
                }
            }

            // some estimated hours appear to be of the .3333333 repeating variety
            totalHours = totalHours.setScale( 2 );

            if( rr.pse__SOW_Hours__c != totalHours || rr.pse__Start_Date__c != oldestStartDate || rr.pse__End_Date__c != newestEndDate )
            {
                rr.pse__SOW_Hours__c = totalHours;
                rr.pse__Start_Date__c = oldestStartDate;
                rr.pse__End_Date__c = newestEndDate;
                resourceRequestsToUpdate.add( rr );
            }
        }

        if( resourceRequestsToUpdate.size() > 0 )
        {
            update resourceRequestsToUpdate;
        }
    }
}