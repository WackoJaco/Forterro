@RestResource(urlMapping='/tasktimeapi/tasktimes/*')
global with sharing class TaskTimeAPI 
{
    public class AppException extends Exception {}

    private final static String BASE_URI = '/tasktimeapi/tasktimes/';
    private final static integer MAX_RECORDS = 1000;
    private final static Set<string> NO_MILEAGE_ONLY_BUS = new Set<string>{ 'BPSC' };

    global class TimeEntry
    {
        public Id timeEntryId;
        public string reportedBy;
        public Date reportedDate;
        public decimal reportedHours;
        public string notes;
        public boolean isBillable;
        public decimal billedAmount;
        public string billingCurrency;
        public decimal billRate;
        public string timeType;
        public string businessUnitId;
        public string projectId;
        public string projectName;
        public string customerID;
        public string customerName;
        public string invoiceNumber;
        public string projectOwner;
        public string taskDescription;
        public string taskId;
        public string taskName;
        public boolean perDiemOnSite;
        public decimal distance;
        public string errorMessage;
        public DateTime syncDate;
        public string syncState;
        public DateTime approvedDate;
        public string taskType;
        public string orderID;
        public string resourcePractice;
        public string resourceRegion;
        public string resourceGroup;
        public string customerContact;
        public string projectType;
        public string projectSubType;
        public string taskStatus;
        public string projectStatus;
        public string roleBudget;
        public boolean location;
        public string fortXID;
        public string reportedByBUID;

        global TimeEntry()
        {
        }

        public TimeEntry( Task_Time_Split__c split )
        {
            timeEntryId = split.Id;
            reportedBy = split.Task_Time__r.pse__Timecard__r.pse__Resource__r.External_Id__c == null ?
                (string)split.Task_Time__r.pse__Timecard__r.pse__Resource__r.Email : split.Task_Time__r.pse__Timecard__r.pse__Resource__r.External_Id__c;
            reportedDate = split.Start_Date__c;
            reportedHours = split.Hours__c;
            notes = split.Notes__c;
            isBillable = split.Task_Time__r.pse__Timecard__r.pse__Billable__c;
            billedAmount = split.Hours__c * RestAPIHelper.zeroIfNull( split.Task_Time__r.pse__Timecard__r.pse__Bill_Rate__c );
            billingCurrency = split.Task_Time__r.pse__Timecard__r.CurrencyIsoCode;
            billRate = split.Task_Time__r.pse__Timecard__r.pse__Bill_Rate__c;
            timeType = split.Task_Time__r.pse__Timecard__r.Type__c;
            businessUnitId = split.Task_Time__r.pse__Timecard__r.pse__Project__r.pse__Region__r.BU_Code__c;
            projectId = split.Task_Time__r.pse__Timecard__r.pse__Project__r.External_Project_Id__c == null ?
                (string)split.Task_Time__r.pse__Timecard__r.pse__Project__r.pse__Project_ID__c : split.Task_Time__r.pse__Timecard__r.pse__Project__r.External_Project_Id__c;
            projectName = split.Task_Time__r.pse__Timecard__r.pse__Project__r.Name;
            customerID = split.Task_Time__r.pse__Timecard__r.pse__Project__r.pse__Account__r.External_Id__c == null ?
                (string)split.Task_Time__r.pse__Timecard__r.pse__Project__r.pse__Account__c : split.Task_Time__r.pse__Timecard__r.pse__Project__r.pse__Account__r.External_Id__c;
            customerName = split.Task_Time__r.pse__Timecard__r.pse__Project__r.pse__Account__r.Name;
            invoiceNumber = split.Invoice_Number__c;
            if( split.Task_Time__r.pse__Timecard__r.pse__Project__r.pse__Project_Manager__c != null )
            {
                projectOwner = split.Task_Time__r.pse__Timecard__r.pse__Project__r.pse__Project_Manager__r.Name;
            }
            taskDescription = split.Task_Time__r.pse__Project_Task__r.pse__Description__c;
            taskId = split.Task_Time__r.pse__Project_Task__r.pse__External_Task_ID__c == null ?
                (string)split.Task_Time__r.pse__Project_Task__c : split.Task_Time__r.pse__Project_Task__r.pse__External_Task_ID__c;
            taskName = split.Task_Time__r.pse__Project_Task__r.Name;
            perDiemOnSite = split.Per_Diem__c;
            distance = split.Distance__c;
            errorMessage = split.ErrorMessage__c;
            syncDate = split.SyncDate__c;
            syncState = split.Sync_Status__c;

            approvedDate = split.Task_Time__r.pse__Timecard__r.Approved_Date__c;
            taskType = split.Task_Time__r.pse__Project_Task__r.Task_Type__c;
            orderID = split.Task_Time__r.pse__Project_Task__r.Order_ID__c;
            resourcePractice = split.Task_Time__r.pse__Timecard__r.pse__Resource__r.pse__Practice__c == null ?
                '' : split.Task_Time__r.pse__Timecard__r.pse__Resource__r.pse__Practice__r.Name;
            resourceRegion = split.Task_Time__r.pse__Timecard__r.pse__Resource__r.pse__Region__c == null ?
                '' : split.Task_Time__r.pse__Timecard__r.pse__Resource__r.pse__Region__r.Name;
            resourceGroup = split.Task_Time__r.pse__Timecard__r.pse__Resource__r.pse__Group__c == null ?
                '' : split.Task_Time__r.pse__Timecard__r.pse__Resource__r.pse__Group__r.Name;
            customerContact = split.Task_Time__r.pse__Timecard__r.pse__Project__r.Contact__c == null ?
                '' : split.Task_Time__r.pse__Timecard__r.pse__Project__r.Contact__r.Name;
            projectType = split.Task_Time__r.pse__Timecard__r.pse__Project__r.pse__Project_Type__c;
            projectSubType = split.Task_Time__r.pse__Timecard__r.pse__Project__r.Project_Sub_Types__c;
            taskStatus = split.Task_Time__r.pse__Project_Task__r.pse__Status__c;
            projectStatus = split.Task_Time__r.pse__Timecard__r.pse__Project__r.pse__Stage__c;
            roleBudget = split.Task_Time__r.pse__Timecard__r.pse__Assignment__r?.Role_Budget__r?.Role_Budget_Name__c;
            location = split.Task_Time__r.pse__Timecard__r.Location__c == 'On-site' ? true : false;
            fortXID = split.Task_Time__r.pse__Timecard__r.pse__Resource__r.FortX_ID__c;
            reportedByBUID = split.Task_Time__r.pse__Timecard__r.pse__Resource__r.pse__Region__c == null ? '' : split.Task_Time__r.pse__Timecard__r.pse__Resource__r.pse__Region__r.BU_Code__c;
        }
    }

    global class TimeEntryUpdate
    {
        public Id timeEntryId;
        public string errorMessage;
        public string invoiceNumber;
        public DateTime syncDate;
        public string syncState;
    }

    @HttpPost
    global static void HandlePost( TimeEntryUpdate[] timeEntries )
    {
        Savepoint savePoint = Database.setSavepoint();

        try
        {
            Map<Id,TimeEntryUpdate> timeEntryMap = new Map<Id,TimeEntryUpdate>();
            for( TimeEntryUpdate entry : timeEntries )
            {
                timeEntryMap.put( entry.timeEntryId, entry );
            }

            Map<Id,Task_Time_Split__c> splits = new Map<Id,Task_Time_Split__c>(
                [Select Id, Sync_Status__c, ErrorMessage__c, SyncDate__c, Invoice_Number__c from Task_Time_Split__c where id in :timeEntryMap.keySet()]
            );

            List<Task_Time_Split__c> splitsToUpdate = new List<Task_Time_Split__c>();
            List<string> errors = new List<string>();

            for( TimeEntryUpdate entry : timeEntries )
            {
                if( !splits.containsKey( entry.timeEntryId ) )
                {
                    errors.add( 'Entry ' + entry.timeEntryId + ' not found' );
                    continue;
                }

                Task_Time_Split__c split = splits.get( entry.timeEntryId );
                split.Sync_Status__c = entry.syncState;
                split.ErrorMessage__c = entry.errorMessage;
                split.Invoice_Number__c = entry.invoiceNumber;

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

    @HttpGet
    global static void HandleGet()
    {
        Savepoint savePoint = Database.setSavepoint();

        try
        {
            RestRequest req = RestContext.request;
            string context = req.requestURI.substring( req.requestURI.indexOf(BASE_URI) + BASE_URI.length() );

            List<pse__Region__c> regions = [Select Id from pse__Region__c where BU_Code__c = :context];
            if( regions.size() == 0 )
            {
                throw new AppException( 'Failed to find business unit code ' + context );
            }

            List<TimeEntry> timeEntries = new List<TimeEntry>();

            for( Task_Time_Split__c split :
                [Select
                    Id, 
                    Start_Date__c, 
                    Days__c,
                    Hours__c,
                    Notes__c,
                    Distance__c, 
                    Per_Diem__c,
                    Invoice_Number__c,
                    Sync_Status__c,
                    SyncDate__c,
                    ErrorMessage__c,
                    Task_Time__c,
                    Task_Time__r.pse__Timecard__c,
                    Task_Time__r.pse__Timecard__r.Type__c,
                    Task_Time__r.pse__Timecard__r.CurrencyIsoCode,
                    Task_Time__r.pse__Timecard__r.pse__Billable__c,
                    Task_Time__r.pse__Timecard__r.pse__Bill_Rate__c,
                    Task_Time__r.pse__Timecard__r.Approved_Date__c,
                    Task_Time__r.pse__Timecard__r.Location__c,
                    Task_Time__r.pse__Timecard__r.pse__Resource__c,
                    Task_Time__r.pse__Timecard__r.pse__Resource__r.External_Id__c,
                    Task_Time__r.pse__Timecard__r.pse__Resource__r.Email,
                    Task_Time__r.pse__Timecard__r.pse__Resource__r.pse__Practice__c,
                    Task_Time__r.pse__Timecard__r.pse__Resource__r.pse__Practice__r.Name,
                    Task_Time__r.pse__Timecard__r.pse__Resource__r.pse__Region__c,
                    Task_Time__r.pse__Timecard__r.pse__Resource__r.pse__Region__r.Name,
                    Task_Time__r.pse__Timecard__r.pse__Resource__r.pse__Region__r.BU_Code__c,
                    Task_Time__r.pse__Timecard__r.pse__Resource__r.pse__Group__c,
                    Task_Time__r.pse__Timecard__r.pse__Resource__r.pse__Group__r.Name,
                    Task_Time__r.pse__Timecard__r.pse__Resource__r.FortX_ID__c,
                    Task_Time__r.pse__Timecard__r.pse__Project__c,
                    Task_Time__r.pse__Timecard__r.pse__Project__r.Name,
                    Task_Time__r.pse__Timecard__r.pse__Project__r.pse__Region__c,
                    Task_Time__r.pse__Timecard__r.pse__Project__r.pse__Region__r.BU_Code__c,
                    Task_Time__r.pse__Timecard__r.pse__Project__r.pse__Project_ID__c,
                    Task_Time__r.pse__Timecard__r.pse__Project__r.External_Project_Id__c,
                    Task_Time__r.pse__Timecard__r.pse__Project__r.pse__Project_Type__c,
                    Task_Time__r.pse__Timecard__r.pse__Project__r.Project_Sub_Types__c,
                    Task_Time__r.pse__Timecard__r.pse__Project__r.pse__Account__c,
                    Task_Time__r.pse__Timecard__r.pse__Project__r.pse__Account__r.Name,
                    Task_Time__r.pse__Timecard__r.pse__Project__r.pse__Account__r.External_Id__c,
                    Task_Time__r.pse__Timecard__r.pse__Project__r.pse__Project_Manager__c,
                    Task_Time__r.pse__Timecard__r.pse__Project__r.pse__Project_Manager__r.Name,
                    Task_Time__r.pse__Timecard__r.pse__Project__r.Contact__c,
                    Task_Time__r.pse__Timecard__r.pse__Project__r.Contact__r.Name,
                    Task_Time__r.pse__Timecard__r.pse__Project__r.pse__Stage__c,
                    Task_Time__r.pse__Timecard__r.pse__Assignment__r.Role_Budget__r.Role_Budget_Name__c,
                    Task_Time__r.pse__Project_Task__c,
                    Task_Time__r.pse__Project_Task__r.Name,
                    Task_Time__r.pse__Project_Task__r.pse__Description__c,
                    Task_Time__r.pse__Project_Task__r.pse__External_Task_ID__c,
                    Task_Time__r.pse__Project_Task__r.Task_Type__c,
                    Task_Time__r.pse__Project_Task__r.pse__Status__c,
                    Task_Time__r.pse__Project_Task__r.Order_ID__c
                From
                    Task_Time_Split__c
                Where
                    Sync_Status__c = 'New' and
                    Task_Time__r.pse__Timecard__r.pse__Status__c = 'Approved' and
                    Task_Time__r.pse__Timecard__r.pse__Approved__c = true and
                    Task_Time__r.pse__Timecard__r.pse__Include_In_Financials__c = true and
                    Task_Time__r.pse__Timecard__r.pse__Submitted__c = true and
                    Task_Time__r.pse__Timecard__r.pse__Project__r.pse__Region__r.BU_Code__c = :context and
                    ( 
                        Task_Time__r.pse__Timecard__r.pse__Project__r.pse__Region__r.BU_Code__c not in :NO_MILEAGE_ONLY_BUS or 
                        ( Hours__c > 0.0 ) 
                    ) and
                    (
                        ( Distance__c != 0.0 and Distance__c != null) or 
                        (Hours__c != 0.0 and Hours__c != null and Task_Time__r.pse__Timecard__r.pse__Bill_Rate__c > 0) or 
                        (Days__c != 0.0 and Days__c != null and Task_Time__r.pse__Timecard__r.pse__Bill_Rate__c > 0) or 
                        (
                            Task_Time__r.pse__Timecard__r.pse__Project__r.pse__Region__r.BU_Code__c = 'JVS' and 
                            Hours__c != 0.0 and Hours__c != null and 
                            Task_Time__r.pse__Timecard__r.pse__Billable__c = true and
                            Task_Time__r.pse__Timecard__r.pse__Project__r.pse__Billing_Type__c in ('Subscription','Fixed Price')
                        ) or 
                        Per_Diem__c = true
                    )
                Limit
                    :MAX_RECORDS] )
            {
                TimeEntry entry = new TimeEntry( split );
                timeEntries.add( entry );
            }

            RestAPIHelper.SetRestReturn( timeEntries, false );
        }
        catch( Exception ex )
        {
            RestAPIHelper.SetRestError( 400, 'BAD_REQUEST', new List<string>{ ex.getMessage() } );
            Database.rollback( savePoint );
        }
    }
}