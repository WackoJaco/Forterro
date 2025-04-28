@isTest
public class ProjectTaskHelperTest 
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
            Role__c = 'Consultant',
            Reference__c = 'CON1'
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
            pse__Status__c = 'Draft',
            pse__Estimated_Hours__c = 100,
            Role_Budget__c = 'CON1'
        );

        pse__Project_Task__c projectTask2 = new pse__Project_Task__c(
            Name = 'Not Design',
            pse__Actual_Start_Date_Time__c = DateTime.newInstance( system.today().tostartOfMonth().addMonths( -2 ), Time.newInstance( 11, 0, 0, 0 ) ),
            pse__Actual_End_Date_Time__c = DateTime.newInstance( system.today().tostartOfMonth().addMonths( 2 ).addDays( -1 ), Time.newInstance( 11, 0, 0, 0 ) ), 
            pse__End_Date_Time__c = DateTime.newInstance( system.today().tostartOfMonth().addMonths( 3 ).addDays( -1 ), Time.newInstance( 11, 0, 0, 0 ) ), 
            pse__Start_Date_Time__c = DateTime.newInstance( system.today().tostartOfMonth().addMonths( -2 ), Time.newInstance( 11, 0, 0, 0 ) ),
            pse__Project__c = project.Id,
            pse__Status__c = 'Draft',
            pse__Estimated_Hours__c = 10,
            Role_Budget__c = 'CON1'
        );

        insert new List<pse__Project_Task__c>{ projectTask, projectTask2 };

        pse__Project_Task_Assignment__c pta = new pse__Project_Task_Assignment__c(
            pse__Project_Task__c = projectTask.Id,
            pse__Assignment__c = assignment.Id,
            pse__Resource__c = res.Id,
            pse__Estimated_Hours__c = 100,
            pse__Resource_Role__c = 'Consultant'
        );

        insert pta;
    }

    @isTest
    static void ChangeRoleBudgetOnSimpleTask()
    {
        Test.startTest();

        Role_Budget__c roleBudget = new Role_Budget__c(
            Project__c = [Select Id from pse__Proj__c limit 1].Id,
            Hours_Budget__c = 150,
            Rate__c = 40,
            Role__c = 'Consultant',
            Reference__c = 'CON2'
        );

        insert roleBudget;

        pse__Project_Task__c projectTask = [Select Id, Role_Budget_Link__c, Role_Budget__c from pse__Project_Task__c where Name = 'Design' limit 1];
        projectTask.Role_Budget__c = 'CON2';
        projectTask.Role_Budget_Link__c = roleBudget.Id;
        update projectTask;

        pse__Project_Task_Assignment__c pta = [Select Id, Role_Budget__c, Role_Budget__r.Reference__c from pse__Project_Task_Assignment__c limit 1];
        pse__Assignment__c assignment = [Select Id, Role_Budget__c, Role_Budget__r.Reference__c from pse__Assignment__c limit 1];

        Test.stopTest();

        system.assert( pta.Role_Budget__c == roleBudget.Id, pta.Role_Budget__r?.Reference__c );
        system.assert( assignment.Role_Budget__c == roleBudget.Id, assignment.Role_Budget__r?.Reference__c );
    }

    @isTest
    static void ChangeRoleBudgetOnSimpleTaskWithRR()
    {
        pse__Proj__c project = [Select Id from pse__Proj__c limit 1];
        pse__Schedule__c sched = [Select Id from pse__Schedule__c limit 1];
        Contact res = [Select Id from Contact limit 1];
        Role_Budget__c originalRoleBudget = [Select Id from Role_Budget__c limit 1];
        pse__Assignment__c assignment = [Select Id from pse__Assignment__c limit 1];
        
        Test.startTest();

        pse__Resource_Request__c resourceRequest = new pse__Resource_Request__c(
            pse__Assignment__c = assignment.Id,
            pse__Project__c = project.Id,
            pse__Resource__c = res.Id,
            pse__Start_Date__c = system.today(),
            pse__End_Date__c = system.today().addDays( 14 ),
            pse__SOW_Hours__c = 20,
            pse__Region__c = [Select Id from pse__Region__c limit 1].Id,
            pse__Resource_Role__c = 'Consultant',
            Role_Budget__c = originalRoleBudget.Id
        );

        insert resourceRequest;

        pse__Project_Task_Assignment__c pta = [Select Id, pse__Resource_Request__c from pse__Project_Task_Assignment__c limit 1];
        pta.pse__Resource_Request__c = resourceRequest.Id;
        update pta;

        Role_Budget__c roleBudget = new Role_Budget__c(
            Project__c = [Select Id from pse__Proj__c limit 1].Id,
            Hours_Budget__c = 150,
            Rate__c = 40,
            Role__c = 'Consultant',
            Reference__c = 'CON2'
        );

        insert roleBudget;

        pse__Project_Task__c projectTask = [Select Id, Role_Budget_Link__c, Role_Budget__c from pse__Project_Task__c where Name = 'Design' limit 1];
        projectTask.Role_Budget__c = 'CON2';
        projectTask.Role_Budget_Link__c = roleBudget.Id;
        update projectTask;

        pta = [Select Id, Role_Budget__c, Role_Budget__r.Reference__c from pse__Project_Task_Assignment__c limit 1];
        assignment = [Select Id, Role_Budget__c, Role_Budget__r.Reference__c from pse__Assignment__c limit 1];
        resourceRequest = [Select Id, Role_Budget__c, Role_Budget__r.Reference__c from pse__Resource_Request__c where Id = :resourceRequest.Id];

        Test.stopTest();

        system.assert( pta.Role_Budget__c == roleBudget.Id, pta.Role_Budget__r?.Reference__c );
        system.assert( assignment.Role_Budget__c == roleBudget.Id, assignment.Role_Budget__r?.Reference__c );

        // and the resource request should use the new role budget
        system.assert( resourceRequest.Role_Budget__c == roleBudget.Id, resourceRequest.Role_Budget__r?.Reference__c );
    }

    @isTest
    static void ChangeRoleBudgetOnTaskWithOtherTasks()
    {
        Test.startTest();

        pse__Proj__c project = [Select Id from pse__Proj__c limit 1];
        pse__Schedule__c sched = [Select Id from pse__Schedule__c limit 1];
        Contact res = [Select Id from Contact limit 1];
        Role_Budget__c roleBudget = [Select Id from Role_Budget__c limit 1];
        pse__Assignment__c assignment = [Select Id from pse__Assignment__c limit 1];

        pse__Project_Task__c projectTask = [Select Id, Role_Budget__c, Role_Budget_Link__c from pse__Project_Task__c where Name = 'Not Design' limit 1];

        pse__Project_Task_Assignment__c pta = new pse__Project_Task_Assignment__c(
            pse__Project_Task__c = projectTask.Id,
            pse__Assignment__c = assignment.Id,
            pse__Resource__c = res.Id,
            pse__Estimated_Hours__c = 20,
            pse__Resource_Role__c = 'Consultant'
        );

        insert pta;

        Role_Budget__c roleBudget2 = new Role_Budget__c(
            Project__c = [Select Id from pse__Proj__c limit 1].Id,
            Hours_Budget__c = 150,
            Rate__c = 40,
            Role__c = 'Consultant',
            Reference__c = 'CON2'
        );

        insert roleBudget2;

        projectTask.Role_Budget__c = 'CON2';
        projectTask.Role_Budget_Link__c = roleBudget2.Id;
        update projectTask;

        Test.stopTest();

        // get the data we need to test against
        pse__Project_Task__c originalTask = [Select Id, Role_Budget_Link__c from pse__Project_Task__c where Name = 'Design' limit 1];
        pse__Project_Task_Assignment__c originalPTA = [Select Id, pse__Assignment__c, Role_Budget__c from pse__Project_Task_Assignment__c where Id != :pta.Id limit 1];
        pta = [Select Id, Role_Budget__c, Role_Budget__r.Reference__c, pse__Assignment__c from pse__Project_Task_Assignment__c where Id = :pta.Id];
        assignment = [Select Id, Role_Budget__c, Role_Budget__r.Reference__c from pse__Assignment__c limit 1];

        // the original project task should still have the original role budget
        system.assert( originalTask.Role_Budget_Link__c == roleBudget.Id );

        // the original PTA should still have the original assignment
        system.assert( originalPTA.pse__Assignment__c == assignment.Id, originalPTA.pse__Assignment__c );
        
        // the new PTA should have no assignment
        system.assert( pta.pse__Assignment__c == null );
        
        // the new PTA should have the new role budget
        system.assert( pta.Role_Budget__c == roleBudget2.Id, pta.Role_Budget__r?.Reference__c );

        // the assignment should have its original role budget
        system.assert( assignment.Role_Budget__c == roleBudget.Id, assignment.Role_Budget__r?.Reference__c );
    }
}