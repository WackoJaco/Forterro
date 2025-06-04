global class RestAPIHelper 
{
    public class SalesforceError 
    {
        public String errorCode;
        public List<String> messages;
        public SalesforceError( String errorCode, List<string> messages )
        {
            this.errorCode = errorCode;
            this.messages = messages;
        }
    }

    public static void SetRestError( Integer statusCode, string returnCode, List<string> messages )
    {
        RestContext.response.statusCode = statusCode;
        SalesforceError[] errs = new SalesforceError[]
        { 
            new SalesforceError(returnCode, messages)
        };
        RestContext.response.addHeader( 'Content-Type', 'application/json' );
        RestContext.response.responseBody = Blob.valueOf( JSON.serialize( errs ) );
    }

    public static void SetRestReturn( object obj )
    {
        SetRestReturn( obj, false );
    }

    public static void SetRestReturn( object obj, boolean suppressNulls )
    {
        RestContext.response.addHeader( 'Content-Type', 'application/json' );
        RestContext.response.responseBody = Blob.valueOf( JSON.serialize( obj, suppressNulls ) );
    }

    public static decimal zeroIfNull( decimal d )
    {
        return d == null ? 0.0 : d;
    }

    public static string sanitiseProjectId( string projectId )
    {
        // project id may be ABC|P-01234 - we want to return P-01234
        if( string.isBlank( projectId ) )
        {
            return projectId;
        }

        string[] parts = projectId.split( '\\|' );
        return parts[parts.size() - 1];
    }
}