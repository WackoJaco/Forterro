@isTest
public class GetExtProjectForRegionTest 
{
    @TestSetup
    static void makeData()
    {
        pse__Region__c region1 = new pse__Region__c(
            Name = 'Region1'
        );
        insert region1;

        pse__Region__c region2 = new pse__Region__c(
            Name = 'Region2',
            pse__Parent_Region__c = region1.Id
        );
        insert region2;

        pse__Region__c region3 = new pse__Region__c(
            Name = 'Region3',
            pse__Parent_Region__c = region2.Id
        );
        insert region3;

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

        Contact res = new Contact(
            AccountId = acc.Id,
            FirstName = 'Test',
            LastName = 'Resource',
            pse__Region__c = region2.Id,
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
            Name = 'Test (EXT) project',
            pse__Account__c = acc.Id,
            pse__Billing_Type__c = 'Time and Materials',
            pse__Is_Billable__c = true,
            pse__Region__c = region1.Id,
            pse__Is_Active__c = true,
            pse__Allow_Timecards_Without_Assignment__c = true,
            pse__Allow_Expenses_Without_Assignment__c = true,
            pse__Project_Manager__c = res.Id,
            Sync_Status__c = 'New',
            pse__Project_Type__c = 'IBS',
            Project_Sub_Types__c = 'IBS - Enhancement'
        );
        insert project;

        Role_Budget__c roleBudget = new Role_Budget__c(
            Project__c = project.Id,
            Hours_Budget__c = 100,
            Rate__c = 50,
            Role__c = 'Consultant'
        );
        insert roleBudget;

        project.pse__Stage__c = 'In Progress';
        update project;
    }

    @isTest static void TestMultipleRegionLevels()
    {
        GetExtProjectForRegion.InputParameters input = new GetExtProjectForRegion.InputParameters();
        input.regionId = [Select Id from pse__Region__c where Name = 'Region3'].Id;

        List<GetExtProjectForRegion.OutputParameters> outputs = GetExtProjectForRegion.getProjectForRegion( 
            new List<GetExtProjectForRegion.InputParameters>{ input }
        );

        system.assert( outputs.size() == 1 );
        system.assert( outputs[0].projectIds.size() == 1 );
        system.assert( outputs[0].projectIds[0] == [Select Id from pse__Proj__c].Id );
    }

    @isTest static void TestSameRegionLevel()
    {
        GetExtProjectForRegion.InputParameters input = new GetExtProjectForRegion.InputParameters();
        input.regionId = [Select Id from pse__Region__c where Name = 'Region1'].Id;

        List<GetExtProjectForRegion.OutputParameters> outputs = GetExtProjectForRegion.getProjectForRegion( 
            new List<GetExtProjectForRegion.InputParameters>{ input }
        );

        system.assert( outputs.size() == 1 );
        system.assert( outputs[0].projectIds.size() == 1 );
        system.assert( outputs[0].projectIds[0] == [Select Id from pse__Proj__c].Id );
    }
}