public class TaskTimeHelper 
{
    public class AppException extends Exception {}

    public static void TimecardHeaderTriggerHandler()
    {
        if( !Task_Time_Split_Settings__c.getInstance().Enable_Timecard_Trigger__c )
        {
            return;
        }

        // we can't create a master detail on task time split so have to handle the fact that a 
        // delete here won't cascade and fire the task time delete trigger
        Set<Id> timecardIds = new Set<Id>();
        Set<Id> approvedIds = new Set<Id>();
        for( pse__Timecard_Header__c tc : (List<pse__Timecard_Header__c>)trigger.old )
        {
            timecardIds.add( tc.Id );

            if( trigger.isUpdate )
            {
                if( ((pse__Timecard_Header__c)trigger.newMap.get( tc.Id )).pse__Status__c == 'Approved' )
                {
                    approvedIds.add( tc.Id );
                }
            }
        }

        if( trigger.isDelete )
        {
            List<Task_Time_Split__c> splitsToDelete = new List<Task_Time_Split__c>();
            Set<string> syncedStatuses = new Set<string>{ 'Extracted', 'Synced', 'Invoiced', 'Pending Invoice' };

            for( Task_Time_Split__c split : [Select Id, Task_Time__r.pse__Timecard__c, Sync_Status__c from Task_Time_Split__c where Task_Time__r.pse__Timecard__c in :timecardIds] )
            {
                if( syncedStatuses.contains( split.Sync_Status__c ) )
                {
                    trigger.oldMap.get( split.Task_Time__r.pse__Timecard__c ).addError( 'This timecard cannot be deleted as it has a task time split that has been synced externally' );
                }
                else
                {
                    splitsToDelete.add( split );
                }
            }

            if( splitsToDelete.size() > 0 )
            {
                delete splitsToDelete;
            }
        }

        if( trigger.isUpdate )
        {
            PushDistanceFromTimecardToTaskTimeSplits( approvedIds );
        }
    }

    public static void HandleTimesheetRevocation( Id timecardId, string reason )
    {
        // get the timecard
        List<pse__Timecard_Header__c> timecards = 
            [Select 
                Id,
                pse__Approved__c,
                pse__Status__c,
                pse__Include_In_Financials__c,
                pse__Submitted__c,
                pse__Resource__c,
                pse__Resource__r.Clarizen_ID__c,
                pse__Resource__r.Email,
                Revoked__c,
                Revoke_Reason__c
            from 
                pse__Timecard_Header__c 
            where 
                Id = :timecardId];

        if( timecards.size() == 0 )
        {
            throw new AppException( 'Unable to find the timecard with id ' + timecardId );
        }

        if( string.isBlank( reason ) )
        {
            throw new AppException( 'You must provide a revocation reason' );
        }

        pse__Timecard_Header__c timecard = timecards[0];

        if( timecard.pse__Approved__c != true )
        {
            throw new AppException( 'You can only revoke approved timecards' );
        }

        string revokedBy = timecard.pse__Resource__r.Email;
        if( !string.isBlank( timecard.pse__Resource__r.Clarizen_ID__c ) )
        {
            revokedBy = timecard.pse__Resource__r.Clarizen_ID__c;
        }

        // gather the splits to delete
        List<Task_Time_Split__c> splitsToDelete = new List<Task_Time_Split__c>();
        List<Task_Time_Split__c> syncedSplits = new List<Task_Time_Split__c>();
        Set<string> syncedStatuses = new Set<string>{ 'Extracted', 'Synced', 'Pending Invoice' };
        List<Deleted_Task_Time_Split__c> deletedTaskTimeSplits = new List<Deleted_Task_Time_Split__c>();
        Set<Id> effectedTaskTimeIds = new Set<Id>();

        for( Task_Time_Split__c split : [Select Id, Task_Time__c, Sync_Status__c from Task_Time_Split__c where Task_Time__r.pse__Timecard__c = :timecardId] )
        {
            // if any are invoiced we fail the whole process
            if( split.Sync_Status__c == 'Invoiced' )
            {
                throw new AppException( 'Some of the time has been invoiced so this timecard cannot be revoked' );
            }

            if( syncedStatuses.contains( split.Sync_Status__c ) )
            {
                syncedSplits.add( split );
                effectedTaskTimeIds.add( split.Task_Time__c );

                deletedTaskTimeSplits.add( new Deleted_Task_Time_Split__c(
                    Timecard__c = timecardId,
                    Task_Time_Split_Id__c = split.Id,
                    Sync_Status__c = 'New',
                    Revoke_State__c = 'Requested',
                    Revoke_Reason__c = reason,
                    Revoked_By__c = revokedBy
                ) );
            }
            splitsToDelete.add( split );
        }

        if( syncedSplits.size() > 0 )
        {
            // record the deleted splits, then actually delete them
            insert deletedTaskTimeSplits;
            delete splitsToDelete;

            // now trigger recreation of new timecard splits
            List<pse__Task_Time__c> taskTimes = new List<pse__Task_Time__c>();
            for( Id taskTimeId : effectedTaskTimeIds )
            {
                taskTimes.add( new pse__Task_Time__c( Id = taskTimeId  ) );
            }
            update taskTimes;
        }

        // un-approve the timecard
        timecard.pse__Approved__c = false;
        timecard.pse__Status__c = 'Saved';
        timecard.pse__Include_In_Financials__c = false;
        timecard.pse__Submitted__c = false;
        timecard.Revoked__c = true;
        timecard.Revoke_Reason__c = reason;

        update timecard;
    }

    public static void TriggerHandler()
    {
        // check custom setting to disable functionality
        if( !Task_Time_Split_Settings__c.getInstance().Enable_Task_Time_Trigger__c )
        {
            return;
        }

        // get the task time ids
        Set<Id> taskTimeIds = new Set<Id>();
        if( trigger.isDelete )
        {
            taskTimeIds = trigger.oldMap.keySet();
        }
        else if( trigger.isInsert || trigger.isUpdate )
        {
            taskTimeIds = trigger.newMap.keySet();
        }

        Set<Id> timecardIds = new Set<Id>();

        // get all task time splits for effected task times
        Map<Id,List<Task_Time_Split__c>> taskTimeToSplits = new Map<Id,List<Task_Time_Split__c>>();
        for( Task_Time_Split__c split : 
            [Select 
                Id, 
                Days__c, 
                Hours__c, 
                Notes__c, 
                Start_Date__c, 
                Sync_Status__c, 
                Task_Time__c,
                Task_Time__r.pse__Timecard__c 
            from 
                Task_Time_Split__c 
            where 
                Task_Time__c in :taskTimeIds] )
        {
            if( !taskTimeToSplits.containsKey( split.Task_Time__c ) )
            {
                taskTimeToSplits.put( split.Task_Time__c, new List<Task_Time_Split__c>() );
            }
            taskTimeToSplits.get( split.Task_Time__c ).add( split );
        }

        // deletion / update - prevent deletion if any task time splits are synced
        if( trigger.isDelete || trigger.isUpdate )
        {
            List<sObject> splitsToDelete = new List<sObject>();
            Set<string> syncedStatuses = new Set<string>{ 'Extracted', 'Synced', 'Invoiced', 'Pending Invoice' };

            for( sObject taskTime : trigger.old )
            {
                boolean failed = false;
                if( taskTimeToSplits.containsKey( taskTime.Id ) )
                {
                    for( Task_Time_Split__c split : taskTimeToSplits.get( taskTime.Id ) )
                    {
                        if( syncedStatuses.contains( split.Sync_Status__c ) )
                        {
                            taskTime.addError( 'This task time cannot be modified as it has been synced externally' );
                            failed = true;
                        }
                    }
                }

                if( !failed && trigger.isDelete )
                {
                    // no problems, so we can delete the child splits
                    splitsToDelete.addAll( taskTimeToSplits.get( taskTime.Id ) );
                }
            }

            if( splitsToDelete.size() > 0 )
            {
                for( Task_Time_Split__c split : (List<Task_Time_Split__c>)splitsToDelete )
                {
                    if( split.Task_Time__c != null && split.Task_Time__r.pse__Timecard__c != null )
                    {
                        timecardIds.add( split.Task_Time__r.pse__Timecard__c );
                    }
                }

                delete splitsToDelete;
            }
        }

        // insert - split down the task time into days
        if( trigger.isInsert )
        {
            List<Task_Time_Split__c> splits = new List<Task_Time_Split__c>();
            for( pse__Task_Time__c taskTime : (List<pse__Task_Time__c>)trigger.new )
            {
                Date dt = taskTime.pse__Start_Date__c;

                if( taskTime.pse__Timecard__c != null )
                {
                    timecardIds.add( taskTime.pse__Timecard__c );
                }

                for( Integer i = 0; i < 7; i++ )
                {
                    string dayOfWeek = dayOfWeek( dt );

                    Task_Time_Split__c split = new Task_Time_Split__c(
                        Task_Time__c = taskTime.Id,
                        CurrencyIsoCode = taskTime.CurrencyIsoCode,
                        Start_Date__c = dt,
                        Days__c = (decimal)taskTime.get( 'pse__' + dayOfWeek + '_Days__c'),
                        Hours__c = (decimal)taskTime.get( 'pse__' + dayOfWeek + '_Hours__c'),
                        Notes__c = (string)taskTime.get( 'pse__' + dayOfWeek + '_Notes__c'),
                        Sync_Status__c = 'New'                        
                    );

                    // only create splits that actually have values
                    //if( getVal( split.Days__c ) != 0.0 || getVal( split.Hours__c ) != 0.0 )
                    {
                        splits.add( split );
                    }

                    dt = dt.addDays( 1 );
                }
            }

            insert splits;
        }

        // update - make sure at the end we have splits that match the task time
        if( trigger.isUpdate )
        {
            List<Task_Time_Split__c> splits = new List<Task_Time_Split__c>();
            List<Task_Time_Split__c> splitsToDelete = new List<Task_Time_Split__c>();

            for( pse__Task_Time__c taskTime : (List<pse__Task_Time__c>)trigger.new )
            {
                if( taskTime.getErrors().size() > 0 )
                {
                    // if we've marked one of the task times as invalid, skip processing it here
                    continue;
                }

                if( taskTime.pse__Timecard__c != null )
                {
                    timecardIds.add( taskTime.pse__Timecard__c );
                }

                Date dt = taskTime.pse__Start_Date__c;

                for( Integer i = 0; i < 7; i++ )
                {
                    string dayOfWeek = dayOfWeek( dt );
                    Task_Time_Split__c splitForDay;
                    if( taskTimeToSplits.containsKey( taskTime.Id ) )
                    {
                        for( Task_Time_Split__c split : taskTimeToSplits.get( taskTime.Id ) )
                        {
                            if( split.Start_Date__c == dt )
                            {
                                splitForDay = split;
                                break;
                            }
                        }
                    }

                    if( splitForDay == null )
                    {
                        Task_Time_Split__c split = new Task_Time_Split__c(
                            Task_Time__c = taskTime.Id,
                            CurrencyIsoCode = taskTime.CurrencyIsoCode,
                            Start_Date__c = dt,
                            Days__c = (decimal)taskTime.get( 'pse__' + dayOfWeek + '_Days__c'),
                            Hours__c = (decimal)taskTime.get( 'pse__' + dayOfWeek + '_Hours__c'),
                            Notes__c = (string)taskTime.get( 'pse__' + dayOfWeek + '_Notes__c'),
                            Sync_Status__c = 'New'                        
                        );

                        //if( getVal( split.Days__c ) != 0.0 || getVal( split.Hours__c ) != 0.0 )
                        {
                            splits.add( split );
                        }
                    }
                    else
                    {
                        splitForDay.Days__c = (decimal)taskTime.get( 'pse__' + dayOfWeek + '_Days__c');
                        splitForDay.Hours__c = (decimal)taskTime.get( 'pse__' + dayOfWeek + '_Hours__c');
                        splitForDay.Notes__c = (string)taskTime.get( 'pse__' + dayOfWeek + '_Notes__c');

                        //if( getVal( splitForDay.Days__c ) != 0.0 || getVal( splitForDay.Hours__c ) != 0.0 )
                        {
                            splits.add( splitForDay );
                        }
                        /*else
                        {
                            // the split no longer has a value so is up for deletion
                            splitsToDelete.add( splitForDay );
                        }*/
                    }

                    dt = dt.addDays( 1 );
                }
            }

            upsert splits;

            if( splitsToDelete.size() > 0 )
            {
                delete splitsToDelete;
            }

            PushDistanceFromTimecardToTaskTimeSplits( timecardIds );
        }
    }

    public static void PushDistanceFromTimecardToTaskTimeSplits( Set<Id> timecardIds )
    {
        List<Task_Time_Split__c> splitsToUpdate = new List<Task_Time_Split__c>();

        Map<Id,pse__Timecard_Header__c> timecards = new Map<Id,pse__Timecard_Header__c>();
        Map<Id,List<pse__Task_Time__c>> timecardToTaskTimes = new Map<Id,List<pse__Task_Time__c>>();

        for( pse__Task_Time__c taskTime : 
            [Select 
                Id,
                pse__Start_Date__c,
                pse__Timecard__c,
                pse__Timecard__r.Distance_Monday__c,
                pse__Timecard__r.Distance_Tuesday__c,
                pse__Timecard__r.Distance_Wednesday__c,
                pse__Timecard__r.Distance_Thursday__c,
                pse__Timecard__r.Distance_Friday__c,
                pse__Timecard__r.Distance_Saturday__c,
                pse__Timecard__r.Distance_Sunday__c,
                pse__Timecard__r.Per_Diem_Monday__c,
                pse__Timecard__r.Per_Diem_Tuesday__c,
                pse__Timecard__r.Per_Diem_Wednesday__c,
                pse__Timecard__r.Per_Diem_Thursday__c,
                pse__Timecard__r.Per_Diem_Friday__c,
                pse__Timecard__r.Per_Diem_Saturday__c,
                pse__Timecard__r.Per_Diem_Sunday__c,
                (Select Id, Start_Date__c, Distance__c, Per_Diem__c from Task_Time_Splits__r) 
            from 
                pse__Task_Time__c
            where
                pse__Timecard__c in :timecardIds
            order by 
                pse__Timecard__c, createddate] )
        {
            if( !timecards.containsKey( taskTime.pse__Timecard__c ) )
            {
                timecards.put( taskTime.pse__Timecard__c, taskTime.pse__Timecard__r );
                timecardToTaskTimes.put( taskTime.pse__Timecard__c, new List<pse__Task_Time__c>() );
            }

            timecardToTaskTimes.get( taskTime.pse__Timecard__c ).add( taskTime );
        }

        for( pse__Timecard_Header__c timecard : timecards.values() )
        {
            // we only want to push the distance and per diem down to a single task time (splits)
            boolean firstTaskTime = true;
            for( pse__Task_Time__c taskTime : timecardToTaskTimes.get( timecard.Id ) )
            {
                for( Task_Time_Split__c split : taskTime.Task_Time_Splits__r )
                {
                    Date dt = split.Start_Date__c;
                    string dayOfWeek = dayOfWeek( dt );

                    if( firstTaskTime )
                    {
                        split.Distance__c = (decimal)timecard.get( 'Distance_' + dayOfWeek + '__c' );
                        split.Per_Diem__c = (boolean)timecard.get( 'Per_Diem_' + dayOfWeek + '__c' );
                    }
                    else
                    {
                        split.Distance__c = 0;
                        split.Per_Diem__c = false;
                    }

                    splitsToUpdate.add( split );
                }

                firstTaskTime = false;
            }
        }     
        
        if( splitsToUpdate.size() > 0 )
        {
            update splitsToUpdate;
        }
    }

    public static decimal getVal( decimal val )
    {
        return val == null ? 0.0 : val;
    }

    public static string dayOfWeek( Date theDate )
    {
        Integer day = Math.mod( Date.newInstance( 1900, 1, 7 ).daysBetween( theDate ), 7 );

        switch on day
        {
            when 0
            {
                return 'Sunday';
            }
            when 1
            {
                return 'Monday';
            }
            when 2
            {
                return 'Tuesday';
            }
            when 3
            {
                return 'Wednesday';
            }
            when 4
            {
                return 'Thursday';
            }
            when 5
            {
                return 'Friday';
            }
            when 6
            {
                return 'Saturday';
            }
            when else
            {
                throw new AppException( 'Unexpected day' );
            }
        }
    }
}