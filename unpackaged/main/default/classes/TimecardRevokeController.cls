public with sharing class TimecardRevokeController 
{
    public boolean IsDone { get; set; }
    public Id TimecardId { get; set; }
    public string Reason { get; set; }
    public class AppException extends Exception {}

    public TimecardRevokeController( ApexPages.StandardController con ) 
    {
        this.IsDone = false;
        this.TimecardId = con.getId();
    }

    public void preCheck()
    {
        try
        {
            List<pse__Timecard_Header__c> timecards = 
                [Select 
                    Id,
                    pse__Approved__c,
                    pse__Status__c,
                    pse__Include_In_Financials__c,
                    pse__Submitted__c
                from 
                    pse__Timecard_Header__c 
                where 
                    Id = :timecardId];

            if( timecards.size() == 0 )
            {
                throw new AppException( 'Unable to find the timecard with id ' + timecardId );
            }

            pse__Timecard_Header__c timecard = timecards[0];

            if( timecard.pse__Approved__c != true )
            {
                throw new AppException( 'You can only revoke approved timecards' );
            }

            for( Task_Time_Split__c split : [Select Id, Task_Time__c, Sync_Status__c from Task_Time_Split__c where Task_Time__r.pse__Timecard__c = :timecardId] )
            {
                // if any are invoiced we fail the whole process
                if( split.Sync_Status__c == 'Invoiced' )
                {
                    throw new AppException( 'Some of the time has been invoiced so this timecard cannot be revoked' );
                }
            }
        }
        catch( Exception ex )
        {
            this.IsDone = true;
            ApexPages.addMessages( ex );
        }
    }

    public void Revoke()
    {
        IsDone = false;
        Savepoint savePoint = Database.setSavepoint();

        try
        {
            TaskTimeHelper.HandleTimesheetRevocation( TimecardId, Reason );

            ApexPages.addMessage( new ApexPages.Message( 
                ApexPages.Severity.Confirm, 
                'The timecard has been revoked and any synced data has been marked for deletion.' ) );          
        }
        catch( Exception ex )
        {
            ApexPages.addMessages( ex );
            Database.rollback( savePoint );
        }

        IsDone = true;
    }
}