@RestResource(urlMapping='/tasktimeapi/deletedtasktimes/*')
global with sharing class DeletedTaskTimeAPI 
{
    public class AppException extends Exception {}

    private final static String BASE_URI = '/tasktimeapi/deletedtasktimes/';
    private final static integer MAX_RECORDS = 1000;

    global class DeletedTimeEntry
    {
        public Id timeEntryId;
        public Id deletedTimeEntryId;
        public string revokeState;
        public DateTime syncDate;
        public string syncState;
        public string revokeReason;
        public string revokedBy;

        global DeletedTimeEntry()
        {
        }

        public DeletedTimeEntry( Deleted_Task_Time_Split__c split )
        {
            timeEntryId = split.Task_Time_Split_Id__c;
            deletedTimeEntryId = split.Id;
            revokeState = split.Revoke_State__c;
            syncDate = split.SyncDate__c;
            syncState = split.Sync_Status__c;
            revokeReason = split.Revoke_Reason__c;
            revokedBy = split.Revoked_By__c;
        }
    }

    global class DeletedTimeEntryUpdate
    {
        public Id timeEntryId;
        public string revokeState;
        public DateTime syncDate;
        public string syncState;
    }

    @HttpGet
    global static void HandleGet()
    {
        try
        {
            RestRequest req = RestContext.request;
            string context = req.requestURI.substring( req.requestURI.indexOf(BASE_URI) + BASE_URI.length() );

            List<pse__Region__c> regions = [Select Id from pse__Region__c where BU_Code__c = :context];
            if( regions.size() == 0 )
            {
                throw new AppException( 'Failed to find business unit code ' + context );
            }

            List<DeletedTimeEntry> timeEntries = new List<DeletedTimeEntry>();

            for( Deleted_Task_Time_Split__c split :
                [Select
                    Id, 
                    Task_Time_Split_Id__c,
                    Sync_Status__c,
                    SyncDate__c,
                    Revoke_Reason__c,
                    Revoked_By__c,
                    Revoke_State__c
                From
                    Deleted_Task_Time_Split__c
                Where
                    Sync_Status__c = 'New' and
                    Timecard__r.pse__Project__r.pse__Region__r.BU_Code__c = :context
                Limit
                    :MAX_RECORDS] )
            {
                DeletedTimeEntry entry = new DeletedTimeEntry( split );
                timeEntries.add( entry );
            }

            RestAPIHelper.SetRestReturn( timeEntries, false );
        }
        catch( Exception ex )
        {
            RestAPIHelper.SetRestError( 400, 'BAD_REQUEST', new List<string>{ ex.getMessage() } );
        }
    }

    @HttpPost
    global static void HandlePost( DeletedTimeEntryUpdate[] timeEntries )
    {
        Savepoint savePoint = Database.setSavepoint();

        try
        {
            Map<Id,DeletedTimeEntryUpdate> timeEntryMap = new Map<Id,DeletedTimeEntryUpdate>();
            for( DeletedTimeEntryUpdate entry : timeEntries )
            {
                timeEntryMap.put( entry.timeEntryId, entry );
            }

            Map<string,Deleted_Task_Time_Split__c> splits = new Map<string,Deleted_Task_Time_Split__c>();

            for( Deleted_Task_Time_Split__c split :
                [Select 
                    Id, 
                    Task_Time_Split_Id__c, 
                    Sync_Status__c, 
                    SyncDate__c,
                    Revoke_State__c
                from 
                    Deleted_Task_Time_Split__c 
                where
                    Task_Time_Split_Id__c in :timeEntryMap.keySet()] )
            {
                splits.put( split.Task_Time_Split_Id__c, split );
            }

            List<Deleted_Task_Time_Split__c> splitsToUpdate = new List<Deleted_Task_Time_Split__c>();
            List<string> errors = new List<string>();

            for( DeletedTimeEntryUpdate entry : timeEntries )
            {
                if( !splits.containsKey( entry.timeEntryId ) )
                {
                    errors.add( 'Entry ' + entry.timeEntryId + ' not found' + timeEntryMap.keySet() );
                    continue;
                }

                Deleted_Task_Time_Split__c split = splits.get( entry.timeEntryId );
                split.Sync_Status__c = entry.syncState;
                split.Revoke_State__c = entry.revokeState;

                if( entry.syncDate != null )
                {
                    split.SyncDate__c = entry.syncDate;
                }

                if( entry.syncState == 'Synced' && split.SyncDate__c == null )
                {
                    split.SyncDate__c = system.now();
                }

                splitsToUpdate.add( split );
            }

            if( errors.size() > 0 )
            {
                RestAPIHelper.SetRestError( 400, 'BAD_REQUEST', errors );
            }
            else
            {
                update splitsToUpdate;
                RestAPIHelper.SetRestReturn( timeEntryMap.size(), true );
            }
        }
        catch( Exception ex )
        {
            RestAPIHelper.SetRestError( 400, 'BAD_REQUEST', new List<string>{ ex.getMessage() } );
            Database.rollback( savePoint );
        }
    }
}