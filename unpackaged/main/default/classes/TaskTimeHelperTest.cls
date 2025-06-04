@isTest
public class TaskTimeHelperTest 
{
    @TestSetup
    static void makeData()
    {
        pse__Region__c region = new pse__Region__c(
            Name = 'Region1'
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
            Name = 'Test account'
        );

        insert acc;

        Contact res = new Contact(
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

        pse__Proj__c project = new pse__Proj__c(
            Name = 'Test project',
            pse__Account__c = acc.Id,
            pse__Billing_Type__c = 'Time and Materials',
            pse__Is_Billable__c = true,
            pse__Region__c = region.Id,
            pse__Is_Active__c = true,
            pse__Allow_Timecards_Without_Assignment__c = true,
            pse__Allow_Expenses_Without_Assignment__c = true,
            pse__Project_Manager__c = res.Id
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

        Role_Budget__c roleBudget = new Role_Budget__c(
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

        pse__Assignment__c assignment = new pse__Assignment__c(
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

        pse__Project_Task__c projectTask = new pse__Project_Task__c(
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

    static void makeData2()
    {
        // have to do some of the setup in a second method as the flows and what not kill the SOQL limits ¯\_(ツ)_/¯
        pse__Project_Task__c projectTask = [Select Id from pse__Project_Task__c limit 1];
        pse__Assignment__c assignment = [Select Id from pse__Assignment__c limit 1];
        Contact res = [Select Id from Contact limit 1];
        pse__Proj__c project = [Select Id from pse__Proj__c limit 1];

        pse__Project_Task_Assignment__c pta = new pse__Project_Task_Assignment__c(
            pse__Project_Task__c = projectTask.Id,
            pse__Assignment__c = assignment.Id,
            pse__Resource__c = res.Id,
            pse__Estimated_Hours__c = 100,
            pse__Resource_Role__c = 'Consultant'
        );

        insert pta;

        pse__Timecard_Header__c header = new pse__Timecard_Header__c(
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
            Distance_Sunday__c = 7 );

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
    }

    @isTest
    static void TestInsertTaskTime()
    {
        Test.startTest();
        makeData2();

        pse__Proj__c project = [Select Id from pse__Proj__c limit 1];
        pse__Project_Task_Assignment__c pta = [Select Id, pse__Project_Task__c from pse__Project_Task_Assignment__c limit 1];
        pse__Timecard_Header__c header = [Select Id from pse__Timecard_Header__c limit 1];

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
        update taskTime;

        Test.stopTest();

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

        system.assert( splits.size() == 7, splits.size() );

        decimal distanceTotal = 0;
        for( Task_Time_Split__c split : splits )
        {
            if( split.Distance__c != null )
            {
                distanceTotal += split.Distance__c;
            }
        }

        system.assert( distanceTotal == 28, distanceTotal );
    }

    @isTest
    static void TestUpdateTaskTime()
    {
        Test.startTest();
        makeData2();

        pse__Proj__c project = [Select Id from pse__Proj__c limit 1];
        pse__Project_Task_Assignment__c pta = [Select Id, pse__Project_Task__c from pse__Project_Task_Assignment__c limit 1];
        pse__Timecard_Header__c header = [Select Id from pse__Timecard_Header__c limit 1];

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
        update taskTime;

        taskTime.pse__Thursday_Hours__c = 4;
        taskTime.pse__Saturday_Hours__c = 1;
        update taskTime;

        Test.stopTest();

        List<Task_Time_Split__c> splits = 
            [Select 
                Id, 
                Days__c, 
                Hours__c, 
                Notes__c, 
                Start_Date__c, 
                Sync_Status__c, 
                Task_Time__c 
            from 
                Task_Time_Split__c];

        system.assert( splits.size() == 7, splits.size() );
    }

    @isTest
    static void TestDeleteTaskTime()
    {
        Test.startTest();
        makeData2();

        pse__Proj__c project = [Select Id from pse__Proj__c limit 1];
        pse__Project_Task_Assignment__c pta = [Select Id, pse__Project_Task__c from pse__Project_Task_Assignment__c limit 1];
        pse__Timecard_Header__c header = [Select Id from pse__Timecard_Header__c limit 1];

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

        delete taskTime;

        Test.stopTest();

        List<Task_Time_Split__c> splits = [Select Id from Task_Time_Split__c];

        system.assert( splits.size() == 0, splits.size() );
    }

    @isTest
    static void TestDeleteTimecardHeader()
    {
        Test.startTest();
        makeData2();

        pse__Proj__c project = [Select Id from pse__Proj__c limit 1];
        pse__Project_Task_Assignment__c pta = [Select Id, pse__Project_Task__c from pse__Project_Task_Assignment__c limit 1];
        pse__Timecard_Header__c header = [Select Id from pse__Timecard_Header__c limit 1];

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

        delete header;

        Test.stopTest();

        List<pse__Task_Time__c> taskTimes = [Select Id from pse__Task_Time__c];

        system.assert( taskTimes.size() == 0, taskTimes.size() );

        List<Task_Time_Split__c> splits = [Select Id from Task_Time_Split__c];

        system.assert( splits.size() == 0, splits.size() );
    }

    @isTest
    static void TestInsertTwoTaskTimes()
    {
        Test.startTest();
        makeData2();

        pse__Proj__c project = [Select Id from pse__Proj__c limit 1];
        pse__Project_Task_Assignment__c pta = [Select Id, pse__Project_Task__c from pse__Project_Task_Assignment__c limit 1];
        pse__Timecard_Header__c header = [Select Id from pse__Timecard_Header__c limit 1];

        pse__Task_Time__c taskTime1 = new pse__Task_Time__c(
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

        pse__Task_Time__c taskTime2 = new pse__Task_Time__c(
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

        insert new List<sObject>{ taskTime1, taskTime2 };
        update new List<sObject>{ taskTime1, taskTime2 };

        Test.stopTest();

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

        system.assert( splits.size() == 14, splits.size() );

        decimal distanceTotal = 0;
        for( Task_Time_Split__c split : splits )
        {
            if( split.Distance__c != null )
            {
                distanceTotal += split.Distance__c;
            }
        }

        system.assert( distanceTotal == 28, distanceTotal );
    }

    @isTest
    static void RevokeTimecardTest()
    {
        Test.startTest();
        makeData2();

        pse__Proj__c project = [Select Id from pse__Proj__c limit 1];
        pse__Project_Task_Assignment__c pta = [Select Id, pse__Project_Task__c from pse__Project_Task_Assignment__c limit 1];
        pse__Timecard_Header__c header = [Select Id, pse__Approved__c, pse__Submitted__c from pse__Timecard_Header__c limit 1];

        header.pse__Approved__c = true;
        header.pse__Submitted__c = true;
        update header;

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

        system.assert( splitIds.size() == 7, splitIds.size() );

        TimecardRevokeController con = new TimecardRevokeController( new ApexPages.StandardController( header ) );
        con.Reason = 'This is a reason';
        con.Revoke();

        Test.stopTest();

        for( ApexPages.Message message : ApexPages.getMessages() )
        {
            if( message.getSeverity() != ApexPages.Severity.Confirm )
            {
                system.assert( false, message.getDetail() );
            }
        }

        for( Deleted_Task_Time_Split__c deletedSplit : [Select Id, Task_Time_Split_Id__c from Deleted_Task_Time_Split__c where Timecard__c = :header.Id] )
        {
            system.assert( splitIds.contains( deletedSplit.Task_Time_Split_Id__c) );
        }

        Set<Id> newSplitIds = new Set<Id>();
        for( Task_Time_Split__c split : 
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
                Task_Time_Split__c] )
        {
            system.assert( !splitIds.contains( split.Id ) );
            newSplitIds.add( split.Id );
        }

        system.assert( newSplitIds.size() == 7, newSplitIds.size() );
    }
}