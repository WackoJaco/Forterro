public class ClearStagingDataBatch implements Database.Batchable<sObject>, Database.Stateful
{
    public List<string> errorMessages;

    public ClearStagingDataBatch() 
    {
    }

    public database.querylocator start( Database.BatchableContext bc ) 
    {
        errorMessages = new List<string>();

        string query = 
            'Select ' +
            '    Id, Project__c, Import_Status__c ' +
            'from ' +
            '    Staging_Project__c ' +
            'where ' +
            '    Project__c != null ';

        return Database.getQueryLocator( query );
    }

    public void execute( Database.BatchableContext bc, List<sObject> records )
    {
        try
        {
            Set<Id> projectIds = new Set<Id>();
            for( Staging_Project__c sp : (List<Staging_Project__c>)records )
            {
                if( sp.Project__c != null )
                {
                    projectIds.add( sp.Project__c );
                }
            }

            delete [SELECT ID FROM pse__Timecard_Header__c WHERE pse__Project__c in :projectIds];
            delete [SELECT ID FROM pse__Expense_Report__c WHERE pse__Project__c in :projectIds];
            delete [SELECT ID FROM pse__Milestone__c WHERE pse__Project__c in :projectIds];
            delete [SELECT ID FROM pse__Resource_Request__c WHERE pse__Project__c in :projectIds];
            delete [SELECT ID FROM pse__Assignment__c WHERE pse__Project__c in :projectIds];
            delete [SELECT ID FROM pse__Project_Task__c WHERE pse__Project__c in :projectIds];
            delete [SELECT ID FROM pse__Budget_Header__c WHERE pse__Project__c in :projectIds];
            delete [SELECT ID FROM pse__Budget_Allocation__c WHERE pse__Project__c in :projectIds];
            delete [SELECT ID FROM pse__Budget__c WHERE pse__Project__c in :projectIds];
            delete [SELECT ID FROM pse__Miscellaneous_Adjustment__c WHERE pse__Project__c in :projectIds];
            delete [SELECT ID FROM pse__Proj__c WHERE Id in :projectIds];

            delete [select id from role_budget__c where Project__c in :projectIds and external_id__c != null];
        }
        catch( Exception ex )
        {
            errorMessages.add( records[0].Id + ': ' + ex.getMessage() );
        }
    }

    public void finish( Database.BatchableContext BC ) 
    {
        if( this.errorMessages.size() > 0 )
        {
            AsyncApexJob batchJob = [Select Id, CreatedBy.Email from AsyncApexJob where Id =:BC.getJobId()];
            sendEmail( batchJob.CreatedBy.Email );
        }
    }

    public void sendEmail( string to ) 
    {
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setToAddresses( new String[] {to} );

        string body = '<p>The data clear down process completed with errors</p>';

        mail.setSubject( 'The data clear down process has completed with errors!' );
        body += '<p>The following errors occurred:</p><ul>';
        for( String s : errorMessages ) 
        {
            body += '<li>' + s + '</li>';
        }
        body += '</ul>';

        /*Data_Import_Results__c res = new Data_Import_Results__c(
            Errors__c = body
        );
        insert res;*/

        body += '<p>User: ' + UserInfo.getUserName() + ', Org Id: ' + UserInfo.getOrganizationId() + '</p>';

		body += '<p>Certinia</p>';

		mail.setHtmlBody( body );

        try 
        {
		    Messaging.sendEmail( new Messaging.SingleEmailMessage[] { mail } );
        }
        catch( System.EmailException sex ) 
        {
        }
    }
}