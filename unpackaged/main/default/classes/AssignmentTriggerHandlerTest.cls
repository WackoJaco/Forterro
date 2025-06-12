@isTest
public class AssignmentTriggerHandlerTest 
{
    static pse__Project_Task__c projectTask;
    static pse__Assignment__c assignment;
    static Contact res;
    static pse__Proj__c project;
    static Role_Budget__c roleBudget;
    static pse__Project_Task_Assignment__c pta;

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
    }

    @isTest
    static void TestDeleteAssignment()
    {
        TestSetup1();
        Test.startTest();
        TestSetup2();

        projectTask = [Select Id, Number_of_Resource_Assignments__c from pse__Project_Task__c where Id = :projectTask.Id];
        system.assert( projectTask.Number_of_Resource_Assignments__c == 1 );

        delete assignment;

        Test.stopTest();

        projectTask = [Select Id, Number_of_Resource_Assignments__c from pse__Project_Task__c where Id = :projectTask.Id];
        system.assert( projectTask.Number_of_Resource_Assignments__c == 0 );
    }
}