@RestResource(urlMapping='/miscadjustmentssapi/miscadjustments/*')
global with sharing class MiscAdjustmentsAPI 
{
    public class AppException extends Exception {}

    private final static String BASE_URI = '/miscadjustmentssapi/miscadjustments/';
    private final static integer MAX_RECORDS = 1000;

    global class MiscAdjustment
    {
        public string projectId;
        public string projectName;
        public string customerID;
        public string customerName;
        public string businessUnitId;
        public DateTime syncDate;
        public string syncState;
        public string errorMessage;
        public decimal amount;
        public string invoiceNumber;
        public Date invoiceDate;
        public string Description;
        public string Reason;
        public string recordId;
        public string adjustmentName;
        public string currencyCode;
        public Date effectiveDate;
        public DateTime createdDate;
        public DateTime approvedDate;
        public string approver;
        public string reportedBy;

        global MiscAdjustment()
        {
        }

        public MiscAdjustment( pse__Miscellaneous_Adjustment__c adjustment )
        {
            projectId = adjustment.pse__Project__r.pse__Project_ID__c;
            projectName = adjustment.pse__Project__r.Name;
            customerID = adjustment.pse__Project__r.pse__Account__r.AccountNumber;
            customerName = adjustment.pse__Project__r.pse__Account__r.Name;
            if( adjustment.pse__Project__r.pse__Region__c != null )
            {
                businessUnitId = adjustment.pse__Project__r.pse__Region__r.BU_Code__c;
            }
            syncDate = adjustment.SyncDate__c;
            syncState = adjustment.Sync_Status__c;
            errorMessage = adjustment.ErrorMessage__c;
            amount = Math.abs( adjustment.pse__Amount__c );
            invoiceNumber = adjustment.pse__Invoice_Number__c;
            invoiceDate = adjustment.pse__Invoice_Date__c;
            Description = adjustment.pse__Description__c;
            Reason = adjustment.Reason__c;
            recordId = adjustment.Id;
            adjustmentName = adjustment.Name;
            currencyCode = adjustment.currencyISOcode;
            effectiveDate = adjustment.pse__Effective_Date__c;
            createdDate = adjustment.CreatedDate;
            approvedDate = adjustment.LastModifiedDate;
            approver = adjustment.pse__Approver__r?.Name;
            reportedBy = adjustment.Owner.Name;
            adjustmentName = adjustment.Name;
        }
    }

    global class MiscAdjustmentUpdate
    {
        public string recordId;
        public string invoiceNumber;
        public Date invoiceDate;
        public string errorMessage;
        public string syncState;
        public DateTime syncDate;
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

            List<MiscAdjustment> miscAdjustments = new List<MiscAdjustment>();
            List<string> allowedSyncStates = new List<string>{ 'New', '' };

            for( pse__Miscellaneous_Adjustment__c soAdjustment :
                [Select
                    Id,
                    Name,
                    CreatedDate,
                    LastModifiedDate,
                    pse__Approver__c,
                    pse__Approver__r.Name,
                    Owner.Name,
                    pse__Project__c,
                    pse__Project__r.pse__Project_ID__c,
                    pse__Project__r.Name,
                    pse__Project__r.pse__Account__c,
                    pse__Project__r.pse__Account__r.AccountNumber,
                    pse__Project__r.pse__Account__r.Name,
                    pse__Project__r.pse__Region__c,
                    pse__Project__r.pse__Region__r.BU_Code__c,
                    SyncDate__c,
                    Sync_Status__c,
                    ErrorMessage__c,
                    pse__Amount__c,
                    pse__Invoice_Number__c,
                    pse__Invoice_Date__c,
                    pse__Description__c,
                    Reason__c,
                    currencyISOcode,
                    pse__Effective_Date__c
                From
                    pse__Miscellaneous_Adjustment__c
                Where
                    Sync_Status__c in :allowedSyncStates and
                    pse__Status__c = 'Approved' and
                    pse__Include_In_Financials__c = true and
                    pse__Transaction_Category__c = 'Ready-to-Bill Revenue' and
                    pse__Project__r.pse__Is_Billable__c = true and
                    pse__Project__r.pse__Region__c = :regions[0].Id
                Limit
                    :MAX_RECORDS] )
            {
                MiscAdjustment adjustment = new MiscAdjustment( soAdjustment );
                miscAdjustments.add( adjustment );
            }

            RestAPIHelper.SetRestReturn( miscAdjustments, false );
        }
        catch( Exception ex )
        {
            RestAPIHelper.SetRestError( 400, 'BAD_REQUEST', new List<string>{ ex.getMessage() } );
        }
    }

    @HttpPost
    global static void HandlePost( MiscAdjustmentUpdate[] adjustmentUpdates )
    {
        Savepoint savePoint = Database.setSavepoint();

        try
        {
            Map<string,MiscAdjustmentUpdate> adjustmentUpdateMap = new Map<string,MiscAdjustmentUpdate>();
            for( MiscAdjustmentUpdate adjustmentUpdate : adjustmentUpdates )
            {
                adjustmentUpdateMap.put( adjustmentUpdate.recordId, adjustmentUpdate );
            }

            system.debug( adjustmentUpdateMap );

            Map<string,pse__Miscellaneous_Adjustment__c> adjustments = new Map<string,pse__Miscellaneous_Adjustment__c>();
            for( pse__Miscellaneous_Adjustment__c adjustment : 
                [Select 
                    Id, 
                    Invoice_Number__c,
                    Invoice_Date__c, 
                    Sync_Status__c, 
                    ErrorMessage__c, 
                    SyncDate__c 
                from 
                    pse__Miscellaneous_Adjustment__c 
                where 
                    Id in :adjustmentUpdateMap.keySet()] )
            {
                adjustments.put( adjustment.Id, adjustment );
            }

            system.debug( adjustments );

            List<pse__Miscellaneous_Adjustment__c> adjustmentsToUpdate = new List<pse__Miscellaneous_Adjustment__c>();
            List<string> errors = new List<string>();

            for( MiscAdjustmentUpdate adjustmentUpdate : adjustmentUpdates )
            {
                if( !adjustments.containsKey( adjustmentUpdate.recordId ) )
                {
                    errors.add( 'Miscellaneous adjustment ' + adjustmentUpdate.recordId + ' not found' );
                    continue;
                }

                pse__Miscellaneous_Adjustment__c adjustment = adjustments.get( adjustmentUpdate.recordId );
                adjustment.Sync_Status__c = adjustmentUpdate.syncState;
                adjustment.ErrorMessage__c = adjustmentUpdate.errorMessage;
                adjustment.Invoice_Number__c = adjustmentUpdate.invoiceNumber;
                adjustment.Invoice_Date__c = adjustmentUpdate.invoiceDate;

                if( adjustmentUpdate.syncDate != null )
                {
                    adjustment.SyncDate__c = adjustmentUpdate.syncDate;
                }

                if( adjustmentUpdate.syncState == 'Synced' && adjustment.SyncDate__c == null )
                {
                    adjustment.SyncDate__c = system.now();
                }

                adjustmentsToUpdate.add( adjustment );
            }

            system.debug( errors );

            if( errors.size() > 0 )
            {
                RestAPIHelper.SetRestError( 400, 'BAD_REQUEST', errors );
            }
            else
            {
                update adjustmentsToUpdate;
                RestAPIHelper.SetRestReturn( adjustmentsToUpdate.size(), true );
            }
        }
        catch( Exception ex )
        {
            RestAPIHelper.SetRestError( 400, 'BAD_REQUEST', new List<string>{ ex.getMessage() } );
            Database.rollback( savePoint );
        }
    }
}