public class TriggerOngoingTaskForServiceRequestBatch implements Database.Batchable<sObject>, Database.Stateful
{
    private final Set<string> supportedTypes = new Set<string>
    { 
        'SupportBillable', 
        'SupportCredited', 
        'smallrequest', 
        'Small Work' 
    };

    public List<String> errorMessages;
    private boolean calendarSyncAssignmentWasEnabled;
    private boolean calendarSyncPTAWasEnabled;

    public TriggerOngoingTaskForServiceRequestBatch() 
    {
    }

    public static void scheduleEveryFiveMinutes()
    {
        List<CronTrigger> crons = [Select Id from CronTrigger where CronJobDetail.Name = 'TriggerOngoingTaskForServiceRequest' and CronJobDetail.JobType = '7'];
        if( crons.size() == 0 )
        {
            system.scheduleBatch( new TriggerOngoingTaskForServiceRequestBatch(), 'TriggerOngoingTaskForServiceRequest', 5, 1 );
        }
    }

    public database.querylocator start( Database.BatchableContext bc ) 
    {
        this.errorMessages = new List<String>();
        setSyncAssignmentPTAWithExternalCalendar( false, false );

        if( Test.isRunningTest() )
        {
            this.errorMessages.add( 'This is a test' );
        }

        string query = 
            'Select ' +
            '    Id, ' +
            '    Trigger_Ongoing_Task__c ' +
            'from ' +
            '    ffps_forterro__ServiceRequest__c ' +
            'where ' +
            '    ffps_forterro__Type__c in :supportedTypes and ' +
            '    Trigger_Ongoing_Task__c = false ';
        
        return Database.getQueryLocator( query );
    }

    public void execute( Database.BatchableContext bc, List<sObject> records )
    {
        try
        {
            for( sObject rec : records )
            {
                rec.put( 'Trigger_Ongoing_Task__c', true );
            }

            update records;
        }
        catch( Exception ex )
        {
            if( records.size() == 1 ) 
            {
                errorMessages.add( records[0].Id + ': ' + ex.getMessage() + ' - ' + ex.getStackTraceString() );
            }
            else
            {
                errorMessages.add( ex.getMessage() + ' - ' + ex.getStackTraceString() );
            }
        }
    }

    public void finish( Database.BatchableContext BC ) 
    {
        if( this.errorMessages.size() > 0 )
        {
            AsyncApexJob batchJob = [Select Id, CreatedBy.Email from AsyncApexJob where Id =:BC.getJobId()];
            sendEmail( batchJob.CreatedBy.Email );
        }

        setSyncAssignmentPTAWithExternalCalendar( calendarSyncAssignmentWasEnabled, calendarSyncPTAWasEnabled );

        if( !test.isRunningTest() )
        {
            scheduleEveryFiveMinutes();
        }
    }

    public void sendEmail( string to )
    {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setToAddresses( new String[] { to } );

        string body = '<p>The ongoing task service request job has failed!</p>';

        mail.setSubject( 'The ongoing task service request job has failed!' );
        body += '<p>The following errors occurred:</p><ul>';

        for( string s : errorMessages )
        {
            body += '<li>' + s + '</li>';
        }

        body += '</ul>';
        
        body += '<p>User: ' + UserInfo.getUserName() + ', Org Id: ' + UserInfo.getOrganizationId() + '</p>';
		body += '<p>Certinia</p>';

		mail.setHtmlBody( body );

        List<OrgWideEmailAddress> addresses = [Select Id from OrgWideEmailAddress where DisplayName = 'Salesforce No Reply'];
        if( addresses.size() > 0 )
        {
            mail.setOrgWideEmailAddressId( addresses[0].Id );
        }

        try 
        {
		    Messaging.sendEmail( new Messaging.SingleEmailMessage[] { mail } );
        }
        catch( System.EmailException sex ) 
        {
        }
    }

    public void setSyncAssignmentPTAWithExternalCalendar( boolean enableAssignment, boolean enablePTA )
    {
        // we switch this off for every job as it causes issues with assignment generation
        List<pse__External_Calendar_Events_Settings__c> settings = 
            [select 
                Id, 
                pse__Sync_Assignment_With_External_Calendar__c,
                pse__Sync_PTA_With_External_Calendar__c 
            from 
                pse__External_Calendar_Events_Settings__c
            where
                SetupOwnerId = :UserInfo.getuserId()];

        calendarSyncAssignmentWasEnabled = false;
        calendarSyncPTAWasEnabled = false;

        for( pse__External_Calendar_Events_Settings__c setting : settings )
        {
            if( setting.pse__Sync_Assignment_With_External_Calendar__c )
            {
                calendarSyncAssignmentWasEnabled = true;
            }
            setting.pse__Sync_Assignment_With_External_Calendar__c = enableAssignment;

            if( setting.pse__Sync_PTA_With_External_Calendar__c )
            {
                calendarSyncPTAWasEnabled = true;
            }
            setting.pse__Sync_PTA_With_External_Calendar__c = enablePTA;
        }

        update settings;
    }
}