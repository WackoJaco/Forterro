@RestResource(urlMapping='/projectsapi/projecttest/resetprojects/*')
global with sharing class ProjectTestAPI 
{
    @HttpPost
    global static void HandlePost( string BUCode )
    {
        List<pse__Proj__c> projects = [Select Id, Sync_Status__c, SyncDate__c, ErrorMessage__c from pse__Proj__c where
            pse__Region__r.BU_Code__c = :BUCode and Sync_Status__c != 'New' and pse__Is_Billable__c = true];

        for( pse__Proj__c project : projects )
        {
            project.Sync_Status__c = 'New';
            project.SyncDate__c = null;
            project.ErrorMessage__c = '';
        }

        update projects;

        RestAPIHelper.SetRestReturn( projects.size(), true );
    }
}