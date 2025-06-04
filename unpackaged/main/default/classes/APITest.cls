@isTest
public class APITest 
{
    static pse__Project_Task__c projectTask;
    static pse__Assignment__c assignment;
    static Contact res;
    static pse__Proj__c project;
    static Role_Budget__c roleBudget;
    static pse__Project_Task_Assignment__c pta;
    static pse__Timecard_Header__c header;
    static pse__Miscellaneous_Adjustment__c adjustment;

    static void TestSetup1()
    {
        pse__Region__c region = new pse__Region__c(
            Name = 'Region1',
            BU_Code__c = 'ABCDEF'
        );

        insert region;

        pse__Work_Calendar__c cal = new pse__Work_Calendar__c(
            Name ='Test Calender',
            pse__Week_Start_Day__c = 'Sunday',
            pse__Sunday_Hours__c = 0.0,
            pse__Monday_Hours__c = 8.0,
            pse__Tuesday_Hours__c = 8.0,
            pse__Wednesday_Hours__c = 8.0,
            pse__Thursday_Hours__c = 8.0,
            pse__Friday_Hours__c = 8.0,
            pse__Saturday_Hours__c = 0.0
        );

        insert cal;

        Account acc = new Account(
            Name = 'Test account',
            AccountNumber = '123456'
        );

        insert acc;

        res = new Contact(
            AccountId = acc.Id,
            FirstName = 'Test',
            LastName = 'Resource',
            pse__Region__c = region.Id,
            CurrencyIsoCode = 'EUR',
            pse__Is_Resource_Active__c = true,
            pse__Is_Resource__c = true,
            pse__Resource_Role__c = 'Consultant',
            pse__Default_Cost_Rate__c = 80.0,
            pse__Work_Calendar__c = cal.Id,
            pse__Salesforce_User__c = UserInfo.getUserId()
        );

        insert res;

        project = new pse__Proj__c(
            Name = 'Test project',
            pse__Account__c = acc.Id,
            pse__Billing_Type__c = 'Time and Materials',
            pse__Is_Billable__c = true,
            pse__Region__c = region.Id,
            pse__Is_Active__c = true,
            pse__Allow_Timecards_Without_Assignment__c = true,
            pse__Allow_Expenses_Without_Assignment__c = true,
            pse__Project_Manager__c = res.Id,
            Sync_Status__c = 'New'
        );

        insert project;

        pse__Budget__c budget = new pse__Budget__c(
            Name= 'Test Budget',
            pse__Project__c = project.Id,
            pse__Type__c = 'Customer Purchase Order',
            pse__Amount__c = 5000,
            pse__Status__c = 'Approved',
            pse__Include_In_Financials__c = true, 
            pse__Approved__c = true,
            pse__Effective_Date__c = Date.today()
        );

        insert budget;

        pse__Schedule__c sched = new pse__Schedule__c(
            pse__Start_Date__c = date.newinstance( system.today().year(), 1, 1 ),
            pse__End_Date__c = date.newinstance( system.today().year(), 12, 31 ),
            pse__Monday_Hours__c = 0, 
            pse__Tuesday_Hours__c = 0,
            pse__Wednesday_Hours__c = 0,
            pse__Thursday_Hours__c = 0,
            pse__Friday_Hours__c = 0,
            pse__Saturday_Hours__c = 0,
            pse__Sunday_Hours__c = 0
        );

        insert sched;

        roleBudget = new Role_Budget__c(
            Project__c = project.Id,
            Hours_Budget__c = 100,
            Rate__c = 50,
            Role__c = 'Consultant'
        );

        insert roleBudget;

        project.pse__Stage__c = 'In Progress';
        update project;

        pse__Permission_Control__c perm = new pse__Permission_Control__c(
            pse__User__c = UserInfo.getUserId(),
            pse__Region__c = region.Id,
            pse__Cascading_Permission__c = true,
            pse__Timecard_Ops_Edit__c = true,
            pse__Timecard_Entry__c = true,
            pse__Staffing__c = true,
            pse__Skills_And_Certifications_View__c = true,
            pse__Skills_And_Certifications_Entry__c = true, 
            pse__Resource_Request_Entry__c = true,
            pse__Invoicing__c = true,
            pse__Forecast_View__c = true,
            pse__Forecast_Edit__c = true,
            pse__Expense_Ops_Edit__c = true,
            pse__Expense_Entry__c = true,
            pse__Billing__c = true
        );

        insert perm;

        assignment = new pse__Assignment__c(
            Name = 'AssignmentName',
            pse__Project__c = project.Id,
            pse__Schedule__c = sched.Id,
            pse__Bill_Rate__c = 10.0,
            pse__Is_Billable__c = true,
            pse__Cost_Rate_Amount__c = 80.0,
            CurrencyIsoCode = 'EUR',
            pse__Resource__c = res.Id,
            pse__Role__c = 'Consultant',
            Role_Budget__c = roleBudget.Id
        );

        insert assignment;

        projectTask = new pse__Project_Task__c(
            Name = 'Design',
            pse__Actual_Start_Date_Time__c = DateTime.newInstance( system.today().tostartOfMonth().addMonths( -2 ), Time.newInstance( 11, 0, 0, 0 ) ),
            pse__Actual_End_Date_Time__c = DateTime.newInstance( system.today().tostartOfMonth().addMonths( 2 ).addDays( -1 ), Time.newInstance( 11, 0, 0, 0 ) ), 
            pse__End_Date_Time__c = DateTime.newInstance( system.today().tostartOfMonth().addMonths( 3 ).addDays( -1 ), Time.newInstance( 11, 0, 0, 0 ) ), 
            pse__Start_Date_Time__c = DateTime.newInstance( system.today().tostartOfMonth().addMonths( -2 ), Time.newInstance( 11, 0, 0, 0 ) ),
            pse__Project__c = project.Id,
            pse__Status__c = 'Planned',
            pse__Estimated_Hours__c = 100
        );

        insert projectTask;      
    }

    private static void TestSetup2()
    {
        // have to do this after Test.startTest() to avoid hitting the governor limits
        pta = new pse__Project_Task_Assignment__c(
            pse__Project_Task__c = projectTask.Id,
            pse__Assignment__c = assignment.Id,
            pse__Resource__c = res.Id,
            pse__Estimated_Hours__c = 100,
            Role_Budget__c = roleBudget.Id,
            pse__Resource_Role__c = 'Consultant'
        );

        insert pta;

        header = new pse__Timecard_Header__c(
            pse__Assignment__c = assignment.Id,
            pse__Project__c = project.Id,
            pse__Resource__c = res.Id,
            pse__Start_Date__c = Date.today().tostartOfWeek().addDays( -7 ),
            pse__End_Date__c = Date.today().tostartOfWeek().addDays( -1 ),
            Distance_Monday__c = 1,
            Distance_Tuesday__c = 2,
            Distance_Wednesday__c = 3,
            Distance_Thursday__c = 4,
            Distance_Friday__c = 5,
            Distance_Saturday__c = 6,
            Distance_Sunday__c = 7,
            pse__Bill_Rate__c = 10.0,
            pse__Status__c = 'Approved',
            pse__Approved__c = true,
            pse__Include_In_Financials__c = true,
            pse__Submitted__c = true );

        insert header;

        pse__Timecard__c timecard = new pse__Timecard__c(
            pse__Project__c = project.Id,
            pse__Resource__c = res.Id,
            pse__Assignment__c = assignment.Id,
            pse__Timecard_Header__c = header.Id,
            pse__Start_Date__c = Date.today().tostartOfWeek().addDays( -7 ),
            pse__End_Date__c = Date.today().tostartOfWeek().addDays( -1 ),
            pse__Monday_Hours__c = 8.0,
            pse__Tuesday_Hours__c = 8.0,
            pse__Wednesday_Hours__c = 8.0,
            pse__Thursday_Hours__c = 8.0,
            pse__Friday_Hours__c = 8.0,
            pse__Total_Hours__c = 40.0,
            pse__Billable__c = true );

        insert timecard;

        Task_Time_Split_Settings__c settings = new Task_Time_Split_Settings__c(
            Enable_Task_Time_Trigger__c = true,
            Enable_Timecard_Trigger__c = true
        );

        insert settings;

        adjustment = new pse__Miscellaneous_Adjustment__c(
            Name= 'Test Miscellaneous Adjustment',
            pse__Project__c = project.Id,
            CurrencyIsoCode = 'EUR',
            pse__Amount__c = 100,
            pse__Effective_Date__c = system.today(),
            pse__Transaction_Category__c = 'Ready-to-Bill Revenue',
            pse__Status__c = 'Approved',
            pse__Include_In_Financials__c = true,
            Reason__c = 'Product Issue' );

        insert adjustment;
    }

    @isTest static void GetProjectTest()
    {
        TestSetup1();
        Test.startTest();
        TestSetup2();

        String rootUrl = URL.getOrgDomainUrl().toExternalForm() + '/';
        RestRequest request = new RestRequest();
        request.requestUri = rootUrl + 'services/apexrest/projectsapi/projects/ABCDEF';
        request.httpMethod = 'GET';
        RestContext.request = request;
        RestContext.response = new RestResponse();

        ProjectAPI.HandleGet();

        Test.stopTest();

        List<ProjectAPI.Project> projects = (List<ProjectAPI.Project>)JSON.deserialize( RestContext.response.responseBody.toString(), List<ProjectAPI.Project>.class );
        system.assert( projects.size() > 0 );
        system.assert( projects[0].buCode == 'ABCDEF' );
    }

    @isTest static void UpdateProjectTest()
    {
        TestSetup1();
        Test.startTest();
        TestSetup2();

        project = [Select id, pse__Project_ID__c from pse__Proj__c where Id = :project.Id];
        
        List<ProjectAPI.ProjectUpdate> updates = new List<ProjectAPI.ProjectUpdate>();
        ProjectAPI.ProjectUpdate upd = new ProjectAPI.ProjectUpdate();
        upd.projectId = project.pse__Project_ID__c;
        upd.syncState = 'Synced';
        updates.add( upd );

        String rootUrl = URL.getOrgDomainUrl().toExternalForm() + '/';
        RestRequest request = new RestRequest();
        request.requestUri = rootUrl + '/services/apexrest/projectsapi/projects/';
        request.addHeader('Content-Type', 'application/json');
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf( '{"projectUpdates": ' + JSON.serialize( updates, true ) + '}' );
        RestContext.request = request;
        RestContext.response = new RestResponse();

        ProjectAPI.HandlePost( updates );

        Test.stopTest();

        string res = string.valueOf( JSON.deserialize( RestContext.response.responseBody.toString(), string.class ) );
        system.assert( res == '1' );
    }

    @isTest static void GetTaskTimesTest()
    {
        TestSetup1();
        Test.startTest();
        TestSetup2();

        pse__Task_Time__c taskTime = new pse__Task_Time__c(
            pse__Project_Task__c = pta.pse__Project_Task__c,
            pse__Project_Task_Assignment__c = pta.Id,
            pse__Timecard__c = header.Id,
            pse__Monday_Hours__c = 6,
            pse__Tuesday_Hours__c = 5,
            pse__Wednesday_Hours__c = 4,
            pse__Thursday_Hours__c = 3,
            pse__Friday_Hours__c = 2,
            pse__Saturday_Hours__c = 0,
            pse__Sunday_Hours__c = 0,
            pse__Monday_Notes__c = 'mon',
            pse__Tuesday_Notes__c = 'tue',
            pse__Wednesday_Notes__c = 'wed',
            pse__Thursday_Notes__c = 'thu',
            pse__Friday_Notes__c = 'fri',
            pse__Saturday_Notes__c = 'sat',
            pse__Sunday_Notes__c = 'sun',
            pse__Start_Date__c = system.today().tostartOfWeek().addDays( -7 )
        );

        insert taskTime;

        String rootUrl = URL.getOrgDomainUrl().toExternalForm() + '/';
        RestRequest request = new RestRequest();
        request.requestUri = rootUrl + 'services/apexrest/tasktimeapi/tasktimes/ABCDEF';
        request.httpMethod = 'GET';
        RestContext.request = request;
        RestContext.response = new RestResponse();

        TaskTimeAPI.HandleGet();

        Test.stopTest();

        List<TaskTimeAPI.TimeEntry> entries = (List<TaskTimeAPI.TimeEntry>)JSON.deserialize( RestContext.response.responseBody.toString(), List<TaskTimeAPI.TimeEntry>.class );
        system.assert( entries.size() > 0 );
        system.assert( entries[0].businessUnitId == 'ABCDEF' );
    }

    @isTest static void UpdateTaskTimesTest()
    {
        TestSetup1();
        Test.startTest();
        TestSetup2();

        pse__Task_Time__c taskTime = new pse__Task_Time__c(
            pse__Project_Task__c = pta.pse__Project_Task__c,
            pse__Project_Task_Assignment__c = pta.Id,
            pse__Timecard__c = header.Id,
            pse__Monday_Hours__c = 6,
            pse__Tuesday_Hours__c = 5,
            pse__Wednesday_Hours__c = 4,
            pse__Thursday_Hours__c = 3,
            pse__Friday_Hours__c = 2,
            pse__Saturday_Hours__c = 0,
            pse__Sunday_Hours__c = 0,
            pse__Monday_Notes__c = 'mon',
            pse__Tuesday_Notes__c = 'tue',
            pse__Wednesday_Notes__c = 'wed',
            pse__Thursday_Notes__c = 'thu',
            pse__Friday_Notes__c = 'fri',
            pse__Saturday_Notes__c = 'sat',
            pse__Sunday_Notes__c = 'sun',
            pse__Start_Date__c = system.today().tostartOfWeek().addDays( -7 )
        );

        insert taskTime;

        List<TaskTimeAPI.TimeEntryUpdate> updates = new List<TaskTimeAPI.TimeEntryUpdate>();
        TaskTimeAPI.TimeEntryUpdate upd = new TaskTimeAPI.TimeEntryUpdate();
        upd.timeEntryId = [Select Id from Task_Time_Split__c limit 1].Id;
        upd.syncState = 'Synced';
        updates.add( upd );

        String rootUrl = URL.getOrgDomainUrl().toExternalForm() + '/';
        RestRequest request = new RestRequest();
        request.requestUri = rootUrl + 'services/apexrest/tasktimeapi/tasktimes/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf( '{"timeEntries": ' + JSON.serialize( updates, true ) + '}' );
        RestContext.request = request;
        RestContext.response = new RestResponse();

        TaskTimeAPI.HandlePost( updates );

        Test.stopTest();

        string res = string.valueOf( JSON.deserialize( RestContext.response.responseBody.toString(), string.class ) );
        system.assert( res == '1' );
    }

    @isTest static void GetMiscAdjustmentTest()
    {
        TestSetup1();
        Test.startTest();
        TestSetup2();

        String rootUrl = URL.getOrgDomainUrl().toExternalForm() + '/';
        RestRequest request = new RestRequest();
        request.requestUri = rootUrl + 'services/apexrest/miscadjustmentssapi/miscadjustments/ABCDEF';
        request.httpMethod = 'GET';
        RestContext.request = request;
        RestContext.response = new RestResponse();

        MiscAdjustmentsAPI.HandleGet();

        Test.stopTest();

        system.debug( RestContext.response.responseBody.toString() );

        List<MiscAdjustmentsAPI.MiscAdjustment> adjustments = (List<MiscAdjustmentsAPI.MiscAdjustment>)JSON.deserialize( RestContext.response.responseBody.toString(), List<MiscAdjustmentsAPI.MiscAdjustment>.class );
        system.assert( adjustments.size() > 0 );
        system.assert( adjustments[0].businessUnitId == 'ABCDEF' );
    }

    @isTest static void UpdateMiscAdjustmentTest()
    {
        TestSetup1();
        Test.startTest();
        TestSetup2();
        
        List<MiscAdjustmentsAPI.MiscAdjustmentUpdate> updates = new List<MiscAdjustmentsAPI.MiscAdjustmentUpdate>();
        MiscAdjustmentsAPI.MiscAdjustmentUpdate upd = new MiscAdjustmentsAPI.MiscAdjustmentUpdate();
        upd.recordId = adjustment.Id;
        upd.syncState = 'Synced';
        upd.invoiceNumber = '12345678';
        upd.invoiceDate = system.today();
        updates.add( upd );

        String rootUrl = URL.getOrgDomainUrl().toExternalForm() + '/';
        RestRequest request = new RestRequest();
        request.requestUri = rootUrl + '/services/apexrest/miscadjustmentssapi/miscadjustments/';
        request.addHeader('Content-Type', 'application/json');
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf( '{"adjustmentUpdates": ' + JSON.serialize( updates, true ) + '}' );
        RestContext.request = request;
        RestContext.response = new RestResponse();

        MiscAdjustmentsAPI.HandlePost( updates );

        Test.stopTest();

        string res = string.valueOf( JSON.deserialize( RestContext.response.responseBody.toString(), string.class ) );
        system.assert( res == '1' );
    }

    @isTest static void GetDeletedTaskTimesTest()
    {
        TestSetup1();
        Test.startTest();
        TestSetup2();

        pse__Task_Time__c taskTime = new pse__Task_Time__c(
            pse__Project_Task__c = projectTask.Id,
            pse__Project_Task_Assignment__c = pta.Id,
            pse__Timecard__c = header.Id,
            pse__Monday_Hours__c = 6,
            pse__Tuesday_Hours__c = 5,
            pse__Wednesday_Hours__c = 4,
            pse__Thursday_Hours__c = 3,
            pse__Friday_Hours__c = 2,
            pse__Saturday_Hours__c = 0,
            pse__Sunday_Hours__c = 0,
            pse__Monday_Notes__c = 'mon',
            pse__Tuesday_Notes__c = 'tue',
            pse__Wednesday_Notes__c = 'wed',
            pse__Thursday_Notes__c = 'thu',
            pse__Friday_Notes__c = 'fri',
            pse__Saturday_Notes__c = 'sat',
            pse__Sunday_Notes__c = 'sun',
            pse__Start_Date__c = system.today().tostartOfWeek().addDays( -7 )
        );

        insert taskTime;
        update taskTime;

        Set<Id> splitIds = new Set<Id>();
        List<Task_Time_Split__c> splits = 
            [Select 
                Id, 
                Days__c, 
                Hours__c, 
                Notes__c, 
                Start_Date__c, 
                Sync_Status__c, 
                Task_Time__c,
                Distance__c,
                Per_Diem__c 
            from 
                Task_Time_Split__c];

        for( Task_Time_Split__c split : splits )
        {
            splitIds.add( split.Id );
            split.Sync_Status__c = 'Synced';
        }

        update splits;

        TimecardRevokeController con = new TimecardRevokeController( new ApexPages.StandardController( header ) );
        con.preCheck();
        con.Reason = 'This is a reason';
        con.Revoke();

        for( ApexPages.Message message : ApexPages.getMessages() )
        {
            if( message.getSeverity() != ApexPages.Severity.Confirm )
            {
                system.assert( false, message.getDetail() );
            }
        }

        String rootUrl = URL.getOrgDomainUrl().toExternalForm() + '/';
        RestRequest request = new RestRequest();
        request.requestUri = rootUrl + 'services/apexrest/tasktimeapi/deletedtasktimes/ABCDEF';
        request.httpMethod = 'GET';
        RestContext.request = request;
        RestContext.response = new RestResponse();

        DeletedTaskTimeAPI.HandleGet();

        Test.stopTest();

        system.debug( RestContext.response.responseBody.toString() );

        List<DeletedTaskTimeAPI.DeletedTimeEntry> deletedTimeEntries = (List<DeletedTaskTimeAPI.DeletedTimeEntry>)JSON.deserialize( RestContext.response.responseBody.toString(), List<DeletedTaskTimeAPI.DeletedTimeEntry>.class );
        system.assert( deletedTimeEntries.size() > 0 );
    }

    @isTest static void UpdateDeletedTaskTimesTest()
    {
        TestSetup1();
        Test.startTest();
        TestSetup2();

        pse__Task_Time__c taskTime = new pse__Task_Time__c(
            pse__Project_Task__c = projectTask.Id,
            pse__Project_Task_Assignment__c = pta.Id,
            pse__Timecard__c = header.Id,
            pse__Monday_Hours__c = 6,
            pse__Tuesday_Hours__c = 5,
            pse__Wednesday_Hours__c = 4,
            pse__Thursday_Hours__c = 3,
            pse__Friday_Hours__c = 2,
            pse__Saturday_Hours__c = 0,
            pse__Sunday_Hours__c = 0,
            pse__Monday_Notes__c = 'mon',
            pse__Tuesday_Notes__c = 'tue',
            pse__Wednesday_Notes__c = 'wed',
            pse__Thursday_Notes__c = 'thu',
            pse__Friday_Notes__c = 'fri',
            pse__Saturday_Notes__c = 'sat',
            pse__Sunday_Notes__c = 'sun',
            pse__Start_Date__c = system.today().tostartOfWeek().addDays( -7 )
        );

        insert taskTime;
        update taskTime;

        Set<Id> splitIds = new Set<Id>();
        List<Task_Time_Split__c> splits = 
            [Select 
                Id, 
                Days__c, 
                Hours__c, 
                Notes__c, 
                Start_Date__c, 
                Sync_Status__c, 
                Task_Time__c,
                Distance__c,
                Per_Diem__c 
            from 
                Task_Time_Split__c];

        for( Task_Time_Split__c split : splits )
        {
            splitIds.add( split.Id );
            split.Sync_Status__c = 'Synced';
        }

        update splits;

        TimecardRevokeController con = new TimecardRevokeController( new ApexPages.StandardController( header ) );
        con.Reason = 'This is a reason';
        con.Revoke();

        List<DeletedTaskTimeAPI.DeletedTimeEntryUpdate> updates = new List<DeletedTaskTimeAPI.DeletedTimeEntryUpdate>();
        for( Deleted_Task_Time_Split__c deletedSplit : [Select Id, Task_Time_Split_Id__c from Deleted_Task_Time_Split__c] )
        {
            DeletedTaskTimeAPI.DeletedTimeEntryUpdate up = new DeletedTaskTimeAPI.DeletedTimeEntryUpdate();
            up.syncState = 'Synced';
            up.revokeState = 'Completed';
            up.timeEntryId = deletedSplit.Task_Time_Split_Id__c;
            updates.add( up );
        }

        String rootUrl = URL.getOrgDomainUrl().toExternalForm() + '/';
        RestRequest request = new RestRequest();
        request.requestUri = rootUrl + '/services/apexrest/tasktimeapi/deletedtasktimes/';
        request.addHeader('Content-Type', 'application/json');
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf( '{"timeEntries": ' + JSON.serialize( updates, true ) + '}' );
        RestContext.request = request;
        RestContext.response = new RestResponse();

        DeletedTaskTimeAPI.HandlePost( updates );

        Test.stopTest();

        string res = string.valueOf( JSON.deserialize( RestContext.response.responseBody.toString(), string.class ) );
        system.assert( res == string.valueOf( splits.size() ), res );
    }
}