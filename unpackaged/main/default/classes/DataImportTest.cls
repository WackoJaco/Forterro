@isTest
public class DataImportTest 
{
    @TestSetup
    static void commonSetup()
    {
        // make sure the executing user can bypass some of the project validations
        List<PermissionSetGroup> groups = [Select Id from PermissionSetGroup where DeveloperName = 'Persona_System_Administrators'];
        if( groups.size() > 0 )
        {
            Id userId = UserInfo.getUserId();
            
            List<PermissionSetAssignment> assignments = 
                [Select Id from PermissionSetAssignment where PermissionSetGroupId = :groups[0].Id and AssigneeId = :userId];

            if( assignments.size() == 0 )
            {
                insert new PermissionSetAssignment(
                    PermissionSetGroupId = groups[0].Id,
                    AssigneeId = userId
                );
            }
        }
    }

    @isTest static void TestGetTaskRates()
    {
        List<Staging_Order__c> orders = new List<Staging_Order__c>{
            new Staging_Order__c( Order_Task_Identifier__c = 'aaa', Hourly_Net_Price__c = 10 ),
            new Staging_Order__c( Order_Task_Identifier__c = 'bbb', Hourly_Net_Price__c = 11 ),
            new Staging_Order__c( Order_Task_Identifier__c = 'ccc', Hourly_Net_Price__c = 12 ),
            new Staging_Order__c( Order_Task_Identifier__c = 'ddd', Hourly_Net_Price__c = 13 ),
            new Staging_Order__c( Order_Task_Identifier__c = 'eee', Hourly_Net_Price__c = 14 )
        };
        insert orders;

        List<Staging_Task__c> tasks = new List<Staging_Task__c>{
            new Staging_Task__c( Internal_Id__c = 'aaa', Import_Status__c = 'New', Task_Rate__c = null ),
            new Staging_Task__c( Internal_Id__c = 'bbb', Import_Status__c = 'New', Task_Rate__c = null ),
            new Staging_Task__c( Internal_Id__c = 'ccc', Import_Status__c = 'New', Task_Rate__c = null ),
            new Staging_Task__c( Internal_Id__c = 'ddd', Import_Status__c = 'New', Task_Rate__c = null ),
            new Staging_Task__c( Internal_Id__c = 'eee', Import_Status__c = 'New', Task_Rate__c = null )
        };
        insert tasks;

        Test.startTest();

        DataImportBatch batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.GET_TASK_RATE_ON_TASKS_FROM_ORDERS;
        Database.executeBatch( batch );

        Test.stopTest();

        for( Staging_Task__c task : [Select Id, Task_Rate__c, Internal_Id__c from Staging_Task__c] )
        {
            system.assert( task.Task_Rate__c != null, task.Internal_Id__c );
        }
    }

    @isTest static void TestFirstPassProjects()
    {
        Account acc = new Account( Name = 'John Smith', External_Id__c = 'C-133701' );
        insert acc;   

        Contact con = new Contact( FirstName = 'Izabela', LastName = 'Gredka', AccountId = acc.Id, External_Id__c = 'IGREDKA' );
        insert con;

        pse__Work_Calendar__c cal = new pse__Work_Calendar__c(
            Name = 'Test Calendar',
            pse__Week_Start_Day__c = 'Monday',
            pse__Sunday_Hours__c = 0.0,
            pse__Monday_Hours__c = 8.0,
            pse__Tuesday_Hours__c = 8.0,
            pse__Wednesday_Hours__c = 8.0,
            pse__Thursday_Hours__c =8.0,
            pse__Friday_Hours__c = 8.0,
            pse__Saturday_Hours__c = 0.0
        );
        insert cal;

        pse__Region__c region = new pse__Region__c( BU_Code__c = 'AB123', Name = 'Test Region', pse__Default_Work_Calendar__c = cal.Id );
        insert region;

        List<Staging_Project__c> stagingProjects = new List<Staging_Project__c>
        {
            new Staging_Project__c(
                Project_Name__c = 'Test project',
                Start_Date__c = system.today().addMonths( -1 ),
                Due_Date__c = system.today().addMonths( 2 ),
                Type__c = 'NSS',
                Sub_Project_Type__c = 'NSS - Implementation',
                State__c = 'Active',
                Billing_Type__c = 'Mixed',
                Customer_Name__c = 'John Smith',
                Customer_Id__c = 'C-133701',
                Project_ID__c = 'P-99702',
                Project_Number__c = '702',
                Project_Manager_Name__c = 'Izabela Gredka',
                Project_ManagerFortX_ID__c = 'FX1',
                Project_ManagerInternal_ID__c = 'IGREDKA',
                Description__c = 'This is a description',
                Region__c = 'Test Region',
                Order_Id__c = '12345',
                CurrencyisoCode = 'EUR',
                Planned_Hours__c = 10,
                Actual_Hours__c = 8 )
        };
        insert stagingProjects;

        Test.startTest();

        DataImportBatch batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.CREATE_PROJECT_FIRST_PASS;
        Database.executeBatch( batch );

        Test.stopTest();

        List<pse__Proj__c> projects = 
            [Select
                Name,
                pse__Start_Date__c,
                pse__End_Date__c,
                pse__Project_Type__c,
                Project_Sub_Types__c,
                pse__Stage__c,
                pse__Billing_Type__c,
                pse__Account__c,
                External_Project_Id__c,
                pse__Notes__c,
                pse__Project_Manager__c,
                pse__Region__c,
                Order_Id__c,
                CurrencyIsoCode,
                pse__Is_Active__c,
                pse__is_Billable__c,
                RecordTypeId,
                pse__Work_Calendar__c,
                Total_Orginal_Estimated_Hours__c,
                Actual_Hours_Migrated__c
            From
                pse__Proj__c];

        system.assert( projects.size() == 1, projects.size() );
        system.assert( projects[0].Name == 'Test project' );
        system.assert( projects[0].pse__Account__c != null );
        system.assert( projects[0].pse__Project_Manager__c != null );
        system.assert( projects[0].pse__Region__c != null );
        system.assert( projects[0].Total_Orginal_Estimated_Hours__c == 10, projects[0].Total_Orginal_Estimated_Hours__c );
        system.assert( projects[0].Actual_Hours_Migrated__c == 8, projects[0].Actual_Hours_Migrated__c );

        Staging_Project__c stage = [Select Id, Project__c, Import_Status__c from Staging_Project__c limit 1];
        system.assert( stage.Project__c != null );
        system.assert( stage.Import_Status__c == 'Base Import Complete' );
    }

    @isTest static void TestSetProjectParents()
    {
        Account acc = new Account( Name = 'John Smith', External_Id__c = 'C-133701' );
        insert acc;   

        Contact con = new Contact( FirstName = 'Izabela', LastName = 'Gredka', AccountId = acc.Id, External_Id__c = 'IGREDKA' );
        insert con;

        pse__Work_Calendar__c cal = new pse__Work_Calendar__c(
            Name = 'Test Calendar',
            pse__Week_Start_Day__c = 'Monday',
            pse__Sunday_Hours__c = 0.0,
            pse__Monday_Hours__c = 8.0,
            pse__Tuesday_Hours__c = 8.0,
            pse__Wednesday_Hours__c = 8.0,
            pse__Thursday_Hours__c =8.0,
            pse__Friday_Hours__c = 8.0,
            pse__Saturday_Hours__c = 0.0
        );
        insert cal;

        pse__Region__c region = new pse__Region__c( BU_Code__c = 'AB123', Name = 'Test Region', pse__Default_Work_Calendar__c = cal.Id );
        insert region;

        List<Staging_Project__c> stagingProjects = new List<Staging_Project__c>
        {
            new Staging_Project__c(
                Project_Name__c = 'Test project 1',
                Start_Date__c = system.today().addMonths( -1 ),
                Due_Date__c = system.today().addMonths( 2 ),
                Type__c = 'NSS',
                Sub_Project_Type__c = 'NSS - Implementation',
                State__c = 'Active',
                Billing_Type__c = 'Mixed',
                Customer_Name__c = 'John Smith',
                Customer_Id__c = 'C-133701',
                Project_ID__c = 'P-99702',
                Project_Number__c = '702',
                Project_Manager_Name__c = 'Izabela Gredka',
                Project_ManagerFortX_ID__c = 'FX1',
                Project_ManagerInternal_ID__c = 'IGREDKA',
                Description__c = 'This is a description',
                Region__c = 'Test Region',
                Order_Id__c = '12345',
                CurrencyisoCode = 'EUR',
                Parent_Project_Id__c = '',
                Parent_Project_Name__c = '' ),
            new Staging_Project__c(
                Project_Name__c = 'Test project 2',
                Start_Date__c = system.today().addMonths( -1 ),
                Due_Date__c = system.today().addMonths( 2 ),
                Type__c = 'NSS',
                Sub_Project_Type__c = 'NSS - Implementation',
                State__c = 'Active',
                Billing_Type__c = 'Mixed',
                Customer_Name__c = 'John Smith',
                Customer_Id__c = 'C-133701',
                Project_ID__c = 'P-99703',
                Project_Number__c = '703',
                Project_Manager_Name__c = 'Izabela Gredka',
                Project_ManagerFortX_ID__c = 'FX1',
                Project_ManagerInternal_ID__c = 'IGREDKA',
                Description__c = 'This is a description',
                Region__c = 'Test Region',
                Order_Id__c = '12345',
                CurrencyisoCode = 'EUR',
                Parent_Project_Id__c = 'P-99702',
                Parent_Project_Name__c = 'Test project 1' )
        };
        insert stagingProjects;

        DataImportBatch batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.CREATE_PROJECT_FIRST_PASS;
        batch.errorMessages = new List<string>();
        batch.execute( null, stagingProjects );

        Test.startTest();

        batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.SET_PROJECT_PARENTS;
        Database.executeBatch( batch );

        Test.stopTest();

        List<pse__Proj__c> projects = 
            [Select
                Id,
                Name,
                pse__Parent_Project__c
            From
                pse__Proj__c
            Order by
                Name];

        system.assert( projects[0].Name == 'Test project 1', projects[0].Name );
        system.assert( projects[1].Name == 'Test project 2', projects[1].Name );
        system.assert( projects[0].pse__Parent_Project__c == null );
        system.assert( projects[1].pse__Parent_Project__c == projects[0].Id );

        for( Staging_Project__c stage : [Select Id, Project__c, Import_Status__c from Staging_Project__c] )
        {
            system.assert( stage.Project__c != null );
            system.assert( stage.Import_Status__c == 'Parents Associated' );
        }
    }

    @isTest static void TestGettingTaskRateFromRateCards()
    {
        Account acc = new Account( Name = 'John Smith', External_Id__c = 'C-133701' );
        insert acc;   

        Contact con = new Contact( FirstName = 'Izabela', LastName = 'Gredka', AccountId = acc.Id, External_Id__c = 'IGREDKA' );
        insert con;

        pse__Work_Calendar__c cal = new pse__Work_Calendar__c(
            Name = 'Test Calendar',
            pse__Week_Start_Day__c = 'Monday',
            pse__Sunday_Hours__c = 0.0,
            pse__Monday_Hours__c = 8.0,
            pse__Tuesday_Hours__c = 8.0,
            pse__Wednesday_Hours__c = 8.0,
            pse__Thursday_Hours__c =8.0,
            pse__Friday_Hours__c = 8.0,
            pse__Saturday_Hours__c = 0.0
        );
        insert cal;

        pse__Region__c region = new pse__Region__c( BU_Code__c = 'AB123', Name = 'Test Region', pse__Default_Work_Calendar__c = cal.Id );
        insert region;

        pse__Practice__c practice = new pse__Practice__c( Name = 'Test practice' );
        insert practice;

        List<Staging_Project__c> stagingProjects = new List<Staging_Project__c>
        {
            new Staging_Project__c(
                Project_Name__c = 'Test project',
                Start_Date__c = system.today().addMonths( -1 ),
                Due_Date__c = system.today().addMonths( 2 ),
                Type__c = 'NSS',
                Sub_Project_Type__c = 'NSS - Implementation',
                State__c = 'Active',
                Billing_Type__c = 'Mixed',
                Customer_Name__c = 'John Smith',
                Customer_Id__c = 'C-133701',
                Project_ID__c = 'P-99702',
                Project_Number__c = '702',
                Project_Manager_Name__c = 'Izabela Gredka',
                Project_ManagerFortX_ID__c = 'FX1',
                Project_ManagerInternal_ID__c = 'IGREDKA',
                Description__c = 'This is a description',
                Region__c = 'Test Region',
                Order_Id__c = '12345',
                CurrencyisoCode = 'EUR' )
        };
        insert stagingProjects;

        DataImportBatch batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.CREATE_PROJECT_FIRST_PASS;
        batch.errorMessages = new List<string>();
        batch.execute( null, stagingProjects );

        List<Staging_Task__c> stagingTasks = new List<Staging_Task__c>
        {
            new Staging_Task__c( 
                Task_Name__c = 'Task 1',
                Start_Date__c = system.today().toStartOfWeek().addDays( -7 ),
                Due_Date__c = system.today().toStartOfWeek().addDays( -1 ),
                Resource_Name__c = 'Mike Bullet',
                Task_ID__c = 'T-000001',
                State__c = 'Active',
                Project_ID__c = 'P-99702',
                Remaining_Effort__c = 10,
                Internal_Id__c = '8ae6838b9105721c0191095e08064fe1',
                Parent_Id__c = 'T-000002',
                CurrencyisoCode = 'EUR',
                Training_Module__c = 'H-FRM-REFERP',
                Practice__c = 'Test practice',
                Reportable__c = true,
                Actual_Hours__c = 8,
                Budget__c = 10,
                Task_Rate__c = 0,
                Task_Role__c = 'Consultant'
            )
        };
        insert stagingTasks;

        pse__Rate_Card__c rateCard = new pse__Rate_Card__c(
            pse__Account__c = acc.Id,
            CurrencyIsoCode = 'EUR',
            pse__Role__c = 'Consultant',
            pse__Suggested_Bill_Rate__c = 1234
        );
        insert rateCard;

        Test.startTest();

        batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.GET_TASK_RATE_FROM_RATE_CARDS;
        Database.executeBatch( batch );

        Test.stopTest();

        Staging_Task__c stage = [Select id, Task_Rate__c, Import_Status__c from Staging_Task__c limit 1];
        system.assert( stage.Task_Rate__c == 1234 );
        system.assert( stage.Import_Status__c == 'New' );
    }

    @isTest static void TestFirstPassTasks()
    {
        Account acc = new Account( Name = 'John Smith', External_Id__c = 'C-133701' );
        insert acc;   

        Contact con = new Contact( FirstName = 'Izabela', LastName = 'Gredka', AccountId = acc.Id, External_Id__c = 'IGREDKA' );
        insert con;

        pse__Work_Calendar__c cal = new pse__Work_Calendar__c(
            Name = 'Test Calendar',
            pse__Week_Start_Day__c = 'Monday',
            pse__Sunday_Hours__c = 0.0,
            pse__Monday_Hours__c = 8.0,
            pse__Tuesday_Hours__c = 8.0,
            pse__Wednesday_Hours__c = 8.0,
            pse__Thursday_Hours__c =8.0,
            pse__Friday_Hours__c = 8.0,
            pse__Saturday_Hours__c = 0.0
        );
        insert cal;

        pse__Region__c region = new pse__Region__c( BU_Code__c = 'AB123', Name = 'Test Region', pse__Default_Work_Calendar__c = cal.Id );
        insert region;

        pse__Practice__c practice = new pse__Practice__c( Name = 'Test practice' );
        insert practice;

        List<Staging_Project__c> stagingProjects = new List<Staging_Project__c>
        {
            new Staging_Project__c(
                Project_Name__c = 'Test project',
                Start_Date__c = system.today().addMonths( -1 ),
                Due_Date__c = system.today().addMonths( 2 ),
                Type__c = 'NSS',
                Sub_Project_Type__c = 'NSS - Implementation',
                State__c = 'Active',
                Billing_Type__c = 'Mixed',
                Customer_Name__c = 'John Smith',
                Customer_Id__c = 'C-133701',
                Project_ID__c = 'P-99702',
                Project_Number__c = '702',
                Project_Manager_Name__c = 'Izabela Gredka',
                Project_ManagerFortX_ID__c = 'FX1',
                Project_ManagerInternal_ID__c = 'IGREDKA',
                Description__c = 'This is a description',
                Region__c = 'Test Region',
                Order_Id__c = '12345',
                CurrencyisoCode = 'EUR' )
        };
        insert stagingProjects;

        DataImportBatch batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.CREATE_PROJECT_FIRST_PASS;
        batch.errorMessages = new List<string>();
        batch.execute( null, stagingProjects );

        List<Staging_Task__c> stagingTasks = new List<Staging_Task__c>
        {
            new Staging_Task__c( 
                Task_Name__c = 'Task 1',
                Start_Date__c = system.today().toStartOfWeek().addDays( -7 ),
                Due_Date__c = system.today().toStartOfWeek().addDays( -1 ),
                Resource_Name__c = 'Mike Bullet',
                Task_ID__c = 'T-000001',
                State__c = 'Active',
                Project_ID__c = 'P-99702',
                Remaining_Effort__c = 10,
                Internal_Id__c = '8ae6838b9105721c0191095e08064fe1',
                Parent_Id__c = 'T-000002',
                CurrencyisoCode = 'EUR',
                Training_Module__c = 'H-FRM-REFERP',
                Practice__c = 'Test practice',
                Reportable__c = true,
                Actual_Hours__c = 8,
                Budget__c = 10
            )
        };
        insert stagingTasks;

        Test.startTest();

        batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.CREATE_PROJECT_TASKS;
        Database.executeBatch( batch );

        Test.stopTest();

        List<pse__Project_Task__c> tasks = [Select Id, Name, Practice__c, Original_Estimated_Hours__c, Actual_Hours_Migrated__c from pse__Project_Task__c];
        system.assert( tasks.size() == 1 );
        system.assert( tasks[0].Practice__c == practice.Id );
        system.assert( tasks[0].Original_Estimated_Hours__c == 10, tasks[0].Original_Estimated_Hours__c );
        system.assert( tasks[0].Actual_Hours_Migrated__c == 8, tasks[0].Actual_Hours_Migrated__c );

        Staging_Task__c stage = [Select id, Project_Task__c, Import_Status__c from Staging_Task__c limit 1];
        system.assert( stage.Project_Task__c != null );
        system.assert( stage.Import_Status__c == 'Base Import Complete' );
    }

    @isTest static void TestSetTaskParents()
    {
        Account acc = new Account( Name = 'John Smith', External_Id__c = 'C-133701' );
        insert acc;   

        Contact con = new Contact( FirstName = 'Izabela', LastName = 'Gredka', AccountId = acc.Id, External_Id__c = 'IGREDKA' );
        insert con;

        pse__Work_Calendar__c cal = new pse__Work_Calendar__c(
            Name = 'Test Calendar',
            pse__Week_Start_Day__c = 'Monday',
            pse__Sunday_Hours__c = 0.0,
            pse__Monday_Hours__c = 8.0,
            pse__Tuesday_Hours__c = 8.0,
            pse__Wednesday_Hours__c = 8.0,
            pse__Thursday_Hours__c =8.0,
            pse__Friday_Hours__c = 8.0,
            pse__Saturday_Hours__c = 0.0
        );
        insert cal;

        pse__Region__c region = new pse__Region__c( BU_Code__c = 'AB123', Name = 'Test Region', pse__Default_Work_Calendar__c = cal.Id );
        insert region;

        List<Staging_Project__c> stagingProjects = new List<Staging_Project__c>
        {
            new Staging_Project__c(
                Project_Name__c = 'Test project',
                Start_Date__c = system.today().addMonths( -1 ),
                Due_Date__c = system.today().addMonths( 2 ),
                Type__c = 'NSS',
                Sub_Project_Type__c = 'NSS - Implementation',
                State__c = 'Active',
                Billing_Type__c = 'Mixed',
                Customer_Name__c = 'John Smith',
                Customer_Id__c = 'C-133701',
                Project_ID__c = 'P-99702',
                Project_Number__c = '702',
                Project_Manager_Name__c = 'Izabela Gredka',
                Project_ManagerFortX_ID__c = 'FX1',
                Project_ManagerInternal_ID__c = 'IGREDKA',
                Description__c = 'This is a description',
                Region__c = 'Test Region',
                Order_Id__c = '12345',
                CurrencyisoCode = 'EUR' )
        };
        insert stagingProjects;

        DataImportBatch batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.CREATE_PROJECT_FIRST_PASS;
        batch.errorMessages = new List<string>();
        batch.execute( null, stagingProjects );

        List<Staging_Task__c> stagingTasks = new List<Staging_Task__c>
        {
            new Staging_Task__c( 
                Task_Name__c = 'Task 1',
                Start_Date__c = system.today().toStartOfWeek().addDays( -7 ),
                Due_Date__c = system.today().toStartOfWeek().addDays( -1 ),
                Budget__c = 123,
                Resource_Name__c = 'Mike Bullet',
                Task_ID__c = 'T-000001',
                State__c = 'Active',
                Project_ID__c = 'P-99702',
                Remaining_Effort__c = 10,
                Internal_Id__c = '8ae6838b9105721c0191095e08064fe1',
                Parent_Id__c = 'T-000002',
                CurrencyisoCode = 'EUR',
                Training_Module__c = 'H-FRM-REFERP',
                Reportable__c = true
            ),
            new Staging_Task__c( 
                Task_Name__c = 'Task 2',
                Start_Date__c = system.today().toStartOfWeek().addDays( -7 ),
                Due_Date__c = system.today().toStartOfWeek().addDays( -1 ),
                Budget__c = 321,
                Resource_Name__c = 'Mike Bullet',
                Task_ID__c = 'T-000002',
                State__c = 'Active',
                Project_ID__c = 'P-99702',
                Remaining_Effort__c = 10,
                Internal_Id__c = '8ae6838b9105721c0191095e08064fe2',
                Parent_Id__c = '',
                CurrencyisoCode = 'EUR',
                Training_Module__c = 'H-FRM-REFERP',
                Reportable__c = false
            )
        };
        insert stagingTasks;

        batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.CREATE_PROJECT_TASKS;
        batch.errorMessages = new List<string>();
        batch.execute( null, stagingTasks );

        Test.startTest();

        batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.SET_PROJECT_TASK_PARENTS;
        Database.executeBatch( batch );

        Test.stopTest();

        List<pse__Project_Task__c> tasks = [Select Id, Name, pse__Parent_Task__c from pse__Project_Task__c order by Name];
        system.assert( tasks.size() == 2 );
        system.assert( tasks[0].Name == 'Task 1', tasks[0].Name );
        system.assert( tasks[1].Name == 'Task 2', tasks[1].Name );
        system.assert( tasks[0].pse__Parent_Task__c == tasks[1].Id );
        system.assert( tasks[1].pse__Parent_Task__c == null );

        for( Staging_Task__c stage : [Select id, Project_Task__c, Import_Status__c from Staging_Task__c] )
        {
            system.assert( stage.Project_Task__c != null );
            system.assert( stage.Import_Status__c == 'Parents Associated' );
        }
    }

    @isTest static void TestCreateRoleBudgets()
    {
        Account acc = new Account( Name = 'John Smith', External_Id__c = 'C-133701' );
        insert acc;   

        Contact con = new Contact( FirstName = 'Izabela', LastName = 'Gredka', AccountId = acc.Id, External_Id__c = 'IGREDKA' );
        insert con;

        pse__Work_Calendar__c cal = new pse__Work_Calendar__c(
            Name = 'Test Calendar',
            pse__Week_Start_Day__c = 'Monday',
            pse__Sunday_Hours__c = 0.0,
            pse__Monday_Hours__c = 8.0,
            pse__Tuesday_Hours__c = 8.0,
            pse__Wednesday_Hours__c = 8.0,
            pse__Thursday_Hours__c =8.0,
            pse__Friday_Hours__c = 8.0,
            pse__Saturday_Hours__c = 0.0
        );
        insert cal;

        pse__Region__c region = new pse__Region__c( BU_Code__c = 'AB123', Name = 'Test Region', pse__Default_Work_Calendar__c = cal.Id );
        insert region;

        Contact con2 = new Contact( 
            FirstName = 'Mike', 
            LastName = 'Bullet', 
            AccountId = acc.Id, 
            External_Id__c = 'MIKEBULLET',
            pse__Is_Resource__c = true,
            pse__Is_Resource_Active__c = true,
            pse__Resource_Role__c = 'Consultant',
            pse__Region__c = region.Id );
        insert con2;

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

        List<Staging_Project__c> stagingProjects = new List<Staging_Project__c>
        {
            new Staging_Project__c(
                Project_Name__c = 'Test project',
                Start_Date__c = system.today().addMonths( -1 ),
                Due_Date__c = system.today().addMonths( 2 ),
                Type__c = 'NSS',
                Sub_Project_Type__c = 'NSS - Implementation',
                State__c = 'Active',
                Billing_Type__c = 'Mixed',
                Customer_Name__c = 'John Smith',
                Customer_Id__c = 'C-133701',
                Project_ID__c = 'P-99702',
                Project_Number__c = '702',
                Project_Manager_Name__c = 'Izabela Gredka',
                Project_ManagerFortX_ID__c = 'FX1',
                Project_ManagerInternal_ID__c = 'IGREDKA',
                Description__c = 'This is a description',
                Region__c = 'Test Region',
                Order_Id__c = '12345',
                CurrencyisoCode = 'EUR' )
        };
        insert stagingProjects;

        DataImportBatch batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.CREATE_PROJECT_FIRST_PASS;
        batch.errorMessages = new List<string>();
        batch.execute( null, stagingProjects );

        List<Staging_Task__c> stagingTasks = new List<Staging_Task__c>
        {
            new Staging_Task__c( 
                Task_Name__c = 'Task 1',
                Start_Date__c = system.today().toStartOfWeek().addDays( -7 ),
                Due_Date__c = system.today().toStartOfWeek().addDays( -1 ),
                Budget__c = 123,
                Resource_Name__c = 'Mike Bullet',
                Task_ID__c = 'T-000001',
                Task_Type__c = 'Billable',
                Task_Rate__c = 11,
                State__c = 'Active',
                Project_ID__c = 'P-99702',
                Remaining_Effort__c = 15,
                Internal_Id__c = '8ae6838b9105721c0191095e08064fe1',
                Parent_Id__c = 'T-000002',
                CurrencyisoCode = 'EUR',
                Training_Module__c = 'H-FRM-REFERP',
                Reportable__c = true
            ),
            new Staging_Task__c( 
                Task_Name__c = 'Task 2',
                Start_Date__c = system.today().toStartOfWeek().addDays( -7 ),
                Due_Date__c = system.today().toStartOfWeek().addDays( -1 ),
                Budget__c = 18,
                Resource_Name__c = 'Mike Bullet',
                Task_ID__c = 'T-000002',
                Task_Type__c = 'Billable',
                Task_Rate__c = 11,
                State__c = 'Active',
                Project_ID__c = 'P-99702',
                Remaining_Effort__c = 16,
                Internal_Id__c = '8ae6838b9105721c0191095e08064fe2',
                Parent_Id__c = '',
                CurrencyisoCode = 'EUR',
                Training_Module__c = 'H-FRM-REFERP',
                Reportable__c = true
            )
        };
        insert stagingTasks;

        batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.CREATE_PROJECT_TASKS;
        batch.errorMessages = new List<string>();
        batch.execute( null, stagingTasks );

        batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.SET_PROJECT_TASK_PARENTS;
        batch.errorMessages = new List<string>();
        batch.execute( null, stagingTasks );

        Test.startTest();

        batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.CREATE_ROLE_BUDGETS;
        Database.executeBatch( batch );

        Test.stopTest();

        for( Staging_Task__c stage : [Select id, Project_Task__c, Import_Status__c from Staging_Task__c where Reportable__c = true] )
        {
            system.assert( stage.Project_Task__c != null );
            system.assert( stage.Import_Status__c == 'Role Budgets Created' );
        }

        List<Role_Budget__c> roleBudgets = [Select Id, Hours_Budget__c from Role_Budget__c];
        system.assert( roleBudgets.size() == 1, roleBudgets.size() );
        system.assert( roleBudgets[0].Hours_Budget__c == 31, roleBudgets[0].Hours_Budget__c );
    }

    @isTest static void TestCreateAssignments()
    {
        Account acc = new Account( Name = 'John Smith', External_Id__c = 'C-133701' );
        insert acc;   

        Contact con = new Contact( FirstName = 'Izabela', LastName = 'Gredka', AccountId = acc.Id, External_Id__c = 'IGREDKA' );
        insert con;

        pse__Work_Calendar__c cal = new pse__Work_Calendar__c(
            Name = 'Test Calendar',
            pse__Week_Start_Day__c = 'Monday',
            pse__Sunday_Hours__c = 0.0,
            pse__Monday_Hours__c = 8.0,
            pse__Tuesday_Hours__c = 8.0,
            pse__Wednesday_Hours__c = 8.0,
            pse__Thursday_Hours__c =8.0,
            pse__Friday_Hours__c = 8.0,
            pse__Saturday_Hours__c = 0.0
        );
        insert cal;

        pse__Region__c region = new pse__Region__c( BU_Code__c = 'AB123', Name = 'Test Region', pse__Default_Work_Calendar__c = cal.Id );
        insert region;

        Contact con2 = new Contact( 
            FirstName = 'Mike', 
            LastName = 'Bullet', 
            AccountId = acc.Id, 
            External_Id__c = 'MIKEBULLET',
            pse__Is_Resource__c = true,
            pse__Is_Resource_Active__c = true,
            pse__Resource_Role__c = 'Consultant',
            pse__Region__c = region.Id );
        insert con2;

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

        List<Staging_Project__c> stagingProjects = new List<Staging_Project__c>
        {
            new Staging_Project__c(
                Project_Name__c = 'Test project',
                Start_Date__c = system.today().addMonths( -1 ),
                Due_Date__c = system.today().addMonths( 2 ),
                Type__c = 'NSS',
                Sub_Project_Type__c = 'NSS - Implementation',
                State__c = 'Active',
                Billing_Type__c = 'Mixed',
                Customer_Name__c = 'John Smith',
                Customer_Id__c = 'C-133701',
                Project_ID__c = 'P-99702',
                Project_Number__c = '702',
                Project_Manager_Name__c = 'Izabela Gredka',
                Project_ManagerFortX_ID__c = 'FX1',
                Project_ManagerInternal_ID__c = 'IGREDKA',
                Description__c = 'This is a description',
                Region__c = 'Test Region',
                Order_Id__c = '12345',
                CurrencyisoCode = 'EUR' )
        };
        insert stagingProjects;

        DataImportBatch batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.CREATE_PROJECT_FIRST_PASS;
        batch.errorMessages = new List<string>();
        batch.execute( null, stagingProjects );

        List<Staging_Task__c> stagingTasks = new List<Staging_Task__c>
        {
            new Staging_Task__c( 
                Task_Name__c = 'Task 1',
                Start_Date__c = system.today().toStartOfWeek().addDays( -7 ),
                Due_Date__c = system.today().toStartOfWeek().addDays( -1 ),
                Budget__c = 123,
                Resource_Name__c = 'Mike Bullet',
                Task_ID__c = 'T-000001',
                Task_Type__c = 'Billable',
                Task_Rate__c = 12,
                State__c = 'Active',
                Project_ID__c = 'P-99702',
                Remaining_Effort__c = 10,
                Internal_Id__c = '8ae6838b9105721c0191095e08064fe1',
                Parent_Id__c = 'T-000002',
                CurrencyisoCode = 'EUR',
                Training_Module__c = 'H-FRM-REFERP',
                Reportable__c = true
            ),
            new Staging_Task__c( 
                Task_Name__c = 'Task 2',
                Start_Date__c = system.today().toStartOfWeek().addDays( -7 ),
                Due_Date__c = system.today().toStartOfWeek().addDays( -1 ),
                Budget__c = 18,
                Resource_Name__c = 'Mike Bullet',
                Task_ID__c = 'T-000002',
                Task_Type__c = 'Billable',
                Task_Rate__c = 11,
                State__c = 'Active',
                Project_ID__c = 'P-99702',
                Remaining_Effort__c = 10,
                Internal_Id__c = '8ae6838b9105721c0191095e08064fe2',
                Parent_Id__c = '',
                CurrencyisoCode = 'EUR',
                Training_Module__c = 'H-FRM-REFERP',
                Reportable__c = false
            )
        };
        insert stagingTasks;

        batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.CREATE_PROJECT_TASKS;
        batch.errorMessages = new List<string>();
        batch.execute( null, stagingTasks );

        batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.SET_PROJECT_TASK_PARENTS;
        batch.errorMessages = new List<string>();
        batch.execute( null, stagingTasks );

        batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.CREATE_ROLE_BUDGETS;
        batch.errorMessages = new List<string>();
        
        // re-query so we get fresh data
        Set<string> statuses = new Set<string>{ 'Parents Associated' };
        stagingTasks = (List<Staging_Task__c>)Database.query( batch.start( null ).getQuery() );
        batch.execute( null, stagingTasks );

        Test.startTest();

        batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.CREATE_ASSIGNMENTS;
        Database.executeBatch( batch );

        Test.stopTest();

        for( Staging_Task__c stage : [Select id, Project_Task__c, Import_Status__c from Staging_Task__c where Reportable__c = true] )
        {
            system.assert( stage.Project_Task__c != null );
            system.assert( stage.Import_Status__c == 'Assignments Created' );
        }

        List<pse__Assignment__c> assignments = [Select Id, Role_Budget__c from pse__Assignment__c];
        system.assert( assignments.size() > 0 );
        system.assert( assignments[0].Role_Budget__c != null );

        List<pse__Schedule__c> schedules = [Select Id from pse__Schedule__c];
        system.assert( schedules.size() > 0 );
    }

    @isTest static void TestCreatePTAs()
    {
        Account acc = new Account( Name = 'John Smith', External_Id__c = 'C-133701' );
        insert acc;   

        Contact con = new Contact( FirstName = 'Izabela', LastName = 'Gredka', AccountId = acc.Id, External_Id__c = 'IGREDKA' );
        insert con;

        pse__Work_Calendar__c cal = new pse__Work_Calendar__c(
            Name = 'Test Calendar',
            pse__Week_Start_Day__c = 'Monday',
            pse__Sunday_Hours__c = 0.0,
            pse__Monday_Hours__c = 8.0,
            pse__Tuesday_Hours__c = 8.0,
            pse__Wednesday_Hours__c = 8.0,
            pse__Thursday_Hours__c =8.0,
            pse__Friday_Hours__c = 8.0,
            pse__Saturday_Hours__c = 0.0
        );
        insert cal;

        pse__Region__c region = new pse__Region__c( BU_Code__c = 'AB123', Name = 'Test Region', pse__Default_Work_Calendar__c = cal.Id );
        insert region;

        Contact con2 = new Contact( 
            FirstName = 'Mike', 
            LastName = 'Bullet', 
            AccountId = acc.Id, 
            External_Id__c = 'MIKEBULLET',
            pse__Is_Resource__c = true,
            pse__Is_Resource_Active__c = true,
            pse__Resource_Role__c = 'Consultant',
            pse__Region__c = region.Id );
        insert con2;

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

        List<Staging_Project__c> stagingProjects = new List<Staging_Project__c>
        {
            new Staging_Project__c(
                Project_Name__c = 'Test project',
                Start_Date__c = system.today().addMonths( -1 ),
                Due_Date__c = system.today().addMonths( 2 ),
                Type__c = 'NSS',
                Sub_Project_Type__c = 'NSS - Implementation',
                State__c = 'Active',
                Billing_Type__c = 'Mixed',
                Customer_Name__c = 'John Smith',
                Customer_Id__c = 'C-133701',
                Project_ID__c = 'P-99702',
                Project_Number__c = '702',
                Project_Manager_Name__c = 'Izabela Gredka',
                Project_ManagerFortX_ID__c = 'FX1',
                Project_ManagerInternal_ID__c = 'IGREDKA',
                Description__c = 'This is a description',
                Region__c = 'Test Region',
                Order_Id__c = '12345',
                CurrencyisoCode = 'EUR' )
        };
        insert stagingProjects;

        DataImportBatch batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.CREATE_PROJECT_FIRST_PASS;
        batch.errorMessages = new List<string>();
        batch.execute( null, stagingProjects );

        List<Staging_Task__c> stagingTasks = new List<Staging_Task__c>
        {
            new Staging_Task__c( 
                Task_Name__c = 'Task 1',
                Start_Date__c = system.today().toStartOfWeek().addDays( -7 ),
                Due_Date__c = system.today().toStartOfWeek().addDays( -1 ),
                Budget__c = 12,
                Resource_Name__c = 'Mike Bullet',
                Task_ID__c = 'T-000001',
                Task_Type__c = 'Billable',
                Task_Rate__c = 10,
                State__c = 'Active',
                Project_ID__c = 'P-99702',
                Remaining_Effort__c = 10,
                Internal_Id__c = '8ae6838b9105721c0191095e08064fe1',
                Parent_Id__c = 'T-000002',
                CurrencyisoCode = 'EUR',
                Training_Module__c = 'H-FRM-REFERP',
                Reportable__c = true
            ),
            new Staging_Task__c( 
                Task_Name__c = 'Task 2',
                Start_Date__c = system.today().toStartOfWeek().addDays( -7 ),
                Due_Date__c = system.today().toStartOfWeek().addDays( -1 ),
                Budget__c = 18,
                Resource_Name__c = 'Mike Bullet',
                Task_ID__c = 'T-000002',
                Task_Type__c = 'Billable',
                Task_Rate__c = 11,
                State__c = 'Active',
                Project_ID__c = 'P-99702',
                Remaining_Effort__c = 10,
                Internal_Id__c = '8ae6838b9105721c0191095e08064fe2',
                Parent_Id__c = '',
                CurrencyisoCode = 'EUR',
                Training_Module__c = 'H-FRM-REFERP',
                Reportable__c = false
            )
        };
        insert stagingTasks;

        batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.CREATE_PROJECT_TASKS;
        batch.errorMessages = new List<string>();
        batch.execute( null, stagingTasks );

        batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.SET_PROJECT_TASK_PARENTS;
        batch.errorMessages = new List<string>();
        batch.execute( null, stagingTasks );

        batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.CREATE_ROLE_BUDGETS;
        batch.errorMessages = new List<string>();
        
        // re-query so we get fresh data
        Set<string> statuses = new Set<string>{ 'Parents Associated' };
        stagingTasks = (List<Staging_Task__c>)Database.query( batch.start( null ).getQuery() );
        batch.execute( null, stagingTasks );

        batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.CREATE_ASSIGNMENTS;
        batch.errorMessages = new List<string>();

        // re-query so we get fresh data
        statuses = new Set<string>{ 'Role Budgets Created' };
        stagingTasks = (List<Staging_Task__c>)Database.query( batch.start( null ).getQuery() );
        batch.execute( null, stagingTasks );

        Test.startTest();

        batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.CREATE_PROJECT_TASK_ASSIGNMENTS;
        Database.executeBatch( batch );

        Test.stopTest();

        for( Staging_Task__c stage : [Select id, Project_Task__c, Project_Task__r.Role_Budget_Link__c, Import_Status__c, Project_Task_Assignment__c from Staging_Task__c where Reportable__c = true] )
        {
            system.assert( stage.Project_Task__c != null );
            system.assert( stage.Import_Status__c == 'Complete' );
            system.assert( stage.Project_Task_Assignment__c != null );
            system.assert( stage.Project_Task__r.Role_Budget_Link__c != null );
        }

        List<pse__Assignment__c> assignments = [Select Id, Role_Budget__c from pse__Assignment__c];
        system.assert( assignments.size() > 0 );
        system.assert( assignments[0].Role_Budget__c != null );

        List<pse__Schedule__c> schedules = [Select Id from pse__Schedule__c];
        system.assert( schedules.size() > 0 );

        List<pse__Project_Task_Assignment__c> ptas = [Select Id, Role_Budget__c from pse__Project_Task_Assignment__c];
        system.assert( ptas.size() > 0 );
        system.assert( ptas[0].Role_Budget__c != null );
    }

    @isTest static void TestUpdateProjectPlannedHours()
    {
        Account acc = new Account( Name = 'John Smith', External_Id__c = 'C-133701' );
        insert acc;   

        Contact con = new Contact( FirstName = 'Izabela', LastName = 'Gredka', AccountId = acc.Id, External_Id__c = 'IGREDKA' );
        insert con;

        pse__Work_Calendar__c cal = new pse__Work_Calendar__c(
            Name = 'Test Calendar',
            pse__Week_Start_Day__c = 'Monday',
            pse__Sunday_Hours__c = 0.0,
            pse__Monday_Hours__c = 8.0,
            pse__Tuesday_Hours__c = 8.0,
            pse__Wednesday_Hours__c = 8.0,
            pse__Thursday_Hours__c =8.0,
            pse__Friday_Hours__c = 8.0,
            pse__Saturday_Hours__c = 0.0
        );
        insert cal;

        pse__Region__c region = new pse__Region__c( BU_Code__c = 'AB123', Name = 'Test Region', pse__Default_Work_Calendar__c = cal.Id );
        insert region;

        Contact con2 = new Contact( 
            FirstName = 'Mike', 
            LastName = 'Bullet', 
            AccountId = acc.Id, 
            External_Id__c = 'MIKEBULLET',
            pse__Is_Resource__c = true,
            pse__Is_Resource_Active__c = true,
            pse__Resource_Role__c = 'Consultant',
            pse__Region__c = region.Id );
        insert con2;

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

        List<Staging_Project__c> stagingProjects = new List<Staging_Project__c>
        {
            new Staging_Project__c(
                Project_Name__c = 'Test project',
                Start_Date__c = system.today().addMonths( -1 ),
                Due_Date__c = system.today().addMonths( 2 ),
                Type__c = 'NSS',
                Sub_Project_Type__c = 'NSS - Implementation',
                State__c = 'Active',
                Billing_Type__c = 'Mixed',
                Customer_Name__c = 'John Smith',
                Customer_Id__c = 'C-133701',
                Project_ID__c = 'P-99702',
                Project_Number__c = '702',
                Project_Manager_Name__c = 'Izabela Gredka',
                Project_ManagerFortX_ID__c = 'FX1',
                Project_ManagerInternal_ID__c = 'IGREDKA',
                Description__c = 'This is a description',
                Region__c = 'Test Region',
                Order_Id__c = '12345',
                CurrencyisoCode = 'EUR' )
        };
        insert stagingProjects;

        DataImportBatch batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.CREATE_PROJECT_FIRST_PASS;
        batch.errorMessages = new List<string>();
        batch.execute( null, stagingProjects );

        batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.SET_PROJECT_PARENTS;
        batch.errorMessages = new List<string>();
        batch.execute( null, stagingProjects );

        List<Staging_Task__c> stagingTasks = new List<Staging_Task__c>
        {
            new Staging_Task__c( 
                Task_Name__c = 'Task 1',
                Start_Date__c = system.today().toStartOfWeek().addDays( -7 ),
                Due_Date__c = system.today().toStartOfWeek().addDays( -1 ),
                Budget__c = 12,
                Resource_Name__c = 'Mike Bullet',
                Task_ID__c = 'T-000001',
                Task_Type__c = 'Billable',
                Task_Rate__c = 10,
                State__c = 'Active',
                Project_ID__c = 'P-99702',
                Remaining_Effort__c = 10,
                Internal_Id__c = '8ae6838b9105721c0191095e08064fe1',
                Parent_Id__c = '',
                CurrencyisoCode = 'EUR',
                Training_Module__c = 'H-FRM-REFERP',
                Reportable__c = true
            ),
            new Staging_Task__c( 
                Task_Name__c = 'Task 2',
                Start_Date__c = system.today().toStartOfWeek().addDays( -7 ),
                Due_Date__c = system.today().toStartOfWeek().addDays( -1 ),
                Budget__c = 18,
                Resource_Name__c = 'Mike Bullet',
                Task_ID__c = 'T-000002',
                Task_Type__c = 'Billable',
                Task_Rate__c = 11,
                State__c = 'Active',
                Project_ID__c = 'P-99702',
                Remaining_Effort__c = 11,
                Internal_Id__c = '8ae6838b9105721c0191095e08064fe2',
                Parent_Id__c = '',
                CurrencyisoCode = 'EUR',
                Training_Module__c = 'H-FRM-REFERP',
                Reportable__c = true
            )
        };
        insert stagingTasks;

        batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.CREATE_PROJECT_TASKS;
        batch.errorMessages = new List<string>();
        batch.execute( null, stagingTasks );

        batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.SET_PROJECT_TASK_PARENTS;
        batch.errorMessages = new List<string>();
        batch.execute( null, stagingTasks );

        batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.CREATE_ROLE_BUDGETS;
        batch.errorMessages = new List<string>();

        // re-query so we get fresh data
        Set<string> statuses = new Set<string>{ 'Parents Associated' };
        stagingTasks = (List<Staging_Task__c>)Database.query( batch.start( null ).getQuery() );
        batch.execute( null, stagingTasks );

        Test.startTest();

        batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.UPDATE_PROJECT_PLANNED_HOURS;
        Database.executeBatch( batch );

        Test.stopTest();

        Staging_Project__c proj = [Select Id, Import_Status__c from Staging_Project__c limit 1];
        system.assert( proj.Import_Status__c == 'Parents Associated', proj.Import_Status__c );

        pse__Proj__c project = [Select Id, pse__Planned_Hours__c, (Select Id, pse__Estimated_Hours__c from pse__Project_Tasks__r where pse__Estimated_Hours__c > 0) from pse__Proj__c];
        system.assert( project.pse__Project_Tasks__r.size() == 2, project.pse__Project_Tasks__r.size() );
        system.assert( project.pse__Planned_Hours__c == 21, project.pse__Planned_Hours__c );
    }

    @isTest static void TestCreateProjectBudgets()
    {
        Account acc = new Account( Name = 'John Smith', External_Id__c = 'C-133701' );
        insert acc;   

        Contact con = new Contact( FirstName = 'Izabela', LastName = 'Gredka', AccountId = acc.Id, External_Id__c = 'IGREDKA' );
        insert con;

        pse__Work_Calendar__c cal = new pse__Work_Calendar__c(
            Name = 'Test Calendar',
            pse__Week_Start_Day__c = 'Monday',
            pse__Sunday_Hours__c = 0.0,
            pse__Monday_Hours__c = 8.0,
            pse__Tuesday_Hours__c = 8.0,
            pse__Wednesday_Hours__c = 8.0,
            pse__Thursday_Hours__c =8.0,
            pse__Friday_Hours__c = 8.0,
            pse__Saturday_Hours__c = 0.0
        );
        insert cal;

        pse__Region__c region = new pse__Region__c( BU_Code__c = 'AB123', Name = 'Test Region', pse__Default_Work_Calendar__c = cal.Id );
        insert region;

        Contact con2 = new Contact( 
            FirstName = 'Mike', 
            LastName = 'Bullet', 
            AccountId = acc.Id, 
            External_Id__c = 'MIKEBULLET',
            pse__Is_Resource__c = true,
            pse__Is_Resource_Active__c = true,
            pse__Resource_Role__c = 'Consultant',
            pse__Region__c = region.Id );
        insert con2;

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

        List<Staging_Project__c> stagingProjects = new List<Staging_Project__c>
        {
            new Staging_Project__c(
                Project_Name__c = 'Test project',
                Start_Date__c = system.today().addMonths( -1 ),
                Due_Date__c = system.today().addMonths( 2 ),
                Type__c = 'NSS',
                Sub_Project_Type__c = 'NSS - Implementation',
                State__c = 'Active',
                Billing_Type__c = 'Mixed',
                Customer_Name__c = 'John Smith',
                Customer_Id__c = 'C-133701',
                Project_ID__c = 'P-99702',
                Project_Number__c = '702',
                Project_Manager_Name__c = 'Izabela Gredka',
                Project_ManagerFortX_ID__c = 'FX1',
                Project_ManagerInternal_ID__c = 'IGREDKA',
                Description__c = 'This is a description',
                Region__c = 'Test Region',
                Order_Id__c = '12345',
                CurrencyisoCode = 'EUR' )
        };
        insert stagingProjects;

        DataImportBatch batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.CREATE_PROJECT_FIRST_PASS;
        batch.errorMessages = new List<string>();
        batch.execute( null, stagingProjects );

        batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.SET_PROJECT_PARENTS;
        batch.errorMessages = new List<string>();
        batch.execute( null, stagingProjects );

        List<Staging_Task__c> stagingTasks = new List<Staging_Task__c>
        {
            new Staging_Task__c( 
                Task_Name__c = 'Task 1',
                Start_Date__c = system.today().toStartOfWeek().addDays( -7 ),
                Due_Date__c = system.today().toStartOfWeek().addDays( -1 ),
                Budget__c = 12,
                Resource_Name__c = 'Mike Bullet',
                Task_ID__c = 'T-000001',
                Task_Type__c = 'Billable',
                Task_Rate__c = 10,
                State__c = 'Active',
                Project_ID__c = 'P-99702',
                Remaining_Effort__c = 10,
                Internal_Id__c = '8ae6838b9105721c0191095e08064fe1',
                Parent_Id__c = '',
                CurrencyisoCode = 'EUR',
                Training_Module__c = 'H-FRM-REFERP',
                Reportable__c = true
            ),
            new Staging_Task__c( 
                Task_Name__c = 'Task 2',
                Start_Date__c = system.today().toStartOfWeek().addDays( -7 ),
                Due_Date__c = system.today().toStartOfWeek().addDays( -1 ),
                Budget__c = 18,
                Resource_Name__c = 'Mike Bullet',
                Task_ID__c = 'T-000002',
                Task_Type__c = 'Billable',
                Task_Rate__c = 11,
                State__c = 'Active',
                Project_ID__c = 'P-99702',
                Remaining_Effort__c = 11,
                Internal_Id__c = '8ae6838b9105721c0191095e08064fe2',
                Parent_Id__c = '',
                CurrencyisoCode = 'EUR',
                Training_Module__c = 'H-FRM-REFERP',
                Reportable__c = true
            )
        };
        insert stagingTasks;

        batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.CREATE_PROJECT_TASKS;
        batch.errorMessages = new List<string>();
        batch.execute( null, stagingTasks );

        batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.SET_PROJECT_TASK_PARENTS;
        batch.errorMessages = new List<string>();
        batch.execute( null, stagingTasks );

        Test.startTest();

        batch = new DataImportBatch();
        batch.currentProcess = DataImportBatch.Process.CREATE_PROJECT_BUDGETS;
        Database.executeBatch( batch );

        Test.stopTest();

        Staging_Project__c proj = [Select Id, Import_Status__c from Staging_Project__c limit 1];
        system.assert( proj.Import_Status__c == 'Complete', proj.Import_Status__c );

        List<pse__Budget__c> budgets = [Select Id from pse__Budget__c];
        system.assert( budgets.size() > 0 );
    }
}