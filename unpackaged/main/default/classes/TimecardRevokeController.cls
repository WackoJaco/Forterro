public with sharing class TimecardRevokeController 
{
    public boolean IsDone { get; set; }
    public Id TimecardId { get; set; }
    public class AppException extends Exception {}

    public TimecardRevokeController( ApexPages.StandardController con ) 
    {
        this.IsDone = false;
        this.TimecardId = con.getId();
    }

    public void Revoke()
    {
        IsDone = false;
        Savepoint savePoint = Database.setSavepoint();

        try
        {
            TaskTimeHelper.HandleTimesheetRevocation( TimecardId );

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