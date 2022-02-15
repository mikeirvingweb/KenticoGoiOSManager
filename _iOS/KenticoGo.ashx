<%@ WebHandler Language="C#" Class="KenticoGo" Debug="true" %>
using System;
using System.Web;
using System.Web.Security;
using System.Data;
using System.IO;
using CMS.GlobalHelper;
using CMS.EventLog;
using CMS.SiteProvider;
using CMS.SettingsProvider;
using CMS.CMSHelper;

public class KenticoGo : IHttpHandler {
    // Kentico Go - the iOS Kentico Management App - © 2011 Mike Irving
    // See: https://www.mike-irving.co.uk/KenticoGo
    //
	// Version 1.03
    
    // Configurable Variables
    //
    
    // Enforce SSL - bool
    // set to false allow non-SSL connections (at your own risk)
    //
    private static bool enforceSSL = true;

    // Allowed Users - comma separated list
    // set to "ANY" to allow all users,
    // or a comma separated list of users you want to allow in i.e. "administrator,mike"
    //
    private static string allowedUsers = "ANY";
    
    //
    // End Configurable Variables
    
    private string  stringRequestType;
    private string  stringUsername;
    private string  stringPassword;
    private string  stringSiteID;
    private int     intSiteID;
    private string  stringMaxRows;
    private int     intMaxRows;

    public void ProcessRequest (HttpContext context) {
        int kenticoVersion = Convert.ToInt16(CMSContext.FullSystemSuffixVersion.ToString().Split('.')[0]);
		
		stringRequestType   = ValidationHelper.GetString(context.Request.Form["requestType"], "");
        stringRequestType   = stringRequestType.ToUpper();
        stringUsername      = ValidationHelper.GetString(context.Request.Form["Username"], "");
        stringPassword      = ValidationHelper.GetString(context.Request.Form["Password"], "");
        stringSiteID        = ValidationHelper.GetString(context.Request.Form["siteID"], "");
        stringMaxRows       = ValidationHelper.GetString(context.Request.Form["maxRows"], "");

        string output = "";

        if (stringSiteID == "")
        {
            intSiteID = -1;
        }
        else
        {
            try
            {
                intSiteID = Convert.ToInt32(stringSiteID);
            }
            catch (Exception e)
            {
                intSiteID = -1;
            }
        }

        if (stringMaxRows == "")
        {
            intMaxRows = 5;
        }
        else
        {
            try
            {
                intMaxRows = Convert.ToInt32(stringMaxRows);
            }
            catch (Exception e)
            {
                intMaxRows = 5;
            }
        }
        
        if (stringRequestType == "OVERVIEW")
        {
            output = "<?xml version='1.0' encoding='ISO-8859-1'?>";
	        output += "<overview>";
            
            if (CheckSSL(context))
            {
                output += "<SSLOK>TRUE</SSLOK>";
                
                if (CheckAuthentication(stringUsername, stringPassword))
                {
                    output += "<authenticationOK>TRUE</authenticationOK>";
                    output += "<overviewOK>TRUE</overviewOK>";
                    output += "<machineName>" + HTTPHelper.MachineName +"</machineName>";
                    output += "<aspnetAccount>" + System.Security.Principal.WindowsIdentity.GetCurrent().Name + "</aspnetAccount>";
                    output += "<memory>" + DataHelper.GetSizeString(GC.GetTotalMemory(false)) + "</memory>";

					string startTime = "Unknown";
					
					StringWriter writer = new StringWriter();
					
					try
					{
						if(kenticoVersion < 6)
							context.Server.Execute("GetAppStart.aspx", writer);
						else
							context.Server.Execute("GetAppStart6.aspx", writer);
							
						startTime = writer.ToString();
					}
					catch(Exception eExecute)
					{
						startTime = "Unknown";
					}

					output += "<timeSinceRestart>" + startTime + "</timeSinceRestart>";
				
                    output += "<expiredCacheItems>" + CacheHelper.Expired.ToString() + "</expiredCacheItems>";

                    output += "<sites>";

                    SiteInfo siteInfo = new SiteInfo();
                    DataSet sites = SiteInfoProvider.GetAllSites();
                    if (sites.Tables[0].Rows.Count > 0)
                    {
                        foreach (DataRow site in sites.Tables[0].Rows)
                        {
                            siteInfo = SiteInfoProvider.GetSiteInfo(Convert.ToInt32(site["SiteID"].ToString()));
                            if (siteInfo != null)
                                output += "<site id=\"" + siteInfo.SiteID.ToString() + "\"" +
                                          " domain=\"" + siteInfo.DomainName + "\"" +
                                          " name=\"" + siteInfo.SiteName + "\"" +
                                          " status=\"" + siteInfo.Status.ToString() + "\" />";
                        }
                    }
                    
                    output += "</sites>";
                }
                else
                {
                    output += "<authenticationOK>FALSE</authenticationOK>";
                    output += "<overviewOK>FALSE</overviewOK>";
                }
            }
            else
            {
                output += "<SSLOK>FALSE</SSLOK>";
            }
            
            output += "</overview>";

        }
        else if (stringRequestType == "EMPTYCACHE")
        {
            output = "<?xml version='1.0' encoding='ISO-8859-1'?>";
	        output += "<emptycache>";

            if (CheckSSL(context))
            {
                output += "<SSLOK>TRUE</SSLOK>";

                if (CheckAuthentication(stringUsername, stringPassword))
                {
                    output += "<authenticationOK>TRUE</authenticationOK>";

                    try
                    {
                        CacheHelper.ClearCache(null, true);
                        Functions.ClearHashtables();
                        GC.Collect();
                        GC.WaitForPendingFinalizers();

                        output += "<emptyCacheOK>TRUE</emptyCacheOK>";
                    }
                    catch (Exception e)
                    {
                        output += "<emptyCacheOK>FALSE</emptyCacheOK>";
                    }
                }
                else
                {
                    output += "<authenticationOK>FALSE</authenticationOK>";
                }
            }
            else
            {
                output += "<SSLOK>FALSE</SSLOK>";
            }            
                    
            output += "</emptycache>";
        }
        else if (stringRequestType == "FREEMEMORY")
        {
            output = "<?xml version='1.0' encoding='ISO-8859-1'?>";
            output += "<freememory>";

            if (CheckSSL(context))
            {
                output += "<SSLOK>TRUE</SSLOK>";

                if (CheckAuthentication(stringUsername, stringPassword))
                {
                    output += "<authenticationOK>TRUE</authenticationOK>";

                    try
                    {
                        GC.Collect();
                        GC.WaitForPendingFinalizers();

                        output += "<freeMemoryOK>TRUE</freeMemoryOK>";
                    }
                    catch (Exception e)
                    {
                        output += "<freeMemoryOK>FALSE</freeMemoryOK>";
                    }
                }
                else
                {
                    output += "<authenticationOK>FALSE</authenticationOK>";
                }
            }
            else
            {
                output += "<SSLOK>FALSE</SSLOK>";
            }

            output += "</freememory>";
        }
        else if (stringRequestType == "RESTART")
        {
            output = "<?xml version='1.0' encoding='ISO-8859-1'?>";
            output += "<restart>";

            if (CheckSSL(context))
            {
                output += "<SSLOK>TRUE</SSLOK>";

                if (CheckAuthentication(stringUsername, stringPassword))
                {
                    output += "<authenticationOK>TRUE</authenticationOK>";

                    try
                    {
                        HttpRuntime.UnloadAppDomain();

                        output += "<restartOK>TRUE</restartOK>";
                    }
                    catch (Exception e)
                    {
                        output += "<restartOK>FALSE</restartOK>";
                    }
                }
                else
                {
                    output += "<authenticationOK>FALSE</authenticationOK>";
                }
            }
            else
            {
                output += "<SSLOK>FALSE</SSLOK>";
            }

            output += "</restart>";
        }
        else if (stringRequestType == "START")
        {
            output = "<?xml version='1.0' encoding='ISO-8859-1'?>";
            output += "<start>";

            if (CheckSSL(context))
            {
                output += "<SSLOK>TRUE</SSLOK>";

                if (CheckAuthentication(stringUsername, stringPassword))
                {
                    output += "<authenticationOK>TRUE</authenticationOK>";

                    try
                    {
                        SiteInfo siteInfo = SiteInfoProvider.GetSiteInfo(intSiteID);
                        SiteInfoProvider.RunSite(siteInfo.SiteName);

                        output += "<startOK>TRUE</startOK>";
                    }
                    catch (Exception e)
                    {
                        output += "<startOK>FALSE</startOK>";
                    }
                }
                else
                {
                    output += "<authenticationOK>FALSE</authenticationOK>";
                }
            }
            else
            {
                output += "<SSLOK>FALSE</SSLOK>";
            }

            output += "</start>";
        }
        else if (stringRequestType == "STOP")
        {
            output = "<?xml version='1.0' encoding='ISO-8859-1'?>";
            output += "<stop>";

            if (CheckSSL(context))
            {
                output += "<SSLOK>TRUE</SSLOK>";

                if (CheckAuthentication(stringUsername, stringPassword))
                {
                    output += "<authenticationOK>TRUE</authenticationOK>";

                    try
                    {
                        SiteInfo siteInfo = SiteInfoProvider.GetSiteInfo(intSiteID);
                        SiteInfoProvider.StopSite(siteInfo.SiteName);
                        SessionManager.Clear(siteInfo.SiteName);

                        output += "<stopOK>TRUE</stopOK>";
                    }
                    catch (Exception e)
                    {
                        output += "<stopOK>FALSE</stopOK>";
                    }
                }
                else
                {
                    output += "<authenticationOK>FALSE</authenticationOK>";
                }
            }
            else
            {
                output += "<SSLOK>FALSE</SSLOK>";
            }
            output += "</stop>";
        }
        else if (stringRequestType == "LOGS")
        {
            output = "<?xml version='1.0' encoding='ISO-8859-1'?>";
            output += "<logs>";

            if (CheckSSL(context))
            {
                output += "<SSLOK>TRUE</SSLOK>";

                if (CheckAuthentication(stringUsername, stringPassword))
                {
                    output += "<authenticationOK>TRUE</authenticationOK>";

                    try
                    {
                        output += "<logsOK>TRUE</logsOK>";
                        output += "<logs>";

                        EventLogProvider eventLogProvider = new EventLogProvider();
                        DataSet logs = eventLogProvider.GetAllEvents("EventCode <> 'AUTHENTICATIONSUCC'", "EventTime DESC");
                        if (logs.Tables[0].Rows.Count > 0)
                        {
                            int count = 0;
                            foreach (DataRow log in logs.Tables[0].Rows)
                            {
                                if (count >= intMaxRows)
                                    break;

                                output += "<log>" +
                                            "<eventID>" + log["eventID"].ToString() + "</eventID>" +
                                            "<time>" + log["EventTime"].ToString() + "</time>" +
                                            "<code>" + log["EventCode"].ToString() + "</code>" +
                                            "<source>" + log["Source"].ToString() + "</source>" +
                                            "<description><![CDATA[" + log["EventDescription"].ToString() + "]]></description>" +
                                          "</log>";

                                count++;
                            }
                        }
                        
                        output += "</logs>";
                    }
                    catch (Exception e)
                    {
                        output += "<logsOK>FALSE</logsOK>";
                    }
                }
                else
                {
                    output += "<authenticationOK>FALSE</authenticationOK>";
                }
            }
            else
            {
                output += "<SSLOK>FALSE</SSLOK>";
            }
            output += "</logs>";
        }        
            


        context.Response.ContentType = "text/xml";
        context.Response.Write(output);
    }
 
    public bool IsReusable {
        get {
            return false;
        }
    }

    private bool CheckSSL(HttpContext context)
    {
        if (!(enforceSSL))
            return true;
        
        try
        {
            return context.Request.IsSecureConnection;
        }
        catch (Exception)
        {
            return false;
        }
    }

    public bool CheckAuthentication(string stringUsername, string stringPassword)
    {
        bool allowedIn = false;

        if (allowedUsers == "ANY")
        {
            allowedIn = true;
        }
        else
        {
            string[] allowedUsersSplit = allowedUsers.Split(',');

            foreach (string allowedUser in allowedUsersSplit)
            {
                if (allowedUser.Trim().ToUpper() == stringUsername.Trim().ToUpper())
                {
                    allowedIn = true;
                    break;
                }
            }            
        }
        
        if(!(allowedIn))
            return false;
        
        try
        {
            CMS.SiteProvider.UserInfo userInfo = CMS.SiteProvider.UserInfoProvider.GetUserInfo(stringUsername);

            if (userInfo != null)
                if (Membership.ValidateUser(stringUsername, stringPassword))
                    if (userInfo.IsGlobalAdministrator)
                        return true;
        }
        catch (Exception)
        {
            return false;
        }

        return false;
    }

}