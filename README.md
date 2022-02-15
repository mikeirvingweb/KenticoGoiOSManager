# KenticoGo
Kentico Go - the iOS Kentico Management App - © 2011 Mike Irving
See: https://www.mike-irving.co.uk/KenticoGo

iTunes App URL: http://itunes.apple.com/gb/app/kentico-go/id463485294?ls=1&mt=8 (no longer available)

--

Instructions:

To install, simply place the "/_iOS" folder from the ZIP file into the root of your Kentico installation.

Once installed, you should be able to log in via Kentico Go.

Please Note: Only users with "Administrator" permissions will be able to log in.

--

Configurable Variables:

There are two simple variables that can be set in the KenticoGo.ashx file, to control access.
    
// Enforce SSL - bool
// set to false allow non-SSL connections (at your own risk)
//
private static bool enforceSSL = true;

// Allowed Users - comma separated list
// set to "ANY" to allow all users,
// or a comma separated list of users you want to allow in i.e. "administrator,mike"
//
private static string allowedUsers = "ANY";
