@RestResource(urlMapping='/projectsapi/projects/*')
global with sharing class ProjectAPI 
{
    public class AppException extends Exception {}

    private final static String BASE_URI = '/projectsapi/projects/';
    private final static integer MAX_RECORDS = 1000;

    global class Project
    {
        public string projectId;
        public string externalProjectId;
        public string projectName;
        public string projectOwner;
        public string projectOwnerName;
        public string customerID;
        public string customerName;
        public string businessUnit;
        public string buCode;
        public string projectType;
        public string projectSubType;
        public string projectBillingType;
        public string projectStatus;
        public Date startDate;
        public Date endDate;
        public string recordType;
        public DateTime syncDate;
        public string syncState;
        public string errorMessage;
        public boolean isBillable;
        public string currencyISOcode;
        public string invoiceContactReference;
        public string customerContact;
        public string orderId;

        global Project()
        {
        }

        public Project( pse__Proj__c project )
        {
            projectId = project.pse__Project_ID__c;
            externalProjectId = RestAPIHelper.sanitiseProjectId( project.External_Project_Id__c );
            projectName = project.Name;
            if( project.pse__Project_Manager__c != null )
            {
                projectOwnerName = project.pse__Project_Manager__r.Name;
                projectOwner = string.isblank( project.pse__Project_Manager__r.Clarizen_ID__c ) ? 
                    project.pse__Project_Manager__r.Email : 
                    project.pse__Project_Manager__r.Clarizen_ID__c;
            }
            else if( project.Lead_Consultant__c != null )
            {
                projectOwnerName = project.Lead_Consultant__r.Name;
                projectOwner = string.isblank( project.Lead_Consultant__r.Clarizen_ID__c ) ? 
                    project.Lead_Consultant__r.Email : 
                    project.Lead_Consultant__r.Clarizen_ID__c;
            }
            if( project.Invoice_Contact_Reference__c != null )
            {
                invoiceContactReference = project.Invoice_Contact_Reference__r.Name;
            }
            customerID = project.pse__Account__r.AccountNumber;
            customerName = project.pse__Account__r.Name;
            if( project.pse__Region__c != null )
            {
                businessUnit = project.pse__Region__r.Name;
                buCode = project.pse__Region__r.BU_Code__c;
            }
            projectType = project.pse__Project_Type__c;
            projectSubType = project.Project_Sub_Types__c;
            projectBillingType = project.pse__Billing_Type__c;
            projectStatus = project.pse__Stage__c;
            startDate = project.pse__Start_Date__c;
            endDate = project.pse__End_Date__c;
            recordType = project.RecordTypeId == null ? '' : project.RecordType.Name;
            syncDate = project.SyncDate__c;
            syncState = project.Sync_Status__c;
            errorMessage = project.ErrorMessage__c;
            isBillable = project.pse__Is_Billable__c;
            currencyISOcode = project.CurrencyIsoCode;
            customerContact = project.Customer_Contact_Reference__c;
            orderId = project.Order_Id__c;
        }
    }

    global class ProjectUpdate
    {
        public string projectId;
        public string errorMessage;
        public string syncState;
        public DateTime syncDate;
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

            List<Project> projects = new List<Project>();
            List<string> allowedSyncStates = new List<string>{ 'New', 'Pending' };

            for( pse__Proj__c soProject :
                [Select
                    Id,
                    pse__Project_ID__c,
                    External_Project_Id__c,
                    Name,
                    CurrencyIsoCode,
                    pse__Project_Manager__c,
                    pse__Project_Manager__r.Clarizen_ID__c,
                    pse__Project_Manager__r.Name,
                    pse__Project_Manager__r.Email,
                    Lead_Consultant__c,
                    Lead_Consultant__r.Clarizen_ID__c,
                    Lead_Consultant__r.Name,
                    Lead_Consultant__r.Email,
                    Invoice_Contact_Reference__c,
                    Invoice_Contact_Reference__r.Name,
                    pse__Account__c,
                    pse__Account__r.AccountNumber,
                    pse__Account__r.Name,
                    pse__Region__c,
                    pse__Region__r.Name,
                    pse__Region__r.BU_Code__c,
                    pse__Project_Type__c,
                    Project_Sub_Types__c,
                    pse__Billing_Type__c,
                    pse__Stage__c,
                    pse__Start_Date__c,
                    pse__End_Date__c,
                    RecordTypeId,
                    RecordType.Name,
                    SyncDate__c,
                    Sync_Status__c,
                    ErrorMessage__c,
                    pse__Is_Billable__c,
                    Customer_Contact_Reference__c,
                    Order_Id__c
                From
                    pse__Proj__c
                Where
                    Sync_Status__c in :allowedSyncStates and
                    pse__Stage__c != 'Requested' and
                    pse__Stage__c != 'Draft' and
                    pse__Stage__c != null and
                    pse__Is_Billable__c = true and
                    pse__Account__r.AccountNumber != '' and
                    pse__Region__r.BU_Code__c = :context
                Limit
                    :MAX_RECORDS] )
            {
                Project proj = new Project( soProject );
                projects.add( proj );
            }

            RestAPIHelper.SetRestReturn( projects, false );
        }
        catch( Exception ex )
        {
            RestAPIHelper.SetRestError( 400, 'BAD_REQUEST', new List<string>{ ex.getMessage() } );
            Database.rollback( savePoint );
        }
    }

    @HttpPost
    global static void HandlePost( ProjectUpdate[] projectUpdates )
    {
        Savepoint savePoint = Database.setSavepoint();

        try
        {
            Map<string,ProjectUpdate> projectUpdateMap = new Map<string,ProjectUpdate>();
            for( ProjectUpdate projectUpdate : projectUpdates )
            {
                projectUpdateMap.put( projectUpdate.projectId, projectUpdate );
            }

            Map<string,pse__Proj__c> projects = new Map<string,pse__Proj__c>();
            for( pse__Proj__c project : 
                [Select 
                    Id, 
                    pse__Project_ID__c, 
                    Sync_Status__c, 
                    ErrorMessage__c, 
                    SyncDate__c 
                from 
                    pse__Proj__c 
                where 
                    pse__Project_ID__c in :projectUpdateMap.keySet()] )
            {
                projects.put( project.pse__Project_ID__c, project );
            }

            List<pse__Proj__c> projectsToUpdate = new List<pse__Proj__c>();
            List<string> errors = new List<string>();

            for( ProjectUpdate projectUpdate : projectUpdates )
            {
                if( !projects.containsKey( projectUpdate.projectId ) )
                {
                    errors.add( 'Project ' + projectUpdate.projectId + ' not found' );
                    continue;
                }

                pse__Proj__c project = projects.get( projectUpdate.projectId );
                project.Sync_Status__c = projectUpdate.syncState;
                project.ErrorMessage__c = projectUpdate.errorMessage;

                if( projectUpdate.syncDate != null )
                {
                    project.SyncDate__c = projectUpdate.syncDate;
                }

                if( projectUpdate.syncState == 'Synced' && project.SyncDate__c == null )
                {
                    project.SyncDate__c = system.now();
                }

                projectsToUpdate.add( project );
            }

            if( errors.size() > 0 )
            {
                RestAPIHelper.SetRestError( 400, 'BAD_REQUEST', errors );
            }
            else
            {
                update projectsToUpdate;
                RestAPIHelper.SetRestReturn( projectUpdateMap.size(), true );
            }
        }
        catch( Exception ex )
        {
            RestAPIHelper.SetRestError( 400, 'BAD_REQUEST', new List<string>{ ex.getMessage() } );
            Database.rollback( savePoint );
        }
    }
}