# VersionMe
Easy build time versioning for Clarion appgen / hand coded apps.

VersionMe gives your clarion app the ability to version your app with build numbers. Each time you compile, the build number is incremented for you. 

This build number ends up in your app so you can see it via the Windows Explorer details tab. In addition, you can pass this data to SetupBuilder so it can use automatic version checking. 


**SETTING UP VersionMe** 

In your Clarion project, add this line to the "Pre-build event command line":
c:\projects\VersionMe\VersionMe.exe PROJECT=$(OutputName) BINARYTYPE=$(OutputType) APPFOLDER=$(SolutionDir) 

The path/filename for VersionMe.exe can be different - but it must resolve successfully at compile time. 

Example:

![alt text](https://github.com/mriffey/VersionMe/blob/master/VersionMeProjectDetails.jpg?raw=true)
