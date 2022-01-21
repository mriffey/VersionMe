# VersionMe
Easy build time versioning for Clarion appgen / hand coded apps.

VersionMe gives your clarion app the ability to version your app with build numbers. Each time you compile, the build number is incremented for you. 

This build number ends up in your app so you can see it via the Windows Explorer details tab. In addition, you can pass this data to SetupBuilder so it can use automatic version checking. 


**SETTING UP VersionMe** 

1) Add the Pre-build event command

In your Clarion project, add this line to the "Pre-build event command line":
c:\projects\VersionMe\VersionMe.exe PROJECT=$(OutputName) BINARYTYPE=$(OutputType) APPFOLDER=$(SolutionDir) 

The path/filename for VersionMe.exe can be different - but it must resolve successfully at compile time. 

Example:

![VersionME Clarion project properties](https://github.com/mriffey/VersionMe/blob/master/VersionMeProjectDetails.jpg?raw=true)


2) Create the XML file

Each app requires a NAME_VersionME.XML where NAME is the name of your .app or .cwproj. At various points in processing, this name is pulled from $(OutputName) (see the pre-event command line details above). 

Once you fill in the XML, the build details (specifically BUILDNUMBwill be maintained automatically. You, of course, are responsible for things like PRODUCTNAME, COMPANYNAME, etc. 

```
<?xml version="1.0" encoding="ISO-8859-1"?>
<VersionMeConfig>
    <VERSIONTYPE>SLN</VERSIONTYPE>
    <PRODUCTNAME>My app</PRODUCTNAME>
    <COMPANYNAME>MyCompany, Inc.</COMPANYNAME>
    <COPYRIGHTSTARTYEAR>2007</COPYRIGHTSTARTYEAR>
    <FILEVERSIONNUMBERMAJ>YYYY</FILEVERSIONNUMBERMAJ>
    <FILEVERSIONNUMBERMIN>MM</FILEVERSIONNUMBERMIN>
    <FILEVERSIONNUMBERSUB>DD</FILEVERSIONNUMBERSUB>
    <FILEVERSIONNUMBERREV/>
    <PRODUCTVERSIONNUMBERMAJ/>
    <PRODUCTVERSIONNUMBERMIN/>
    <PRODUCTVERSIONNUMBERSUB/>
    <PRODUCTVERSIONNUMBERREV/>
    <BUILDNUMBER>2733</BUILDNUMBER>
    <VERSIONTEXT>My appname</VERSIONTEXT>
    <VERSIONTEXTSHORT>ShortAppname</VERSIONTEXTSHORT>
    <APPLYCLWVERSIONTO>c:\projects\KSSOpen\source\VersionMe.clw</APPLYCLWVERSIONTO>
    <APPLYCLWTEMPLATE>c:\projects\KSSOpen\source\VersionMeTemplate.clw</APPLYCLWTEMPLATE>
    <SBINIFILE>C:\Dropbox (Personal)\somefolder\MyAppVersion.ini</SBINIFILE> <!-- fully qualified path to the ini used by SB-->
</VersionMeConfig>
```

Note: The ApplyCLWVersionTo and ApplyCLWTemplate values need to be valid file specs in your source tree. 

As an example, for KSS...

c:\projects\KSSOpen\source\VersionMe.clw looks like this:
```
glo:szVersion        CSTRING('2022.1.21.24')
```
(doesnt really matter - this file is overlaid upon every compile)

and 

c:\projects\KSSOpen\source\VersionMeTemplate.clw looks like this:
```
glo:szVersion        CSTRING('$VERSIONME')
```

3) Build

when you build and versionme.exe runs, it will create an ini file that looks like this: 

```
[build]
version=2021.9.24
```

The ini will be named as specified the XML above via the SBINIFILE value. 

That ini will (can) be read by SetupBuilder like this:

![VersionME SetupBuilder ini code](https://github.com/mriffey/VersionMe/blob/master/VersionMeSetupBuilderIniSetup.jpg?raw=true)

Once you've read it into SB, you can use it as you wish. 


![The resulting binary](https://github.com/mriffey/VersionMe/blob/master/VersionMeVersioningWorked.jpg?raw=true)

