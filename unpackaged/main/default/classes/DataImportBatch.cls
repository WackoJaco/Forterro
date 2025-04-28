public with sharing class DataImportBatch implements Database.Batchable<sObject>, Database.Stateful
{
    public static final boolean OneToOnePTAToAssignments = true;

    public enum Process
    {
        GET_TASK_RATE_ON_TASKS_FROM_ORDERS, // 1
        CREATE_PROJECT_FIRST_PASS,          // 2
        SET_PROJECT_PARENTS,                // 3
        GET_TASK_RATE_FROM_RATE_CARDS,      // 4
        CREATE_PROJECT_TASKS,               // 5
        SET_PROJECT_TASK_PARENTS,           // 6
        CREATE_ROLE_BUDGETS,                // 7
        CREATE_ASSIGNMENTS,                 // 8
        CREATE_PROJECT_TASK_ASSIGNMENTS,    // 9
        CREATE_ONE_TO_ONE_PTAS,             // 10
        UPDATE_PROJECT_PLANNED_HOURS,       // 11
        CREATE_PROJECT_BUDGETS,             // 12
        COMPLETE                            // 13
    }

    public Process GetNext( Process current )
    {
        switch on current
        {
            when GET_TASK_RATE_ON_TASKS_FROM_ORDERS
            {
                return Process.CREATE_PROJECT_FIRST_PASS;
            }
            when CREATE_PROJECT_FIRST_PASS
            {
                return Process.SET_PROJECT_PARENTS;
            }
            when SET_PROJECT_PARENTS
            {
                return Process.GET_TASK_RATE_FROM_RATE_CARDS;
            }
            when GET_TASK_RATE_FROM_RATE_CARDS
            {
                return Process.CREATE_PROJECT_TASKS;
            }
            when CREATE_PROJECT_TASKS
            {
                return Process.SET_PROJECT_TASK_PARENTS;
            }
            when SET_PROJECT_TASK_PARENTS
            {
                return Process.CREATE_ROLE_BUDGETS;
            }
            when CREATE_ROLE_BUDGETS
            {
                return Process.CREATE_ASSIGNMENTS;
            }
            when CREATE_ASSIGNMENTS
            {
                return Process.CREATE_PROJECT_TASK_ASSIGNMENTS;
            }
            when CREATE_PROJECT_TASK_ASSIGNMENTS
            {
                return Process.CREATE_ONE_TO_ONE_PTAS;
            }
            when CREATE_ONE_TO_ONE_PTAS
            {
                return Process.UPDATE_PROJECT_PLANNED_HOURS;
            }
            when UPDATE_PROJECT_PLANNED_HOURS
            {
                return Process.CREATE_PROJECT_BUDGETS;
            }
            when CREATE_PROJECT_BUDGETS
            {
                return Process.COMPLETE;
            }
            when else
            {
                return Process.COMPLETE;
            }
        }
    }

    public Process currentProcess { get; set; }
    public List<String> errorMessages;
    public integer batchSize { get; set; }
    public boolean calendarSyncWasEnabled { get; set; }

    public DataImportBatch() 
    {
        this.errorMessages = new List<String>();
        this.currentProcess = Process.GET_TASK_RATE_ON_TASKS_FROM_ORDERS;
        this.batchSize = 200;

        if( Test.isRunningTest() )
        {
            this.errorMessages.add( 'This is a test message' );
        }
    }

    public database.querylocator start( Database.BatchableContext bc ) 
    {
        // stop this setting trying to spin up too many queuables
        this.calendarSyncWasEnabled = setSyncAssignmentWithExternalCalendar( false );

        Set<string> statuses = new Set<string>();
        string query = '';

        switch on this.currentProcess 
        {
            when GET_TASK_RATE_ON_TASKS_FROM_ORDERS
            {
                statuses = new Set<string>{ '', 'New' };
                query = 'Select Id, Internal_Id__c, Task_Rate__c from Staging_Task__c where Import_Status__c in :statuses';
            }
            when CREATE_PROJECT_FIRST_PASS
            {
                statuses = new Set<string>{ '', 'New' };
                query = 
                    'Select ' +
                    '    Id, ' +
                    '    Project_Name__c, ' +
                    '    Start_Date__c, ' +
                    '    Due_Date__c, ' +
                    '    Type__c, ' +
                    '    Sub_Project_Type__c, ' +
                    '    State__c, ' +
                    '    Billing_Type__c, ' +
                    '    Customer_Name__c, ' +
                    '    Customer_Id__c, ' +
                    '    Project_ID__c, ' +
                    '    Project_Number__c, ' +
                    '    Project_Manager_Name__c, ' +
                    '    Project_ManagerFortX_ID__c, ' +
                    '    Project_ManagerInternal_ID__c, ' +
                    '    Description__c, ' +
                    '    Region__c, ' +
                    '    Order_Id__c, ' +
                    '    CurrencyisoCode, ' +
                    '    Parent_Project_Name__c, ' +
                    '    Parent_Project_Id__c, ' +
                    '    Customer_Contact__c, ' +
                    '    Planned_Hours__c, ' +
                    '    Actual_Hours__c, ' +
                    '    Go_Live_Date__c, ' +
                    '    Import_Status__c, ' +
                    '    Project__c ' +
                    'from ' +
                    '    Staging_Project__c ' +
                    'where ' +
                    '    Import_Status__c in :statuses and ' +
                    '    Project__c = null ';
            }
            when SET_PROJECT_PARENTS
            {
                statuses = new Set<string>{ 'Base Import Complete' };
                query = 
                    'Select ' +
                    '    Id, ' +
                    '    Parent_Project_Id__c, ' +
                    '    Import_Status__c, ' +
                    '    Project__c ' +
                    'from ' +
                    '    Staging_Project__c ' +
                    'where ' +
                    '    Import_Status__c in :statuses and ' +
                    '    Project__c != null ';
            }
            when GET_TASK_RATE_FROM_RATE_CARDS
            {
                statuses = new Set<string>{ '', 'New' };
                query = 
                    'Select ' +
                    '    Id, ' +
                    '    CurrencyIsoCode, ' +
                    '    Project_ID__c, ' +
                    '    Resource_Name__c, ' +
                    '    Task_Role__c, ' +
                    '    Task_Rate__c ' +
                    'from ' +
                    '    Staging_Task__c ' +
                    'where ' +
                    '    Import_Status__c in :statuses and ' +
                    '    ( Task_Rate__c = 0 or Task_Rate__c = null ) ';
            }
            when CREATE_PROJECT_TASKS
            {
                statuses = new Set<string>{ '', 'New' };
                query = 
                    'Select ' +
                    '    Task_Name__c, ' +
                    '    Start_Date__c, ' +
                    '    Due_Date__c, ' +
                    '    Remaining_Effort__c, ' +
                    '    Resource_Name__c, ' +
                    '    Task_ID__c, ' +
                    '    State__c, ' +
                    '    Project_ID__c, ' +
                    '    Task_Type__c, ' +
                    '    Expected_Revenue__c, ' +
                    '    Task_Rate__c, ' +
                    '    Order_Id__c, ' +
                    '    Internal_Id__c, ' +
                    '    Parent_Id__c, ' +
                    '    CurrencyisoCode, ' +
                    '    Training_Module__c, ' +
                    '    Practice__c, ' +
                    '    Timecard_History__c, ' +
                    '    Task_Category__c, ' +
                    '    Description__c, ' +
                    '    Reportable__c, ' +
                    '    Actual_Hours__c, ' +
                    '    Budget__c ' +
                    'From ' +
                    '    Staging_Task__c ' +
                    'Where ' +
                    '    Import_Status__c in :statuses and  ' +
                    '    Project_Task__c = null ';
            }
            when SET_PROJECT_TASK_PARENTS
            {
                statuses = new Set<string>{ 'Base Import Complete' };
                query = 
                    'Select ' +
                    '    Id, ' +
                    '    Parent_Id__c, ' +
                    '    Import_Status__c, ' +
                    '    Project_Task__c, ' +
                    '    Project_Task__r.pse__Project__c ' +
                    'from ' +
                    '    Staging_Task__c ' +
                    'where ' +
                    '    Import_Status__c in :statuses and ' +
                    '    Project_Task__c != null ';
            }
            when CREATE_ROLE_BUDGETS
            {
                statuses = new Set<string>{ 'Parents Associated' };
                query = 
                    'Select ' +
                    '    Id, ' +
                    '    Import_Status__c, ' +
                    '    Project_Task__c, ' +
                    '    Project_Task__r.Id, ' +
                    '    Project_Task__r.pse__Status__c, ' +
                    '    Project_Task__r.pse__Project__c, ' +
                    '    Project_Task__r.pse__Project__r.CurrencyIsoCode, ' +
                    '    Project_Task__r.pse__Project__r.Project_Sub_Types__c, ' +
                    '    Remaining_Effort__c, ' +
                    '    Task_Type__c, ' +
                    '    Task_Rate__c, ' +
                    '    Resource_Name__c, ' +
                    '    Task_Role__c ' +
                    'from ' +
                    '    Staging_Task__c ' +
                    'where ' +
                    '    Import_Status__c in :statuses and ' +
                    '    Task_Type__c in (\'Billable\',\'Productive\') and ' +
                    '    Project_Task__c != null and ' +
                    '    Reportable__c = true ';
            }
            when CREATE_ASSIGNMENTS
            {
                statuses = new Set<string>{ 'Role Budgets Created' };
                query = 
                    'Select ' +
                    '    Id, ' +
                    '    Import_Status__c, ' +
                    '    Project_Task__c, ' +
                    '    Project_Task__r.Name, ' +
                    '    Project_Task__r.pse__Project__c, ' +
                    '    Project_Task__r.pse__Project__r.Name, ' +
                    '    Project_Task__r.pse__Project__r.pse__Account__c, ' +
                    '    Project_Task__r.pse__Project__r.pse__Start_Date__c, ' +
                    '    Project_Task__r.pse__Project__r.pse__End_Date__c, ' +
                    '    Project_Task__r.pse__Project__r.pse__Billing_Type__c, ' +
                    '    Project_Task__r.pse__Project__r.CurrencyIsoCode, ' +
                    '    Task_Type__c, ' +
                    '    Task_Rate__c, ' +
                    '    Resource_Name__c, ' +
                    '    Task_Role__c ' +
                    'from ' +
                    '    Staging_Task__c ' +
                    'where ' +
                    '    Import_Status__c in :statuses and ' +
                    '    Project_Task__c != null and ' +
                    '    Reportable__c = true and ' +
                    '    Task_Type__c != \'Non-Billable\' ';
            }
            when CREATE_PROJECT_TASK_ASSIGNMENTS
            {
                statuses = new Set<string>{ 'Assignments Created' };
                query = 
                    'Select ' +
                    '    Id, ' +
                    '    Import_Status__c, ' +
                    '    Project_Task__c, ' +
                    '    Project_Task__r.Id, ' +
                    '    Project_Task__r.Role_Budget_Link__c, ' +
                    '    Project_Task__r.Role_Budget__c, ' +
                    '    Project_Task__r.pse__Project__c, ' +
                    '    Project_Task__r.pse__Project__r.pse__Account__c, ' +
                    '    Project_Task__r.pse__Project__r.pse__Start_Date__c, ' +
                    '    Project_Task__r.pse__Project__r.pse__End_Date__c, ' +
                    '    Project_Task__r.pse__Project__r.CurrencyIsoCode, ' +
                    '    Task_Type__c, ' +
                    '    Task_Rate__c, ' +
                    '    Remaining_Effort__c, ' +
                    '    Resource_Name__c, ' +
                    '    Task_Role__c, ' +
                    '    Project_Task_Assignment__c ' +
                    'from ' +
                    '    Staging_Task__c ' +
                    'where ' +
                    '    Import_Status__c in :statuses and ' +
                    '    Project_Task__c != null and ' +
                    '    Reportable__c = true and ' +
                    '    Task_Type__c != \'Non-Billable\' ';
            }
            when CREATE_ONE_TO_ONE_PTAS
            {
                statuses = new Set<string>{ 'PTA Over Hours' };
                query = 
                    'Select ' +
                    '    Id, ' +
                    '    Import_Status__c, ' +
                    '    Project_Task__c, ' +
                    '    Project_Task__r.Name, ' +
                    '    Project_Task__r.Id, ' +
                    '    Project_Task__r.Role_Budget_Link__c, ' +
                    '    Project_Task__r.Role_Budget__c, ' +
                    '    Project_Task__r.pse__Project__c, ' +
                    '    Project_Task__r.pse__Project__r.Name, ' +
                    '    Project_Task__r.pse__Project__r.pse__Account__c, ' +
                    '    Project_Task__r.pse__Project__r.pse__Start_Date__c, ' +
                    '    Project_Task__r.pse__Project__r.pse__End_Date__c, ' +
                    '    Project_Task__r.pse__Project__r.pse__Billing_Type__c, ' +
                    '    Project_Task__r.pse__Project__r.CurrencyIsoCode, ' +
                    '    Task_Type__c, ' +
                    '    Task_Rate__c, ' +
                    '    Task_Role__c, ' +
                    '    Remaining_Effort__c, ' +
                    '    Resource_Name__c, ' +
                    '    Project_Task_Assignment__c ' +
                    'from ' +
                    '    Staging_Task__c ' +
                    'where ' +
                    '    Import_Status__c in :statuses and ' +
                    '    Project_Task__c != null and ' +
                    '    Project_Task_Assignment__c = null and ' +
                    '    Reportable__c = true and ' +
                    '    Task_Type__c != \'Non-Billable\' ';
            }
            when UPDATE_PROJECT_PLANNED_HOURS
            {
                statuses = new Set<string>{ 'Parents Associated' };
                query = 
                    'Select ' +
                    '    Id, ' +
                    '    Import_Status__c, ' +
                    '    Project__c ' +
                    'from ' +
                    '    Staging_Project__c ' +
                    'where ' +
                    '    Import_Status__c in :statuses and ' +
                    '    Project__c != null and ' +
                    '    Project__r.Project_Sub_Types__c != \'IBS - Ongoing Work\' ';
            }
            when CREATE_PROJECT_BUDGETS
            {
                statuses = new Set<string>{ 'Parents Associated' };
                query = 
                    'Select ' +
                    '    Id, ' +
                    '    Import_Status__c, ' +
                    '    Project__c ' +
                    'from ' +
                    '    Staging_Project__c ' +
                    'where ' +
                    '    Import_Status__c in :statuses and ' +
                    '    Project__c != null ';
            }
        }

        return Database.getQueryLocator( query );
    }

    public void execute( Database.BatchableContext bc, List<sObject> records )
    {
        try
        {
            switch on this.currentProcess 
            {
                when GET_TASK_RATE_ON_TASKS_FROM_ORDERS
                {
                    Set<string> taskIdentifiers = new Set<string>();
                    Map<string,List<Staging_Task__c>> identifierToTasks = new Map<string,List<Staging_Task__c>>();
                    for( Staging_Task__c task : (List<Staging_Task__c>)records )
                    {
                        if( !string.isBlank( task.Internal_Id__c ) )
                        {
                            taskIdentifiers.add( task.Internal_Id__c );
                            if( !identifierToTasks.containsKey( task.Internal_Id__c ) )
                            {
                                identifierToTasks.put( task.Internal_Id__c, new List<Staging_Task__c>() );
                            }
                            identifierToTasks.get( task.Internal_Id__c ).add( task );
                        }
                    }

                    if( taskIdentifiers.size() > 0 )
                    {
                        for( Staging_Order__c order : [Select Id, Hourly_Net_Price__c, Order_Task_Identifier__c from Staging_Order__c where Order_Task_Identifier__c in :taskIdentifiers] )
                        {
                            if( identifierToTasks.containsKey( order.Order_Task_Identifier__c ) )
                            {
                                for( Staging_Task__c task : identifierToTasks.get( order.Order_Task_Identifier__c ) )
                                {
                                    task.Task_Rate__c = order.Hourly_Net_Price__c;
                                }
                            }
                        }

                        update records;
                    }
                }
                when CREATE_PROJECT_FIRST_PASS
                {
                    Set<string> regionNames = new Set<string>();
                    Set<string> resourceIdentifiers = new Set<string>();
                    Set<string> customerIdentifiers = new Set<string>();

                    for( Staging_Project__c stagingProject : (List<Staging_Project__c>)records )
                    {
                        if( !string.isBlank( stagingProject.Region__c ) )
                        {
                            regionNames.add( stagingProject.Region__c );
                        }
                        if( !string.isBlank( stagingProject.Project_Manager_Name__c ) )
                        {
                            resourceIdentifiers.add( stagingProject.Project_Manager_Name__c );
                        }
                        if( !string.isBlank( stagingProject.Customer_Id__c ) )
                        {
                            customerIdentifiers.add( stagingProject.Customer_Id__c );
                        }
                    }

                    Map<string,pse__Region__c> nameToRegions = new Map<string,pse__Region__c>();
                    for( pse__Region__c region : [Select Id, Name, pse__Default_Work_Calendar__c from pse__Region__c where Name in :regionNames] )
                    {
                        nameToRegions.put( region.Name, region );
                    }

                    Map<string,Account> customers = new Map<string,Account>();
                    for( Account acc : [Select Id, External_Id__c from Account where External_Id__c in :customerIdentifiers] )
                    {
                        customers.put( acc.External_Id__c, acc );
                    }

                    Map<string,Contact> contacts = new Map<string,Contact>();
                    for( Contact con : [Select Id, Name from Contact where Name in :resourceIdentifiers] )
                    {
                        contacts.put( con.Name.toUpperCase(), con );
                    }

                    Id recordTypeId = Schema.SObjectType.pse__Proj__c.getRecordTypeInfosByName().get('Customer Project').getRecordTypeId();

                    Map<Id,pse__Proj__c> stagingToReal = new Map<Id,pse__Proj__c>();

                    for( Staging_Project__c stagingProject : (List<Staging_Project__c>)records )
                    {
                        pse__Region__c region = nameToRegions.get( stagingProject.Region__c );
                        if( region == null )
                        {
                            errorMessages.add( stagingProject.Id + ': Failed to find the region with name "' + stagingProject.Region__c + '"' );
                        }

                        pse__Proj__c project = new pse__Proj__c(
                            Name = stagingProject.Project_Name__c.left( 80 ),
                            pse__Start_Date__c = stagingProject.Start_Date__c,
                            pse__End_Date__c = stagingProject.Due_Date__c,
                            pse__Project_Type__c = getProjectType( stagingProject.Type__c ),
                            Project_Sub_Types__c = getProjectSubTypes( stagingProject.Sub_Project_Type__c ),
                            pse__Stage__c = getProjectStage( stagingProject.State__c ),
                            pse__Billing_Type__c = stagingProject.Billing_Type__c,
                            pse__Account__c = customers.get( stagingProject.Customer_Id__c )?.Id,
                            External_Project_Id__c = stagingProject.Project_ID__c,
                            pse__Notes__c = stagingProject.Description__c,
                            pse__Project_Manager__c = contacts.get( stagingProject.Project_Manager_Name__c?.toUpperCase() )?.Id,
                            pse__Region__c = region?.Id,
                            Order_Id__c = stagingProject.Order_Id__c,
                            CurrencyIsoCode = stagingProject.CurrencyIsoCode,
                            pse__Is_Active__c = true,
                            pse__is_Billable__c = true,
                            RecordTypeId = recordTypeId,
                            Customer_Contact_Reference__c = stagingProject.Customer_Contact__c,
                            pse__Work_Calendar__c = region?.pse__Default_Work_Calendar__c,
                            pse__Include_In_Forecasting__c = true,
                            Total_Orginal_Estimated_Hours__c = stagingProject.Planned_Hours__c,
                            Actual_Hours_Migrated__c = stagingProject.Actual_Hours__c,
                            Go_Live_Date__c = stagingProject.Go_Live_Date__c
                        );

                        stagingToReal.put( stagingProject.Id, project );
                    }

                    List<Database.SaveResult> results = database.insert( stagingToReal.values(), false );

                    for( Integer i = 0; i < results.size(); i++ )
                    {
                        Database.SaveResult result = results[i];
                        pse__Proj__c project = stagingToReal.values()[i];

                        if( !result.isSuccess() )
                        {
                            // insert failed, figure out the associated staging record and save the error message
                            for( Staging_Project__c stagingProject : (List<Staging_Project__c>)records )
                            {
                                if( stagingToReal.get( stagingProject.Id ) == project )
                                {
                                    errorMessages.add( stagingProject.Id + ': ' + result.getErrors()[0].getMessage() );
                                    break;
                                }
                            }
                        }
                    }

                    for( Staging_Project__c stagingProject : (List<Staging_Project__c>)records )
                    {
                        stagingProject.Project__c = stagingToReal.get( stagingProject.Id ).Id;

                        if( stagingProject.Project__c != null )
                        {
                            stagingProject.Import_Status__c = 'Base Import Complete';
                        }
                    }

                    update records;
                }
                when SET_PROJECT_PARENTS
                {
                    Set<string> parentIds = new Set<string>();
                    for( Staging_Project__c stagingProject : (List<Staging_Project__c>)records )
                    {
                        if( !string.isBlank( stagingProject.Parent_Project_Id__c ) )
                        {
                            parentIds.add( stagingProject.Parent_Project_Id__c );
                        }
                    }

                    Map<string,Id> projectIdToPSAProjectId = new Map<string,Id>();
                    for( Staging_Project__c proj : [Select Id, Project_ID__c, Project__c from Staging_Project__c where Project_ID__c in :parentIds] )
                    {
                        projectIdToPSAProjectId.put( proj.Project_ID__c, proj.Project__c );
                    }

                    Map<Id,Id> childToParentPSAProjectIds = new Map<Id,Id>();
                    for( Staging_Project__c stagingProject : (List<Staging_Project__c>)records )
                    {
                        if( projectIdToPSAProjectId.containsKey( stagingProject.Parent_Project_Id__c ) )
                        {
                            childToParentPSAProjectIds.put( stagingProject.Project__c, projectIdToPSAProjectId.get( stagingProject.Parent_Project_Id__c ) );
                        }
                        stagingProject.Import_Status__c = 'Parents Associated';
                    }

                    List<pse__Proj__c> projectsToUpdate = [Select Id, pse__Parent_Project__c from pse__Proj__c where Id in :childToParentPSAProjectIds.keySet()];
                    for( pse__Proj__c proj : projectsToUpdate )
                    {
                        proj.pse__Parent_Project__c = childToParentPSAProjectIds.get( proj.Id );
                    }
                    update projectsToUpdate;

                    update records;
                }
                when GET_TASK_RATE_FROM_RATE_CARDS
                {
                    Set<string> projectIds = new Set<string>();
                    Set<string> resourceNames = new Set<string>();
                    Set<string> currencyCodes = new Set<string>();

                    for( Staging_Task__c stagingTask : (List<Staging_Task__c>)records )
                    {
                        if( !string.isBlank( stagingTask.Project_ID__c ) )
                        {
                            projectIds.add( stagingTask.Project_ID__c );
                        }

                        if( !string.isBlank( stagingTask.Resource_Name__c ) )
                        {
                            resourceNames.add( stagingTask.Resource_Name__c );
                        }
                    }

                    Map<string,Contact> contactMap = new Map<string,Contact>();
                    for( Contact con : 
                        [Select 
                            Id, 
                            Name,
                            pse__Resource_Role__c
                        from 
                            Contact 
                        where 
                            Name in :resourceNames and 
                            pse__Is_Resource__c = true and 
                            pse__Is_Resource_Active__c = true] )
                    {
                        contactMap.put( con.Name.toUpperCase(), con );
                    }

                    Map<string,Id> projectIdToAccountId = new Map<string,Id>();
                    Map<string,string> projectIdToCurrency = new Map<string,string>();
                    for( pse__Proj__c project : [Select Id, External_Project_Id__c, pse__Account__c, CurrencyIsoCode from pse__Proj__c where External_Project_Id__c in :projectIds] )
                    {
                        projectIdToAccountId.put( project.External_Project_Id__c, project.pse__Account__c );
                        projectIdToCurrency.put( project.External_Project_Id__c, project.CurrencyIsoCode );
                    }

                    Map<Id,string> stagingTaskIdToRole = new Map<Id,string>();
                    for( Staging_Task__c stagingTask : (List<Staging_Task__c>)records )
                    {
                        string role = stagingTask.Task_Role__c;
                        if( string.isBlank( role ) )
                        {
                            role = contactMap.get( stagingTask.Resource_Name__c?.toUpperCase() )?.pse__Resource_Role__c;
                        }

                        stagingTaskIdToRole.put( stagingTask.Id, role );
                    }

                    Map<string,decimal> rateCardMap = new Map<string,decimal>();
                    for( pse__Rate_Card__c rateCard : 
                        [Select 
                            Id,
                            pse__Account__c,
                            CurrencyIsoCode,
                            pse__Role__c,
                            pse__Suggested_Bill_Rate__c
                        from 
                            pse__Rate_Card__c 
                        where 
                            pse__Account__c in :projectIdToAccountId.values() and
                            CurrencyIsoCode in :projectIdToCurrency.values() and
                            pse__Role__c in :stagingTaskIdToRole.values()] )
                    {
                        string key = rateCard.pse__Account__c + '|' + rateCard.CurrencyIsoCode + '|' + rateCard.pse__Role__c;
                        rateCardMap.put( key, rateCard.pse__Suggested_Bill_Rate__c );
                    }

                    List<Staging_Task__c> changedStagingTasks = new List<Staging_Task__c>();
                    for( Staging_Task__c stagingTask : (List<Staging_Task__c>)records )
                    {
                        Id accountId = projectIdToAccountId.get( stagingTask.Project_ID__c );
                        string currencyCode = projectIdToCurrency.get( stagingTask.Project_ID__c );
                        string role = stagingTaskIdToRole.get( stagingTask.Id );
                        string key = accountId + '|' + currencyCode + '|' + role;

                        if( rateCardMap.containsKey( key ) )
                        {
                            stagingTask.Task_Rate__c = rateCardMap.get( key );
                            changedStagingTasks.add( stagingTask );
                        }
                    }

                    update changedStagingTasks;
                }
                when CREATE_PROJECT_TASKS
                {
                    Set<string> practiceNames = new Set<string>();
                    Set<string> projectIds = new Set<string>();
                    for( Staging_Task__c stagingTask : (List<Staging_Task__c>)records )
                    {
                        if( !string.isBlank( stagingTask.Project_ID__c ) )
                        {
                            projectIds.add( stagingTask.Project_ID__c );
                        }

                        if( !string.isBlank( stagingTask.Practice__c ) )
                        {
                            practiceNames.add( stagingTask.Practice__c );
                        }
                    }

                    Map<string,pse__Proj__c> projectIdToActual = new Map<string,pse__Proj__c>();
                    for( pse__Proj__c project : [Select Id, External_Project_Id__c, pse__Work_Calendar__c from pse__Proj__c where External_Project_Id__c in :projectIds] )
                    {
                        projectIdToActual.put( project.External_Project_Id__c, project );
                    }

                    Map<string,Id> practiceNameToId = new Map<string,Id>();
                    for( pse__Practice__c practice : [Select Id, Name from pse__Practice__c where Name in :practiceNames] )
                    {
                        practiceNameToId.put( practice.Name, practice.Id );
                    }

                    Map<Id,pse__Project_Task__c> stagingToReal = new Map<Id,pse__Project_Task__c>();
                    for( Staging_Task__c stagingTask : (List<Staging_Task__c>)records )
                    {
                        pse__Project_Task__c projectTask = new pse__Project_Task__c(
                            Name = stagingTask.Task_Name__c.left( 80 ),
                            pse__Start_Date_Time__c = DateTime.newInstance( stagingTask.Start_Date__c, time.newInstance( 9, 0, 0, 0 ) ),
                            pse__End_Date_Time__c = DateTime.newInstance( stagingTask.Due_Date__c, time.newInstance( 17, 0, 0, 0 ) ),
                            pse__Estimated_Hours__c = stagingTask.Remaining_Effort__c,
                            pse__External_Task_ID__c = stagingTask.Task_ID__c,
                            pse__Status__c = getTaskState( stagingTask.State__c ),
                            pse__Project__c = projectIdToActual.get( stagingTask.Project_ID__c )?.Id,
                            pse__Work_Calendar__c = projectIdToActual.get( stagingTask.Project_ID__c )?.pse__Work_Calendar__c,
                            CLZ_Internal_Id__c = stagingTask.Internal_Id__c,
                            CurrencyisoCode = stagingTask.CurrencyisoCode,
                            CTC_Training_Code__c = stagingTask.Training_Module__c,
                            Practice__c = practiceNameToId.get( stagingTask.Practice__c ),
                            Timecard_History__c = stagingTask.Timecard_History__c,
                            Task_Type__c = stagingTask.Task_Category__c,
                            Order_Id__c = stagingTask.Order_Id__c,
                            pse__Description__c = stagingTask.Description__c,
                            pse__Assigned_Resources_Long__c = stagingTask.Resource_Name__c,
                            Original_Estimated_Hours__c = stagingTask.Budget__c,
                            Actual_Hours_Migrated__c = stagingTask.Actual_Hours__c
                        );

                        stagingToReal.put( stagingTask.Id, projectTask );
                    }

                    List<Database.SaveResult> results = database.insert( stagingToReal.values(), false );

                    for( Integer i = 0; i < results.size(); i++ )
                    {
                        Database.SaveResult result = results[i];
                        pse__Project_Task__c projectTask = stagingToReal.values()[i];

                        if( !result.isSuccess() )
                        {
                            // insert failed, figure out the associated staging record and save the error message
                            for( Staging_Task__c stagingTask : (List<Staging_Task__c>)records )
                            {
                                if( stagingToReal.get( stagingTask.Id ) == projectTask )
                                {
                                    errorMessages.add( stagingTask.Id + ': ' + result.getErrors()[0].getMessage() );
                                    break;
                                }
                            }
                        }
                    }

                    for( Staging_Task__c stagingTask : (List<Staging_Task__c>)records )
                    {
                        stagingTask.Project_Task__c = stagingToReal.get( stagingTask.Id ).Id;

                        if( stagingTask.Project_Task__c != null )
                        {
                            stagingTask.Import_Status__c = 'Base Import Complete';
                        }
                    }

                    update records;
                }
                when SET_PROJECT_TASK_PARENTS
                {
                    Set<string> parentIds = new Set<string>();
                    for( Staging_Task__c stagingTask : (List<Staging_Task__c>)records )
                    {
                        if( !string.isBlank( stagingTask.Parent_Id__c ) )
                        {
                            parentIds.add( stagingTask.Parent_Id__c );
                        }
                    }

                    Map<string,List<pse__Project_Task__c>> taskIdToPSATasks = new Map<string,List<pse__Project_Task__c>>();
                    for( Staging_Task__c task : 
                        [Select 
                            Id, 
                            Task_ID__c, 
                            Project_Task__c, 
                            Project_Task__r.Id, 
                            Project_Task__r.pse__Project__c 
                        from 
                            Staging_Task__c 
                        where 
                            Task_ID__c in :parentIds] )
                    {
                        if( !taskIdToPSATasks.containsKey( task.Task_ID__c ) )
                        {
                            taskIdToPSATasks.put( task.Task_ID__c, new List<pse__Project_Task__c>() );
                        }
                        taskIdToPSATasks.get( task.Task_ID__c ).add( task.Project_Task__r );
                    }

                    Map<Id,Id> childToParentPSATaskIds = new Map<Id,Id>();
                    for( Staging_Task__c stagingTask : (List<Staging_Task__c>)records )
                    {
                        if( taskIdToPSATasks.containsKey( stagingTask.Parent_Id__c ) )
                        {
                            for( pse__Project_Task__c projectTask : taskIdToPSATasks.get( stagingTask.Parent_Id__c ) )
                            {
                                if( projectTask.pse__Project__c == stagingTask.Project_Task__r.pse__Project__c )
                                {
                                    childToParentPSATaskIds.put( stagingTask.Project_Task__c, projectTask.Id );
                                }
                            }
                        }
                        stagingTask.Import_Status__c = 'Parents Associated';
                    }

                    List<pse__Project_Task__c> projectTasksToUpdate = [Select Id, pse__Parent_Task__c from pse__Project_Task__c where Id in :childToParentPSATaskIds.keySet()];
                    for( pse__Project_Task__c projectTask : projectTasksToUpdate )
                    {
                        projectTask.pse__Parent_Task__c = childToParentPSATaskIds.get( projectTask.Id );
                    }
                    update projectTasksToUpdate;

                    update records;
                }
                when CREATE_ROLE_BUDGETS
                {
                    Set<string> resourceNames = new Set<string>();
                    for( Staging_Task__c stagingTask : (List<Staging_Task__c>)records )
                    {
                        if( !string.isBlank( stagingTask.Resource_Name__c ) )
                        {
                            resourceNames.add( stagingTask.Resource_Name__c );
                        }

                        if( stagingTask.Task_Rate__c == null )
                        {
                            stagingTask.Task_Rate__c = 0;
                        }
                    }

                    Map<string,Contact> contactMap = new Map<string,Contact>();
                    for( Contact con : 
                        [Select 
                            Id, 
                            Name,
                            pse__Resource_Role__c
                        from 
                            Contact 
                        where 
                            Name in :resourceNames and 
                            pse__Is_Resource__c = true and 
                            pse__Is_Resource_Active__c = true] )
                    {
                        contactMap.put( con.Name.toUpperCase(), con );
                    }

                    Map<string,List<Staging_Task__c>> keyToTasks = new Map<string,List<Staging_Task__c>>();
                    for( Staging_Task__c stagingTask : (List<Staging_Task__c>)records )
                    {
                        if( stagingTask.Project_Task__r.pse__Project__c != null &&
                            contactMap.containsKey( stagingTask.Resource_Name__c?.toUpperCase() ) &&
                            !string.isBlank( stagingTask.Task_Type__c ) &&
                            stagingTask.Task_Rate__c != null &&
                            stagingTask.Project_Task__r.pse__Project__r.Project_Sub_Types__c != 'IBS - Ongoing Work' )
                        {
                            string key = makeKeyForRoleBudget( stagingTask, contactMap );
                            if( !keyToTasks.containsKey( key ) )
                            {
                                keyToTasks.put( key, new List<Staging_Task__c>() );
                            }
                            keyToTasks.get( key ).add( stagingTask );
                        }
                    }

                    Map<string,Role_Budget__c> existingRoleBudgets = new Map<string,Role_Budget__c>();
                    for( Role_Budget__c budget : [Select Id, External_Id__c, Hours_Budget__c from Role_Budget__c where External_Id__c in :keyToTasks.keySet()] )
                    {
                        existingRoleBudgets.put( budget.External_Id__c, budget );
                    }

                    for( string key : keyToTasks.keySet() )
                    {
                        for( Staging_Task__c stagingTask : keyToTasks.get( key ) )
                        {
                            if( existingRoleBudgets.containsKey( key ) )
                            {
                                existingRoleBudgets.get( key ).Hours_Budget__c += stagingTask.Remaining_Effort__c;
                            }
                            else
                            {
                                string role = stagingTask.Task_Role__c;
                                if( string.isBlank( role ) )
                                {
                                    role = contactMap.get( stagingTask.Resource_Name__c?.toUpperCase() )?.pse__Resource_Role__c;
                                }

                                Role_Budget__c budget = new Role_Budget__c(
                                    Role__c = role,
                                    Hours_Budget__c = stagingTask.Remaining_Effort__c,
                                    Rate__c = stagingTask.Task_Rate__c,
                                    Project__c = stagingTask.Project_Task__r.pse__Project__c,
                                    CurrencyIsoCode = stagingTask.Project_Task__r.pse__Project__r.CurrencyIsoCode,
                                    Credited_Hours__c = stagingTask.Task_Type__c == 'Productive' ? true : false,
                                    Reference__c = ( role + '|' + stagingTask.Task_Type__c.left( 1 ) + '|' + string.valueOf( stagingTask.Task_Rate__c.setScale( 2 ) ) ).left( 80 ),
                                    External_Id__c = key
                                );

                                existingRoleBudgets.put( key, budget );
                            }
                        }
                    }

                    upsert existingRoleBudgets.values();

                    for( Staging_Task__c stagingTask : (List<Staging_Task__c>)records )
                    {
                        stagingTask.Import_Status__c = 'Role Budgets Created';
                        if( stagingTask.Project_Task__r.pse__Status__c == 'Complete' )
                        {
                            // if complete we don't want to create assignments or PTAs
                            stagingTask.Import_Status__c = 'Complete';
                        }
                    }
                    update records;
                }
                when CREATE_ASSIGNMENTS
                {
                    Set<string> resourceNames = new Set<string>();
                    for( Staging_Task__c stagingTask : (List<Staging_Task__c>)records )
                    {
                        if( !string.isBlank( stagingTask.Resource_Name__c ) )
                        {
                            resourceNames.add( stagingTask.Resource_Name__c );
                        }

                        if( stagingTask.Task_Rate__c == null )
                        {
                            stagingTask.Task_Rate__c = 0;
                        }
                    }

                    Map<string,Contact> contactMap = new Map<string,Contact>();
                    for( Contact con : 
                        [Select 
                            Id, 
                            Name,
                            pse__Resource_Role__c
                        from 
                            Contact 
                        where 
                            Name in :resourceNames and 
                            pse__Is_Resource__c = true and 
                            pse__Is_Resource_Active__c = true] )
                    {
                        contactMap.put( con.Name.toUpperCase(), con );
                    }

                    Map<string,string> assignmentKeyToRoleBudgetKey = new Map<string,string>();

                    Map<string,Staging_Task__c> keyToTask = new Map<string,Staging_Task__c>();
                    for( Staging_Task__c stagingTask : (List<Staging_Task__c>)records )
                    {
                        if( stagingTask.Project_Task__r.pse__Project__c != null &&
                            contactMap.containsKey( stagingTask.Resource_Name__c?.toUpperCase() ) &&
                            !string.isBlank( stagingTask.Task_Type__c ) &&
                            stagingTask.Task_Rate__c != null )
                        {
                            string key = makeKeyForAssignment( stagingTask, contactMap );
                            keyToTask.put( key, stagingTask );
                            assignmentKeyToRoleBudgetKey.put( key, makeKeyForRoleBudget( stagingTask, contactMap ) );
                        }
                    }

                    // search for role budgets
                    Map<string,Id> roleBudgetKeyToId = new Map<string,Id>();
                    for( Role_Budget__c budget : [Select Id, External_Id__c, Hours_Budget__c from Role_Budget__c where External_Id__c in :assignmentKeyToRoleBudgetKey.values()] )
                    {
                        roleBudgetKeyToId.put( budget.External_Id__c, budget.Id );
                    }

                    // search for schedules
                    Map<string,pse__Schedule__c> schedules = new Map<string,pse__Schedule__c>();
                    for( pse__Schedule__c sched : [Select Id, pse_Assignment_External_ID_c__c from pse__Schedule__c where pse_Assignment_External_ID_c__c in :keyToTask.keySet()] )
                    {
                        schedules.put( sched.pse_Assignment_External_ID_c__c, sched );
                    }

                    List<pse__Schedule__c> newSchedules = new List<pse__Schedule__c>();
                    for( string key : keyToTask.keySet() )
                    {
                        if( !schedules.containsKey( key ) )
                        {
                            pse__Schedule__c sched = new pse__Schedule__c(
                                pse__Start_Date__c = keyToTask.get( key ).Project_Task__r.pse__Project__r.pse__Start_Date__c,
                                pse__End_Date__c = keyToTask.get( key ).Project_Task__r.pse__Project__r.pse__End_Date__c,
                                pse_Assignment_External_ID_c__c = key,
                                CurrencyIsoCode = keyToTask.get( key ).Project_Task__r.pse__Project__r.CurrencyIsoCode );
                            
                            newSchedules.add( sched );
                            schedules.put( sched.pse_Assignment_External_ID_c__c, sched );
                        }
                    }

                    insert newSchedules;

                    Set<string> existingAssignmentKeys = new Set<string>();
                    for( pse__Assignment__c ass : [Select Id, Assignment_External_ID__c from pse__Assignment__c where Assignment_External_ID__c in :keyToTask.keySet()] )
                    {
                        existingAssignmentKeys.add( ass.Assignment_External_ID__c );
                    }

                    List<pse__Assignment__c> newAssignments = new List<pse__Assignment__c>();
                    for( string key : keyToTask.keySet() )
                    {
                        if( !existingAssignmentKeys.contains( key ) )
                        {
                            string role = keyToTask.get( key ).Task_Role__c;
                            if( string.isBlank( role ) )
                            {
                                role = contactMap.get( keyToTask.get( key ).Resource_Name__c?.toUpperCase() )?.pse__Resource_Role__c;
                            }

                            Set<string> creditedTaskTypes = new Set<string>{ 'Credited', 'Productive' };
                            
                            decimal billRate = keyToTask.get( key ).Task_Type__c == 'Billable' ? keyToTask.get( key ).Task_Rate__c : 0;
                            if( keyToTask.get( key ).Project_Task__r.pse__Project__r.pse__Billing_Type__c == 'Fixed Price' ||
                                keyToTask.get( key ).Project_Task__r.pse__Project__r.pse__Billing_Type__c == 'Subscription' )
                            {
                                billRate = 0;
                            }

                            pse__Assignment__c assignment = new pse__Assignment__c(
                                Name = ( keyToTask.get( key ).Project_Task__r.pse__Project__r.Name  + '-' + keyToTask.get( key ).Project_Task__r.Name ).left( 80 ),
                                pse__Status__c = 'Scheduled',
                                pse__Project__c = keyToTask.get( key ).Project_Task__r.pse__Project__c,
                                CurrencyIsoCode = keyToTask.get( key ).Project_Task__r.pse__Project__r.CurrencyIsoCode,
                                pse__Resource__c = contactMap.get( keyToTask.get( key ).Resource_Name__c?.toUpperCase() ).Id,
                                pse__Role__c = role,
                                pse__Schedule__c = schedules.get( key ).Id,
                                pse__Is_Billable__c = keyToTask.get( key ).Task_Type__c == 'Billable' ? true : false,
                                pse__Bill_Rate__c = billRate,
                                pse__Time_Credited__c = creditedTaskTypes.contains( keyToTask.get( key ).Task_Type__c ) ? true : false,
                                pse__Use_Resource_Default_Cost_Rate__c = true,
                                Assignment_External_ID__c = key,
                                Role_Budget__c = roleBudgetKeyToId.get( assignmentKeyToRoleBudgetKey.get( key ) )
                            );

                            newAssignments.add( assignment );
                            existingAssignmentKeys.add( key );
                        }
                    }

                    List<Database.SaveResult> results = database.insert( newAssignments, false );
                    Set<string> failedKeys = new Set<string>();

                    List<pse__Assignment__c> assignmentsToUpdate = new List<pse__Assignment__c>();

                    for( Integer i = 0; i < results.size(); i++ )
                    {
                        Database.SaveResult result = results[i];
                        pse__Assignment__c assignment = newAssignments[i];

                        if( !result.isSuccess() )
                        {
                            for( Staging_Task__c stagingTask : (List<Staging_Task__c>)records )
                            {
                                string key = makeKeyForAssignment( stagingTask, contactMap );
                                if( key == assignment.Assignment_External_ID__c )
                                {
                                    failedKeys.add( key );
                                    errorMessages.add( stagingTask.Id + ': ' + result.getErrors()[0].getMessage() );
                                    break;
                                }
                            }
                        }
                        else
                        {
                            assignmentsToUpdate.add( assignment );
                        }
                    }

                    if( assignmentsToUpdate.size() > 0 )
                    {
                        update assignmentsToUpdate;
                    }

                    // finally mark all tasks as complete
                    for( Staging_Task__c stagingTask : (List<Staging_Task__c>)records )
                    {
                        string key = makeKeyForAssignment( stagingTask, contactMap );
                        if( !failedKeys.contains( key ) )
                        {
                            stagingTask.Import_Status__c = 'Assignments Created';
                        }
                    }
                    update records;
                }
                when CREATE_PROJECT_TASK_ASSIGNMENTS
                {
                    Set<string> resourceNames = new Set<string>();
                    for( Staging_Task__c stagingTask : (List<Staging_Task__c>)records )
                    {
                        if( !string.isBlank( stagingTask.Resource_Name__c ) )
                        {
                            resourceNames.add( stagingTask.Resource_Name__c );
                        }

                        if( stagingTask.Task_Rate__c == null )
                        {
                            stagingTask.Task_Rate__c = 0;
                        }
                    }

                    Map<string,Contact> contactMap = new Map<string,Contact>();
                    for( Contact con : 
                        [Select 
                            Id, 
                            Name,
                            pse__Resource_Role__c
                        from 
                            Contact 
                        where 
                            Name in :resourceNames and 
                            pse__Is_Resource__c = true and 
                            pse__Is_Resource_Active__c = true] )
                    {
                        contactMap.put( con.Name.toUpperCase(), con );
                    }

                    Map<string,string> assignmentKeyToRoleBudgetKey = new Map<string,string>();
                    Map<string,Staging_Task__c> keyToTask = new Map<string,Staging_Task__c>();
                    Map<string,string> keyToAssignmentKey = new Map<string,string>();

                    for( Staging_Task__c stagingTask : (List<Staging_Task__c>)records )
                    {
                        if( stagingTask.Project_Task__r.pse__Project__c != null &&
                            contactMap.containsKey( stagingTask.Resource_Name__c?.toUpperCase() ) &&
                            !string.isBlank( stagingTask.Task_Type__c ) &&
                            stagingTask.Task_Rate__c != null )
                        {
                            keyToTask.put( makeKeyForPTA( stagingTask, contactMap ), stagingTask );
                            keyToAssignmentKey.put(
                                makeKeyForPTA( stagingTask, contactMap ),
                                makeKeyForAssignment( stagingTask, contactMap )
                             );

                            assignmentKeyToRoleBudgetKey.put( makeKeyForPTA( stagingTask, contactMap ), makeKeyForRoleBudget( stagingTask, contactMap ) );
                        }
                    }

                    // search for role budgets
                    Map<string,Id> roleBudgetKeyToId = new Map<string,Id>();
                    Map<string,string> roleBudgetKeyToReference = new Map<string,string>();
                    for( Role_Budget__c budget : [Select Id, External_Id__c, Hours_Budget__c, Reference__c from Role_Budget__c where External_Id__c in :assignmentKeyToRoleBudgetKey.values()] )
                    {
                        roleBudgetKeyToId.put( budget.External_Id__c, budget.Id );
                        roleBudgetKeyToReference.put( budget.External_Id__c, budget.Reference__c );
                    }

                    Map<string,Id> assignmentKeyToId = new Map<string,Id>();
                    for( pse__Assignment__c assignment : [Select Id, Assignment_External_ID__c from pse__Assignment__c where Assignment_External_ID__c in :keyToAssignmentKey.values()] )
                    {
                        assignmentKeyToId.put( assignment.Assignment_External_ID__c, assignment.Id );
                    }

                    // check for existing PTAs
                    Set<string> existingPTAKeys = new Set<string>();
                    for( pse__Project_Task_Assignment__c pta : [Select Id, External_Id__c from pse__Project_Task_Assignment__c where External_Id__c in :keyToTask.keySet()] )
                    {
                        existingPTAKeys.add( pta.External_Id__c );
                    }

                    Map<Id,pse__Project_Task_Assignment__c> stagingTaskToPTA = new Map<Id,pse__Project_Task_Assignment__c>();
                    Map<Id,pse__Project_Task__c> projectTasksToUpdate = new Map<Id,pse__Project_Task__c>();

                    List<pse__Project_Task_Assignment__c> newPTAs = new List<pse__Project_Task_Assignment__c>();
                    for( string key : keyToTask.keySet() )
                    {
                        if( !existingPTAKeys.contains( key ) )
                        {
                            string role = keyToTask.get( key ).Task_Role__c;
                            if( string.isBlank( role ) )
                            {
                                role = contactMap.get( keyToTask.get( key ).Resource_Name__c?.toUpperCase() )?.pse__Resource_Role__c;
                            }

                            pse__Project_Task_Assignment__c pta = new pse__Project_Task_Assignment__c(
                                pse__Project_Task__c = keyToTask.get( key ).Project_Task__c,
                                External_Id__c = key,
                                pse__Estimated_Hours__c = keyToTask.get( key ).Remaining_Effort__c,
                                pse__Resource__c = contactMap.get( keyToTask.get( key ).Resource_Name__c?.toUpperCase() ).Id,
                                Project__c = keyToTask.get( key ).Project_Task__r.pse__Project__c,
                                pse__Assignment__c = assignmentKeyToId.get( keyToAssignmentKey.get( key ) ),
                                CurrencyIsoCode = keyToTask.get( key ).Project_Task__r.pse__Project__r.CurrencyIsoCode,
                                pse__Resource_Role__c = role,
                                Role_Budget__c = roleBudgetKeyToId.get( assignmentKeyToRoleBudgetKey.get( key ) )
                            );

                            pse__Project_Task__c projectTask = keyToTask.get( key ).Project_Task__r;
                            projectTask.Role_Budget_Link__c = pta.Role_Budget__c;
                            projectTask.Role_Budget__c = roleBudgetKeyToReference.get( assignmentKeyToRoleBudgetKey.get( key ) );
                            projectTasksToUpdate.put( projectTask.Id, projectTask );

                            newPTAs.add( pta );
                            existingPTAKeys.add( key );
                            stagingTaskToPTA.put( keyToTask.get( key ).Id, pta );
                        }
                    }

                    List<Database.SaveResult> results = database.insert( newPTAs, false );
                    Set<string> successfullySavedKeys = new Set<string>();

                    for( Integer i = 0; i < results.size(); i++ )
                    {
                        Database.SaveResult result = results[i];
                        pse__Project_Task_Assignment__c pta = newPTAs[i];

                        if( !result.isSuccess() )
                        {
                            for( Staging_Task__c stagingTask : (List<Staging_Task__c>)records )
                            {
                                string key = makeKeyForPTA( stagingTask, contactMap );
                                if( key == pta.External_Id__c )
                                {
                                    string message = result.getErrors()[0].getMessage();
                                    if( message.containsIgnoreCase( 'Scheduled hours exceed 24 hours per day. Some assignments will not be generated' ) )
                                    {
                                        // special case, we try again next step with a 1:1 assignment
                                        stagingTask.Import_Status__c = 'PTA Over Hours';
                                    }
                                    else
                                    {
                                        errorMessages.add( stagingTask.Id + ': ' + result.getErrors()[0].getMessage() );
                                    }

                                    break;
                                }
                            }
                        }
                        else
                        {
                            successfullySavedKeys.add( pta.External_Id__c );
                        }
                    }

                    for( Staging_Task__c stagingTask : (List<Staging_Task__c>)records )
                    {
                        string key = makeKeyForPTA( stagingTask, contactMap );
                        if( successfullySavedKeys.contains( key ) )
                        {
                            stagingTask.Import_Status__c = 'Complete';
                            if( stagingTaskToPTA.containsKey( stagingTask.Id ) )
                            {
                                stagingTask.Project_Task_Assignment__c = stagingTaskToPTA.get( stagingTask.Id ).Id;
                            }
                        }
                        else
                        {
                            // don't update project tasks to budgets if the staging task failed
                            projectTasksToUpdate.remove( stagingTask.Project_Task__c );
                        }
                    }
                    update records;
                    update projectTasksToUpdate.values();
                }
                when CREATE_ONE_TO_ONE_PTAS
                {
                    // we overloaded the existing assignment so we create new ones for each PTA to try and make it work
                    Set<string> resourceNames = new Set<string>();
                    for( Staging_Task__c stagingTask : (List<Staging_Task__c>)records )
                    {
                        if( !string.isBlank( stagingTask.Resource_Name__c ) )
                        {
                            resourceNames.add( stagingTask.Resource_Name__c );
                        }

                        if( stagingTask.Task_Rate__c == null )
                        {
                            stagingTask.Task_Rate__c = 0;
                        }
                    }

                    Map<string,Contact> contactMap = new Map<string,Contact>();
                    for( Contact con : 
                        [Select 
                            Id, 
                            Name,
                            pse__Resource_Role__c
                        from 
                            Contact 
                        where 
                            Name in :resourceNames and 
                            pse__Is_Resource__c = true and 
                            pse__Is_Resource_Active__c = true] )
                    {
                        contactMap.put( con.Name.toUpperCase(), con );
                    }

                    Map<string,string> assignmentKeyToRoleBudgetKey = new Map<string,string>();

                    Map<string,Staging_Task__c> keyToTask = new Map<string,Staging_Task__c>();
                    for( Staging_Task__c stagingTask : (List<Staging_Task__c>)records )
                    {
                        if( stagingTask.Project_Task__r.pse__Project__c != null &&
                            contactMap.containsKey( stagingTask.Resource_Name__c?.toUpperCase() ) &&
                            !string.isBlank( stagingTask.Task_Type__c ) &&
                            stagingTask.Task_Rate__c != null )
                        {
                            // making the key for PTA rather than assignment, this includes the task id so will be 1:1
                            string key = makeKeyForPTA( stagingTask, contactMap );
                            keyToTask.put( key, stagingTask );
                            assignmentKeyToRoleBudgetKey.put( key, makeKeyForRoleBudget( stagingTask, contactMap ) );
                        }
                    }

                    // search for role budgets
                    Map<string,Id> roleBudgetKeyToId = new Map<string,Id>();
                    Map<string,Id> roleBudgetKeyToReference = new Map<string,Id>();
                    for( Role_Budget__c budget : [Select Id, External_Id__c, Hours_Budget__c, Reference__c from Role_Budget__c where External_Id__c in :assignmentKeyToRoleBudgetKey.values()] )
                    {
                        roleBudgetKeyToId.put( budget.External_Id__c, budget.Id );
                        roleBudgetKeyToReference.put( budget.External_Id__c, budget.Reference__c );
                    }

                    // search for schedules
                    Map<string,pse__Schedule__c> schedules = new Map<string,pse__Schedule__c>();
                    for( pse__Schedule__c sched : [Select Id, pse_Assignment_External_ID_c__c from pse__Schedule__c where pse_Assignment_External_ID_c__c in :keyToTask.keySet()] )
                    {
                        schedules.put( sched.pse_Assignment_External_ID_c__c, sched );
                    }

                    List<pse__Schedule__c> newSchedules = new List<pse__Schedule__c>();
                    for( string key : keyToTask.keySet() )
                    {
                        if( !schedules.containsKey( key ) )
                        {
                            pse__Schedule__c sched = new pse__Schedule__c(
                                pse__Start_Date__c = keyToTask.get( key ).Project_Task__r.pse__Project__r.pse__Start_Date__c,
                                pse__End_Date__c = keyToTask.get( key ).Project_Task__r.pse__Project__r.pse__End_Date__c,
                                pse_Assignment_External_ID_c__c = key,
                                CurrencyIsoCode = keyToTask.get( key ).Project_Task__r.pse__Project__r.CurrencyIsoCode );
                            
                            newSchedules.add( sched );
                            schedules.put( sched.pse_Assignment_External_ID_c__c, sched );
                        }
                    }

                    insert newSchedules;

                    Set<string> existingAssignmentKeys = new Set<string>();
                    for( pse__Assignment__c ass : [Select Id, Assignment_External_ID__c from pse__Assignment__c where Assignment_External_ID__c in :keyToTask.keySet()] )
                    {
                        existingAssignmentKeys.add( ass.Assignment_External_ID__c );
                    }

                    List<pse__Assignment__c> newAssignments = new List<pse__Assignment__c>();
                    for( string key : keyToTask.keySet() )
                    {
                        if( !existingAssignmentKeys.contains( key ) )
                        {
                            string role = keyToTask.get( key ).Task_Role__c;
                            if( string.isBlank( role ) )
                            {
                                role = contactMap.get( keyToTask.get( key ).Resource_Name__c?.toUpperCase() )?.pse__Resource_Role__c;
                            }

                            Set<string> creditedTaskTypes = new Set<string>{ 'Credited', 'Productive' };

                            decimal billRate = keyToTask.get( key ).Task_Type__c == 'Billable' ? keyToTask.get( key ).Task_Rate__c : 0;
                            if( keyToTask.get( key ).Project_Task__r.pse__Project__r.pse__Billing_Type__c == 'Fixed Price' ||
                                keyToTask.get( key ).Project_Task__r.pse__Project__r.pse__Billing_Type__c == 'Subscription' )
                            {
                                billRate = 0;
                            }

                            pse__Assignment__c assignment = new pse__Assignment__c(
                                Name = ( keyToTask.get( key ).Project_Task__r.pse__Project__r.Name  + '-' + keyToTask.get( key ).Project_Task__r.Name ).left( 80 ),
                                pse__Status__c = 'Scheduled',
                                pse__Project__c = keyToTask.get( key ).Project_Task__r.pse__Project__c,
                                CurrencyIsoCode = keyToTask.get( key ).Project_Task__r.pse__Project__r.CurrencyIsoCode,
                                pse__Resource__c = contactMap.get( keyToTask.get( key ).Resource_Name__c?.toUpperCase() ).Id,
                                pse__Role__c = role,
                                pse__Schedule__c = schedules.get( key ).Id,
                                pse__Is_Billable__c = keyToTask.get( key ).Task_Type__c == 'Billable' ? true : false,
                                pse__Bill_Rate__c = billRate,
                                pse__Time_Credited__c = creditedTaskTypes.contains( keyToTask.get( key ).Task_Type__c ) ? true : false,
                                pse__Use_Resource_Default_Cost_Rate__c = true,
                                Assignment_External_ID__c = key,
                                Role_Budget__c = roleBudgetKeyToId.get( assignmentKeyToRoleBudgetKey.get( key ) )
                            );

                            newAssignments.add( assignment );
                            existingAssignmentKeys.add( key );
                        }
                    }

                    List<Database.SaveResult> results = database.insert( newAssignments, false );
                    Set<string> failedKeys = new Set<string>();

                    List<pse__Assignment__c> assignmentsToUpdate = new List<pse__Assignment__c>();

                    for( Integer i = 0; i < results.size(); i++ )
                    {
                        Database.SaveResult result = results[i];
                        pse__Assignment__c assignment = newAssignments[i];

                        if( !result.isSuccess() )
                        {
                            for( Staging_Task__c stagingTask : (List<Staging_Task__c>)records )
                            {
                                string key = makeKeyForAssignment( stagingTask, contactMap );
                                if( key == assignment.Assignment_External_ID__c )
                                {
                                    failedKeys.add( key );
                                    errorMessages.add( stagingTask.Id + ': ' + result.getErrors()[0].getMessage() );
                                    break;
                                }
                            }
                        }
                        else
                        {
                            assignmentsToUpdate.add( assignment );
                        }
                    }

                    if( assignmentsToUpdate.size() > 0 )
                    {
                        update assignmentsToUpdate;
                    }

                    // now onto the PTA generation
                    Map<string,Id> assignmentKeyToId = new Map<string,Id>();
                    for( pse__Assignment__c assignment : [Select Id, Assignment_External_ID__c from pse__Assignment__c where Assignment_External_ID__c in :keyToTask.keySet()] )
                    {
                        assignmentKeyToId.put( assignment.Assignment_External_ID__c, assignment.Id );
                    }

                    // check for existing PTAs
                    Set<string> existingPTAKeys = new Set<string>();
                    for( pse__Project_Task_Assignment__c pta : [Select Id, External_Id__c from pse__Project_Task_Assignment__c where External_Id__c in :keyToTask.keySet()] )
                    {
                        existingPTAKeys.add( pta.External_Id__c );
                    }

                    Map<Id,pse__Project_Task_Assignment__c> stagingTaskToPTA = new Map<Id,pse__Project_Task_Assignment__c>();

                    Map<Id,pse__Project_Task__c> projectTasksToUpdate = new Map<Id,pse__Project_Task__c>();
                    List<pse__Project_Task_Assignment__c> newPTAs = new List<pse__Project_Task_Assignment__c>();
                    for( string key : keyToTask.keySet() )
                    {
                        if( !existingPTAKeys.contains( key ) )
                        {
                            string role = keyToTask.get( key ).Task_Role__c;
                            if( string.isBlank( role ) )
                            {
                                role = contactMap.get( keyToTask.get( key ).Resource_Name__c?.toUpperCase() )?.pse__Resource_Role__c;
                            }

                            pse__Project_Task_Assignment__c pta = new pse__Project_Task_Assignment__c(
                                pse__Project_Task__c = keyToTask.get( key ).Project_Task__c,
                                External_Id__c = key,
                                pse__Estimated_Hours__c = keyToTask.get( key ).Remaining_Effort__c,
                                pse__Resource__c = contactMap.get( keyToTask.get( key ).Resource_Name__c?.toUpperCase() ).Id,
                                Project__c = keyToTask.get( key ).Project_Task__r.pse__Project__c,
                                pse__Assignment__c = assignmentKeyToId.get( key ),
                                CurrencyIsoCode = keyToTask.get( key ).Project_Task__r.pse__Project__r.CurrencyIsoCode,
                                pse__Resource_Role__c = role,
                                Role_Budget__c = roleBudgetKeyToId.get( assignmentKeyToRoleBudgetKey.get( key ) )
                            );

                            pse__Project_Task__c projectTask = keyToTask.get( key ).Project_Task__r;
                            projectTask.Role_Budget_Link__c = pta.Role_Budget__c;
                            projectTask.Role_Budget__c = roleBudgetKeyToReference.get( assignmentKeyToRoleBudgetKey.get( key ) );
                            projectTasksToUpdate.put( projectTask.Id, projectTask );

                            newPTAs.add( pta );
                            existingPTAKeys.add( key );
                            stagingTaskToPTA.put( keyToTask.get( key ).Id, pta );
                        }
                    }

                    results = database.insert( newPTAs, false );
                    Set<string> successfullySavedKeys = new Set<string>();

                    for( Integer i = 0; i < results.size(); i++ )
                    {
                        Database.SaveResult result = results[i];
                        pse__Project_Task_Assignment__c pta = newPTAs[i];

                        if( !result.isSuccess() )
                        {
                            for( Staging_Task__c stagingTask : (List<Staging_Task__c>)records )
                            {
                                string key = makeKeyForPTA( stagingTask, contactMap );
                                if( key == pta.External_Id__c )
                                {
                                    errorMessages.add( stagingTask.Id + ': ' + result.getErrors()[0].getMessage() );
                                    break;
                                }
                            }
                        }
                        else
                        {
                            successfullySavedKeys.add( pta.External_Id__c );
                        }
                    }

                    for( Staging_Task__c stagingTask : (List<Staging_Task__c>)records )
                    {
                        string key = makeKeyForPTA( stagingTask, contactMap );
                        if( successfullySavedKeys.contains( key ) && !failedKeys.contains( key ) )
                        {
                            stagingTask.Import_Status__c = 'Complete';
                            if( stagingTaskToPTA.containsKey( stagingTask.Id ) )
                            {
                                stagingTask.Project_Task_Assignment__c = stagingTaskToPTA.get( stagingTask.Id ).Id;
                            }
                        }
                        else
                        {
                            // don't update project tasks to budgets if the staging task failed
                            projectTasksToUpdate.remove( stagingTask.Project_Task__c );
                        }
                    }
                    update records;
                    update projectTasksToUpdate.values();
                }
                when UPDATE_PROJECT_PLANNED_HOURS
                {
                    Set<Id> projectIds = new Set<Id>();
                    for( Staging_Project__c stagingProject : (List<Staging_Project__c>)records )
                    {
                        projectIds.add( stagingProject.Project__c );
                    }

                    List<pse__Proj__c> updatedProjects = new List<pse__Proj__c>();
                    for( pse__Proj__c project : 
                        [Select 
                            Id, 
                            pse__Planned_Hours__c, 
                            (Select Id, Hours_Budget__c from Role_Budgets__r where Hours_Budget__c > 0)
                        from 
                            pse__Proj__c 
                        where 
                            Id in :projectIds] )
                    {
                        decimal plannedHours = 0;
                        for( Role_Budget__c rb : project.Role_Budgets__r )
                        {
                            plannedHours += rb.Hours_Budget__c;
                        }

                        updatedProjects.add( new pse__Proj__c( Id = project.Id, pse__Planned_Hours__c = plannedHours ) );
                    }

                    update updatedProjects;
                }
                when CREATE_PROJECT_BUDGETS
                {
                    Set<Id> projectIds = new Set<Id>();
                    for( Staging_Project__c stagingProject : (List<Staging_Project__c>)records )
                    {
                        projectIds.add( stagingProject.Project__c );
                        stagingProject.Import_Status__c = 'Complete';
                    }

                    List<pse__Budget__c> newBudgets = new List<pse__Budget__c>();
                    for( pse__Proj__c project : 
                        [Select 
                            Id, 
                            Name, 
                            CurrencyIsoCode,
                            (Select 
                                Id, 
                                pse__Projected_Revenue__c 
                            from 
                                pse__Assignments__r 
                            where 
                                Assignment_External_ID__c != '' and
                                pse__Is_Billable__c = true) 
                        from 
                            pse__Proj__c 
                        where 
                            Id in :projectIds] )
                    {
                        decimal amount = 0;
                        for( pse__Assignment__c assignment : project.pse__Assignments__r )
                        {
                            if( assignment.pse__Projected_Revenue__c != null )
                            {
                                amount += assignment.pse__Projected_Revenue__c;
                            }
                        }

                        newBudgets.add(
                            new pse__Budget__c( 
                                Name = ( project.Name + ' - Budget' ).left( 80 ), 
                                CurrencyIsoCode = project.CurrencyIsoCode,
                                pse__Project__c = project.Id,
                                pse__Type__c = 'Customer Purchase Order',
                                pse__Amount__c = amount,
                                pse__Effective_Date__c = system.today(),
                                pse__Status__c = 'Approved',
                                pse__Approved__c = true,
                                pse__Include_In_Financials__c = true )
                        );
                    }

                    insert newBudgets;
                    update records;
                }
            }
        }
        catch( Exception ex )
        {
            if( records.size() > 0 )
            {
                errorMessages.add( records[0].Id + ' - ' + ex.getMessage() + ex.getStackTraceString() );
            }
            else
            {
                errorMessages.add( ex.getMessage() );
            }

            if( Test.isRunningTest() )
            {
                throw ex;
            }
        }
    }

    public void finish( Database.BatchableContext BC ) 
    {
        // switch this back on for now
        if( this.calendarSyncWasEnabled )
        {
            setSyncAssignmentWithExternalCalendar( true );
        }

        Process nextStep = GetNext( this.currentProcess );

        // quite if we're complete, testing or we failed on the project first pass (since nothing else will work)
        if( nextStep == Process.COMPLETE || Test.isRunningTest() || 
            ( this.currentProcess == Process.CREATE_PROJECT_FIRST_PASS && this.errorMessages.size() > 0 ) )
        {
            // we're all done, finish and report any errors
            if( this.errorMessages.size() > 0 )
            {
                AsyncApexJob batchJob = [Select Id, CreatedBy.Email from AsyncApexJob where Id =:BC.getJobId()];
                sendEmail( batchJob.CreatedBy.Email );
            }
        }
        else
        {
            DataImportBatch batch = new DataImportBatch();
            batch.currentProcess = nextStep;
            batch.batchSize = this.batchSize;
            batch.errorMessages.addAll( this.errorMessages );

            integer batchSize = this.batchSize;
            if( nextStep == Process.CREATE_PROJECT_TASK_ASSIGNMENTS || 
                nextStep == Process.CREATE_ONE_TO_ONE_PTAS ||
                nextStep == Process.UPDATE_PROJECT_PLANNED_HOURS )
            {
                // due to internal error handling we can only do these 1 at a time
                batchSize = 1;
            }

            Database.executeBatch( batch, batchSize );
        }
    }

    public void sendEmail( string to ) 
    {
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setToAddresses( new String[] {to} );

        string body = '<p>The data import process completed with errors on step ' + string.valueOf( this.currentProcess ) + '.</p>';

        mail.setSubject( 'The data import process has completed with errors!' );
        body += '<p>The following errors occurred:</p><ul>';
        for( String s : errorMessages ) 
        {
            body += '<li>' + s + '</li>';
        }
        body += '</ul>';

        insert new Data_Import_Results__c(
            Errors__c = body
        );

        /*body += '<p>User: ' + UserInfo.getUserName() + ', Org Id: ' + UserInfo.getOrganizationId() + '</p>';

		body += '<p>Certinia</p>';

		mail.setHtmlBody( body );

        try 
        {
		    Messaging.sendEmail( new Messaging.SingleEmailMessage[] { mail } );
        }
        catch( System.EmailException sex ) 
        {
        }*/
    }

    public static string makeKeyForAssignment( Staging_Task__c stagingTask, Map<string,Contact> contactMap )
    {
        if( OneToOnePTAToAssignments )
        {
            return makeKeyForPTA( stagingTask, contactMap );
        }
        else
        {
            string role = stagingTask.Task_Role__c;
            if( string.isBlank( role ) )
            {
                role = contactMap.get( stagingTask.Resource_Name__c?.toUpperCase() )?.pse__Resource_Role__c;
            }

            return
                stagingTask.Project_Task__r.pse__Project__c + '|' +
                contactMap.get( stagingTask.Resource_Name__c?.toUpperCase() )?.Id + '|' +
                stagingTask.Task_Type__c + '|' +
                stagingTask.Task_Rate__c + '|' + 
                role;
        }
    }

    public static string makeKeyForPTA( Staging_Task__c stagingTask, Map<string,Contact> contactMap )
    {
        string role = stagingTask.Task_Role__c;
        if( string.isBlank( role ) )
        {
            role = contactMap.get( stagingTask.Resource_Name__c?.toUpperCase() )?.pse__Resource_Role__c;
        }

        return
            stagingTask.Project_Task__r.pse__Project__c + '|' +
            contactMap.get( stagingTask.Resource_Name__c?.toUpperCase() )?.Id + '|' +
            stagingTask.Task_Type__c + '|' +
            stagingTask.Task_Rate__c + '|' +
            stagingTask.Project_Task__c + '|' + 
            role;
    }

    public static string makeKeyForRoleBudget( Staging_Task__c stagingTask, Map<string,Contact> contactMap )
    {
        string role = stagingTask.Task_Role__c;
        if( string.isBlank( role ) )
        {
            role = contactMap.get( stagingTask.Resource_Name__c?.toUpperCase() )?.pse__Resource_Role__c;
        }

        return
            stagingTask.Project_Task__r.pse__Project__c + '|' +
            stagingTask.Task_Type__c + '|' +
            stagingTask.Task_Rate__c + '|' +
            role;
    }

    public static string getProjectType( string projectType )
    {
        Map<string,string> projectTypeMap = new Map<string,string>
        {
            'NSS' => 'NSS',
            'IBS' => 'IBS',
            'Packed Solutions' => 'Packaged Solutions',
            'Managed Services' => 'PS Subscription',
            'Partner Support' => 'Internal',
            'Business Development' => 'Internal',
            'Internal' => 'Internal'
        };

        if( projectTypeMap.containsKey( projectType ) )
        {
            return projectTypeMap.get( projectType );
        }

        return projectType;
    }

    public static string getProjectSubTypes( string projectSubTypes )
    {
        Map<string,string> projectSubTypeMap = new Map<string,string>
        {
            'Customization' => 'PS Subscription - Customisation Maintenance',
            'Upgrade' => 'IBS - Upgrade',
            'Flex' => 'PS Subscription - Forterro Service Points',
            'IBS - Jeeves Enhancement' => 'IBS - Enhancement',
            'IBS - Upgrade Jeeves' => 'IBS - Upgrade',
            'IBS - Update' => 'IBS - Upgrade',
            'IBS - Customization & Consulting' => 'IBS - Ongoing Work',
            'IBS - Consulting' => 'IBS - Enhancement',
            'IBS - Technical' => 'PS Subscription - Managed Services',
            'IBS - Sub. konv.' => 'IBS - Upgrade',
            'IBS - Cloud. konv.' => 'IBS - Upgrade',
            'IBS - Cloud konv.' => 'IBS - Upgrade',
            'IBS - Upgrade Cloud' => 'IBS - Upgrade',
            'IBS - FSP Contract' => 'Forterro Service Points'
        };

        if( projectSubTypeMap.containsKey( projectSubTypes ) )
        {
            return projectSubTypeMap.get( projectSubTypes );
        }

        return projectSubTypes;
    }

    public static string getProjectStage( string stagingState )
    {
        Map<string,string> stageMap = new Map<string,string>
        {
            'Requested' => 'Requested',
            'Draft' => 'Draft',
            'Active' => 'In Progress',
            'On Hold' => 'On Hold',
            'Canceled' => 'Canceled',
            'Completed' => 'Complete',
            'Cancelled' => 'Cancelled'
        };
        
        return stageMap.get( stagingState );
    }

    public static string getTaskState( string stagingState )
    {
        Map<string,string> stageMap = new Map<string,string>
        {
            'Requested' => 'Draft',
            'Draft' => 'Draft',
            'Active' => 'Started',
            'On Hold' => 'Blocked',
            'Complete' => 'Complete',
            'Canceled' => 'Deferred',
            'Cancelled' => 'Deferred',
            'Completed' => 'Complete'
        };
        
        return stageMap.get( stagingState );
    }

    public static boolean setSyncAssignmentWithExternalCalendar( boolean enabled )
    {
        // we switch this off for every job as it causes issues with assignment generation
        List<pse__External_Calendar_Events_Settings__c> settings = 
            [select 
                Id, 
                pse__Sync_Assignment_With_External_Calendar__c 
            from 
                pse__External_Calendar_Events_Settings__c];

        boolean wasEnabled = false;

        for( pse__External_Calendar_Events_Settings__c setting : settings )
        {
            if( setting.pse__Sync_Assignment_With_External_Calendar__c )
            {
                wasEnabled = true;
            }
            setting.pse__Sync_Assignment_With_External_Calendar__c = enabled;
        }

        update settings;
        return wasEnabled;
    }
}