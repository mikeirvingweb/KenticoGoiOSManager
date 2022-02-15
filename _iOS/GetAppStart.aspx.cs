using System;
using System.Web;
using System.Web.Security;
using System.Data;
using CMS.GlobalHelper;
using CMS.EventLog;
using CMS.SiteProvider;
using CMS.SettingsProvider;
using CMS.CMSHelper;

public partial class KenticoGo_GetAppStart : System.Web.UI.Page
{
    // Get App Start Time for Kentico 4, Kentico 5
	//
	// Kentico Go - the iOS Kentico Management App - © 2011 Mike Irving
    // See: https://www.mike-irving.co.uk/KenticoGo
    //
	
	protected void Page_Load(object sender, EventArgs e)
    {
		Response.ContentType = "text/html";
		Response.Write( ((DateTime.Now - Global.ApplicationStart).ToString().Split('.'))[0]);
    }
}
