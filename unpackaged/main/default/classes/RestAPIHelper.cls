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
}