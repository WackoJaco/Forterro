public class GetExtProjectForRegion 
{
    public class InputParameters
    {
        @InvocableVariable(label='Region ID' required=true)
        public Id regionId;
    }

    public class OutputParameters
    {
        @InvocableVariable(label='A returned list of project IDs if found')
        public List<Id> projectIds = new List<Id>();
    }

    @InvocableMethod(callout=true label='Get EXT project for region')
    public static List<OutputParameters> getProjectForRegion( List<InputParameters> inputs )
    {
        List<OutputParameters> outputs = new List<OutputParameters>();

        // we want regions and all their parents, not interested in children
        Set<Id> regionIds = new Set<Id>();
        for( InputParameters input : inputs )
        {
            regionIds.add( input.regionId );
        }

        Map<Id,pse__Region__c> regions = new Map<Id,pse__Region__c>();

        while( regionIds.size() > 0 )
        {
            Set<Id> nextRegionIds = new Set<Id>();
            for( pse__Region__c region :
                [Select 
                    Id, 
                    pse__Parent_Region__c 
                from 
                    pse__Region__c 
                where 
                    Id in :regionIds] )
            {
                regions.put( region.Id, region );
                if( region.pse__Parent_Region__c != null )
                {
                    nextRegionIds.add( region.pse__Parent_Region__c );
                }
            }

            regionIds = nextRegionIds;
        }

        Map<Id,Set<Id>> regionIdToProjectIds = new Map<Id,Set<Id>>();

        for( pse__Proj__c project : 
            [Select 
                Id,
                pse__Region__c 
            from 
                pse__Proj__c 
            where 
                Name like '%(EXT)%' and 
                pse__Is_Active__c = true and 
                pse__Is_Template__c = false and 
                Project_Sub_Types__c = 'IBS - Enhancement' and
                pse__Stage__c = 'In Progress' and
                pse__Region__c in :regions.keySet()] )
        {
            if( !regionIdToProjectIds.containsKey( project.pse__Region__c ) )
            {
                regionIdToProjectIds.put( project.pse__Region__c, new Set<Id>() );
            }
            regionIdToProjectIds.get( project.pse__Region__c ).add( project.Id );
        }
        
        for( InputParameters input : inputs )
        {
            OutputParameters output = new OutputParameters();

            Id regionId = input.regionId;
            while( regions.containsKey( regionId ) )
            {
                pse__Region__c region = regions.get( regionId );
                if( regionIdToProjectIds.containsKey( region.Id ) )
                {
                    output.projectIds = new List<Id>( regionIdToProjectIds.get( region.Id ) );
                    break;
                }

                regionId = region.pse__Parent_Region__c;
            }

            outputs.add( output );
        }

        return outputs;
    }
}