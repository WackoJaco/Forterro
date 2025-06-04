public class ProjectTaskHelper 
{
    public static void TriggerHandler()
    {
        Map<Id,pse__Project_Task__c> changedProjectTasks = new Map<Id,pse__Project_Task__c>();

        if( trigger.isUpdate && trigger.isAfter )
        {
            for( pse__Project_Task__c task : (List<pse__Project_Task__c>)trigger.new )
            {
                pse__Project_Task__c old = (pse__Project_Task__c)trigger.oldMap.get( task.Id );
                if( task.Role_Budget_Link__c != null && old.Role_Budget_Link__c != null && 
                    task.Role_Budget_Link__c != old.Role_Budget_Link__c )
                {
                    // the role budget has changed
                    changedProjectTasks.put( task.Id, task );
                }
            }
        }

        if( changedProjectTasks.size() == 0 )
        {
            return;
        }

        Set<Id> assignmentIds = new Set<Id>();
        Map<Id,List<pse__Project_Task_Assignment__c>> taskToPTAs = new Map<Id,List<pse__Project_Task_Assignment__c>>();

        for( pse__Project_Task_Assignment__c pta : 
            [Select 
                Id,
                Role_Budget__c,
                pse__Project_Task__c,
                pse__Assignment__c,
                pse__Assignment__r.Role_Budget__c,
                pse__Resource_Request__c,
                pse__Resource_Request__r.Role_Budget__c
            from 
                pse__Project_Task_Assignment__c 
            where 
                pse__Project_Task__c in :changedProjectTasks.keySet()] )
        {
            if( pta.pse__Assignment__c != null )
            {
                assignmentIds.add( pta.pse__Assignment__c );
            }

            if( !taskToPTAs.containsKey( pta.pse__Project_Task__c ) )
            {
                taskToPTAs.put( pta.pse__Project_Task__c, new List<pse__Project_Task_Assignment__c>() );
            }
            taskToPTAs.get( pta.pse__Project_Task__c ).add( pta );
        }

        Map<Id,Set<Id>> assignmentToTasks = new Map<Id,Set<Id>>();
        Map<Id,pse__Assignment__c> assignments = new Map<Id,pse__Assignment__c>();
        for( pse__Assignment__c assignment : 
            [Select 
                Id,
                Role_Budget__c,
                (Select Id, Role_Budget__c, pse__Project_Task__c, pse__Project_Task__r.Role_Budget__c from pse__Project_Task_Assignments__r) 
            from 
                pse__Assignment__c 
            where 
                Id in :assignmentIds] )
        {
            Set<Id> taskIds = new Set<Id>();
            for( pse__Project_Task_Assignment__c pta : assignment.pse__Project_Task_Assignments__r )
            {
                if( pta.pse__Project_Task__c != null )
                {
                    taskIds.add( pta.pse__Project_Task__c );
                }
            }

            if( taskIds.size() > 0 )
            {
                assignmentToTasks.put( assignment.Id, taskIds );
            }

            assignments.put( assignment.Id, assignment );
        }

        Map<Id,pse__Project_Task_Assignment__c> changedPTAs = new Map<Id,pse__Project_Task_Assignment__c>();
        Map<Id,pse__Assignment__c> changedAssignments = new Map<Id,pse__Assignment__c>();
        Map<Id,pse__Resource_Request__c> changedResourceRequests = new Map<Id,pse__Resource_Request__c>();

        for( pse__Project_Task__c task : changedProjectTasks.values() )
        {
            Set<Id> taskAssignmentIds = new Set<Id>();
            if( taskToPTAs.containsKey( task.Id ) )
            {
                for( pse__Project_Task_Assignment__c pta : taskToPTAs.get( task.Id ) )
                {
                    Id assignmentId = pta.pse__Assignment__c;
                    if( assignmentId == null )
                    {
                        // easy, just change the PTA and resource request and we're done
                        pta.Role_Budget__c = task.Role_Budget_Link__c;
                        changedPTAs.put( pta.Id, pta );

                        system.debug( 'x: ' + pta.Id + ' ' + pta.pse__Resource_Request__c );

                        if( pta.pse__Resource_Request__c != null )
                        {
                            pta.pse__Resource_Request__r.Role_Budget__c = task.Role_Budget_Link__c;
                            changedResourceRequests.put( pta.pse__Resource_Request__c, pta.pse__Resource_Request__r );
                        }
                    }
                    else
                    {
                        taskAssignmentIds.add( assignmentId );
                    }
                }
            }

            if( taskAssignmentIds.size() > 0 )
            {
                for( Id assignmentId : taskAssignmentIds )
                {
                    Set<Id> taskIds = assignmentToTasks.get( assignmentId );
                    if( taskIds.contains( task.Id ) )
                    {
                        for( pse__Project_Task_Assignment__c pta : taskToPTAs.get( task.Id ) )
                        {
                            if( taskIds.size() > 1 )
                            {
                                // we have tasks other than this one associated with the assignment
                                pta.pse__Assignment__c = null;
                            }
                            pta.Role_Budget__c = task.Role_Budget_Link__c;
                            changedPTAs.put( pta.Id, pta );

                            system.debug( 'y: ' + pta.Id + ' ' + pta.pse__Resource_Request__c );

                            if( pta.pse__Resource_Request__c != null )
                            {
                                pta.pse__Resource_Request__r.Role_Budget__c = task.Role_Budget_Link__c;
                                changedResourceRequests.put( pta.pse__Resource_Request__c, pta.pse__Resource_Request__r );
                            }
                        }

                        if( taskIds.size() == 1 )
                        {
                            // we have a pure assignment so we can update it too
                            pse__Assignment__c assignment = assignments.get( assignmentId );
                            assignment.Role_Budget__c = task.Role_Budget_Link__c;
                            changedAssignments.put( assignment.Id, assignment );
                        }
                    }
                }
            }

            // update everything we've touched
            update changedPTAs.values();
            update changedAssignments.values();
            update changedResourceRequests.values();
        }
    }
}