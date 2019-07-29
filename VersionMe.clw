
  PROGRAM

  INCLUDE('StringTheory.inc')   ! if your compile fails on this line, you need Capesoft's StringTheory. This is an unpaid endorsement:)
  INCLUDE('xfiles.inc')         ! if your compile fails on this line, you need Capesoft's xFiles. This is an unpaid endorsement:)
  
fp_VMe_SHGetFolderPath             ULONG,STATIC,NAME('VMe_SHGetFolderPath')
  
  MAP
    VMe_GetFolderPath(LONG pCSIDLFolderType, <BYTE pCreateFlag>),STRING 
    VMe_Internal_LoadDLLProc(STRING pProc,STRING pDLL,*ULONG pProcAddress,<*ULONG pInstance>),LONG,PROC,NAME('VMe_Internal_LoadDLLProc')     
    VMe_Internal_GetFolderPath(LONG FolderID,<BYTE CreateFlag>),STRING 

    MODULE('Win32')
       VMe_SHGetFolderPath(ULONG,LONG,ULONG,ULONG,*CSTRING),ULONG,RAW,PASCAL,DLL(_fp_)  
       VMe_GetLastError(),LONG,RAW,PASCAL,NAME('GetLastError')
       VMe_LoadLibrary(*CSTRING lpLibFileName),ULONG,PASCAL,RAW,NAME('LoadLibraryA')
       VMe_FreeLibrary(ULONG hInstance),BYTE,PASCAL,RAW,NAME('FreeLibrary')
       VMe_GetProcAddress(ULONG hInstance,*CSTRING lpProcName),ULONG,PASCAL,RAW,NAME('GetProcAddress')
    END    
  END

VMe::CSIDL_COMMON_DOCUMENTS        EQUATE(02Eh)  
EQ:ConfigVersionTypePRJ            EQUATE('PRJ')
EQ:ConfigVersionTypeSLN            EQUATE('SLN')
  
strBinaryType       STRING(10)  
strBinaryName       STRING(50)
strPublicDocuments  STRING(512) 
strAppFolder        STRING(512) 
strRev              STRING(5) 


gConfig             GROUP
VersionType                 STRING(3) ! PRJ = version projects by prj, SLN = version project by sln
ProductName                 STRING(50) 
CompanyName                 STRING(50)
CopyrightStartYear          LONG 
FileVersionNumberMaj        STRING(5)  ! versions are formatted as Major.Minor.Sub.Revision Build #####
FileVersionNumberMin        STRING(5) 
FileVersionNumberSub        STRING(5) 
FileVersionNumberRev        STRING(5) 
ProductVersionNumberMaj     STRING(5)  ! versions are formatted as Major.Minor.Sub.Revision Build #####
ProductVersionNumberMin     STRING(5) 
ProductVersionNumberSub     STRING(5) 
ProductVersionNumberRev     STRING(5) 
BuildNumber                 LONG 
VersionText                 STRING(50) ! ie: Activation 2.2 Build 1234
VersionTextShort            STRING(10) ! ie: Act2.2
SBIniFile                   STRING(512)
                    END
                    

qConfig             QUEUE 
ProjectName                 STRING(50)
FileVersionNumberMaj        STRING(5)
FileVersionNumberMin        STRING(5)
FileVersionNumberSub        STRING(5)
FileVersionNumberRev        STRING(5)
ProductVersionNumberMaj     STRING(5)  ! versions are formatted as Major.Minor.Sub.Revision Build #####
ProductVersionNumberMin     STRING(5) 
ProductVersionNumberSub     STRING(5) 
ProductVersionNumberRev     STRING(5) 
BuildNumber                 LONG 
VersionText                 STRING(50)  ! if left blank, sln-level text will be used.
VersionTextShort            STRING(10)  ! if left blank, sln-level text will be used.
                    END
                    
strFileVersion          STRING(20)
strFileVersionDOTS      STRING(20)
strProductVersion       STRING(20)
strProductVersionDOTS   STRING(20)
strDLLorEXE             STRING(10) 
intCurrentYear          LONG
strProjectName          STRING(30)
strBinaryFullName       STRING(30) 
intBuildNumber          LONG 
strVersionText          STRING(50)
strVersionTextShort     STRING(10) 
strProductName          STRING(50) 

oXML                    XFileXML 
oST                     StringTheory

  CODE
  
  DO SetupAndGetParameters
  
  ! set version     
  CASE gConfig.VersionType
     OF EQ:ConfigVersionTypePRJ ! uses qConfig fields (queue)
        DO SetVersionByProject 
                        
     OF EQ:ConfigVersionTypeSLN ! uses gConfig fields (group) 
        DO SetVersionBySolution
  END 

  DO BuildVersionFile      
  
  ! Re-save updated config file. 
!  oXML.Trace('Before Save ================')
!  oXML.Trace('gConfig.BuildNumber=' & gConfig.BuildNumber)
!  oXML.Trace('gConfig.FileVersionNumberMaj=' & gConfig.FileVersionNumberMaj)
!  oXML.Trace('gConfig.FileVersionNumberMin=' & gConfig.FileVersionNumberMin)
!  oXML.Trace('gConfig.FileVersionNumberSub=' & gConfig.FileVersionNumberSub)
!  oXML.Trace('gConfig.FileVersionNumberRev=' & gConfig.FileVersionNumberRev)
!  oXML.Trace('gConfig.FileVersionNumberMaj=' & gConfig.FileVersionNumberMaj)
!  oXML.Trace('gConfig.VersionText=' & gConfig.VersionText)
!  oXML.Trace('gConfig.VersionTextShort=' & gConfig.VersionTextShort)
!  oXML.Trace('gConfig.SBINIFILE=' & gConfig.SBIniFile)
  
  oXML.Save(gConfig,CLIP(strAppFolder) & '\' & CLIP(strBinaryName) & '_VersionMe.xml','VersionMeConfig','')
  oXML.Trace('at end records(qconfig)=' & RECORDS(qConfig))
  
!  IF RECORDS(qConfig) > 0
!     oXML.Append = TRUE 
!     oXML.Save(qConfig,CLIP(strAppFolder) & '\' & CLIP(strBinaryName) & '_VersionMe.xml','Projects','Project')
!  END 
!    
  RETURN 

!-------------------------------------
SetupAndGetParameters  ROUTINE 
!-------------------------------------  

 intCurrentYear = YEAR(TODAY())
 strPublicDocuments = VMe_GetFolderPath(VMe::CSIDL_COMMON_DOCUMENTS) 
 
 strAppFolder  = COMMAND('AppFolder') 
 strBinaryName = COMMAND('Project') ! this must be done before the other COMMANDs since part of the CASE for BinaryType depends on this value. 
 strBinaryType = COMMAND('BinaryType') 
 
 CASE LOWER(CLIP(strBinaryType))
    OF 'winexe'
       strDLLorEXE = 'VFT_APP'
       strBinaryFullName = CLIP(strBinaryName) & '.EXE'
    OF 'library'
       strDLLorEXE = 'VFT_DLL'
       strBinaryFullName = CLIP(strBinaryName) & '.DLL'
 END 
 
 ! get versioning config
 IF EXISTS(CLIP(strAppFolder) & '\' & CLIP(strBinaryName) & '_VersionMe.xml') = TRUE 
    oXML.TagCase = XF:CaseAny
    oXML.LoggingOn = TRUE 
    oXML.Load(gConfig,CLIP(strAppFolder) & '\' & CLIP(strBinaryName) & '_VersionMe.xml','VersionMeConfig','')   
    
!    oXML.Trace('After Load ================')
!    oXML.Trace('gConfig.BuildNumber=' & gConfig.BuildNumber)
!    oXML.Trace('gConfig.FileVersionNumberMaj=' & gConfig.FileVersionNumberMaj)
!    oXML.Trace('gConfig.FileVersionNumberMin=' & gConfig.FileVersionNumberMin)
!    oXML.Trace('gConfig.FileVersionNumberSub=' & gConfig.FileVersionNumberSub)
!    oXML.Trace('gConfig.FileVersionNumberRev=' & gConfig.FileVersionNumberRev)
!    oXML.Trace('gConfig.FileVersionNumberMaj=' & gConfig.FileVersionNumberMaj)
!    oXML.Trace('gConfig.VersionText=' & gConfig.VersionText)
!    oXML.Trace('gConfig.VersionTextShort=' & gConfig.VersionTextShort)
!    oXML.Trace('gConfig.SBINIFILE=' & gConfig.SBIniFile)    

    gConfig.BuildNumber += 1        
    
    IF gConfig.VersionType = EQ:ConfigVersionTypeSLN ! solution-wide versioning       
    ELSE                                             ! project by project versioning
       DO LoadProjectConfig 
       qConfig.BuildNumber += 1
       PUT(qConfig)
    END
 ELSE
    MESSAGE('Config file needed. Filename for ' & CLIP(strBinaryName) & '.cwproj should be "' & CLIP(strAppFolder) & '\' & CLIP(strBinaryName) & '_VersionMe.xml".')
 END 
 
 EXIT 
 
!-------------------------------------
SetVersionBySolution ROUTINE      
!-------------------------------------
! supports data.YYYY.MM.DD, YYYY.MM.DD.data, data.YY.MM.DD, YY.MM.DD.data and data.data.data.data.
!-------------------------------------
         
 CASE CLIP(gConfig.FileVersionNumberMaj)
    ! supports YYYY.MM.DD.data
    OF 'YYYY'
       IF CLIP(gConfig.FileVersionNumberRev) > ' '       
          strRev = gConfig.FileVersionNumberRev   
       ELSE
          strRev = gConfig.BuildNumber  ! we use strRev because we dont want this value stored
       END 
       strFileVersion     = YEAR(TODAY()) & ',' & MONTH(TODAY()) & ',' & DAY(TODAY()) & ',' & CLIP(strRev)          
       strFileVersionDOTS = YEAR(TODAY()) & '.' & MONTH(TODAY()) & '.' & DAY(TODAY()) & '.' & CLIP(strRev)          
    
    ! supports YY.MM.DD.data
    OF 'YY'
       IF CLIP(gConfig.FileVersionNumberRev) > ' '       
          strRev = gConfig.FileVersionNumberRev
       ELSE
          strRev = gConfig.BuildNumber
       END 
       strFileVersion     = FORMAT(YEAR(TODAY()) - 2000,@N_2) & ',' & MONTH(TODAY()) & ',' & DAY(TODAY()) & ',' & CLIP(strRev)          
       strFileVersionDOTS = FORMAT(YEAR(TODAY()) - 2000,@N_2) & '.' & MONTH(TODAY()) & '.' & DAY(TODAY()) & '.' & CLIP(strRev)          
       
    ELSE       
       IF CLIP(gConfig.FileVersionNumberMin) = 'YYYY' 
          ! supports data.YYYY.MM.DD
          strFileVersion     = CLIP(gConfig.FileVersionNumberMaj) & ',' & YEAR(TODAY()) & ',' & MONTH(TODAY()) & ',' & DAY(TODAY()) 
          strFileVersionDOTS = CLIP(gConfig.FileVersionNumberMaj) & '.' & YEAR(TODAY()) & '.' & MONTH(TODAY()) & '.' & DAY(TODAY()) 
       ELSE
          ! supports data.YY.MM.DD
          IF CLIP(gConfig.FileVersionNumberMin) = 'YY' 
             strFileVersion     = CLIP(gConfig.FileVersionNumberMaj) & ',' & FORMAT(YEAR(TODAY()) - 2000,@N_2) & ',' & MONTH(TODAY()) & ',' & DAY(TODAY())           
             strFileVersionDOTS = CLIP(gConfig.FileVersionNumberMaj) & '.' & FORMAT(YEAR(TODAY()) - 2000,@N_2) & '.' & MONTH(TODAY()) & '.' & DAY(TODAY())           
          ELSE 
             ! supports data.data.data.data.
             strFileVersion = CLIP(gConfig.FileVersionNumberMaj) & ',' & CLIP(gConfig.FileVersionNumberMin) & ',' & CLIP(gConfig.FileVersionNumberSub) & ',' & CLIP(gConfig.FileVersionNumberRev)
             strFileVersion = CLIP(gConfig.FileVersionNumberMaj) & '.' & CLIP(gConfig.FileVersionNumberMin) & '.' & CLIP(gConfig.FileVersionNumberSub) & '.' & CLIP(gConfig.FileVersionNumberRev)
          END 
       END 
 END 

 
 IF CLIP(gConfig.ProductVersionNumberMaj) > ' '
    CASE CLIP(gConfig.ProductVersionNumberMaj)
       ! supports YYYY.MM.DD.data
       OF 'YYYY'
          IF CLIP(gConfig.FileVersionNumberRev) > ' '       
             strRev = gConfig.FileVersionNumberRev   
          ELSE
             strRev = gConfig.BuildNumber  ! we use strRev because we dont want this value stored
          END 
       
          strProductVersion     = YEAR(TODAY()) & ',' & MONTH(TODAY()) & ',' & DAY(TODAY()) & ',' & CLIP(strRev)          
          strProductVersionDOTS = YEAR(TODAY()) & '.' & MONTH(TODAY()) & '.' & DAY(TODAY()) & '.' & CLIP(strRev)          
       
       ! supports YY.MM.DD.data
       OF 'YY'
          IF CLIP(gConfig.FileVersionNumberRev) > ' '       
             strRev = gConfig.FileVersionNumberRev   
          ELSE
             strRev = gConfig.BuildNumber  ! we use strRev because we dont want this value stored
          END 
          
          strProductVersion     = FORMAT(YEAR(TODAY()) - 2000,@N_2) & ',' & MONTH(TODAY()) & ',' & DAY(TODAY()) & ',' & CLIP(strRev)          
          strProductVersionDOTS = FORMAT(YEAR(TODAY()) - 2000,@N_2) & '.' & MONTH(TODAY()) & '.' & DAY(TODAY()) & '.' & CLIP(strRev)          
          
       ELSE
          strProductVersion = CLIP(gConfig.ProductVersionNumberMaj)
          
          IF CLIP(gConfig.ProductVersionNumberMin) = 'YYYY' 
             ! supports data.YYYY.MM.DD
             strProductVersion     = CLIP(strProductVersion) & ',' & YEAR(TODAY()) & ',' & MONTH(TODAY()) & ',' & DAY(TODAY()) 
             strProductVersionDOTS = CLIP(strProductVersion) & '.' & YEAR(TODAY()) & '.' & MONTH(TODAY()) & '.' & DAY(TODAY()) 
          ELSE
             ! supports data.YY.MM.DD
             IF CLIP(gConfig.ProductVersionNumberMin) = 'YY' 
                strProductVersion = CLIP(strProductVersion) & ',' & FORMAT(YEAR(TODAY()) - 2000,@N_2) & ',' & MONTH(TODAY()) & ',' & DAY(TODAY())           
             ELSE 
                ! supports data.data.data.data.
                IF CLIP(gConfig.FileVersionNumberRev) > ' '       
                   strRev = gConfig.FileVersionNumberRev   
                ELSE
                   strRev = gConfig.BuildNumber  ! we use strRev because we dont want this value stored
                END                 

                strProductVersion = CLIP(strProductVersion) & ',' & CLIP(gConfig.ProductVersionNumberMin) & ',' & CLIP(gConfig.ProductVersionNumberSub) & ',' & CLIP(strRev)
             END 
          END 
    END 
 ELSE 
    strProductVersion = strFileVersion
 END 

 intBuildNumber       = gConfig.BuildNumber
 
 strVersionText       = gConfig.VersionText
 strVersionTextShort  = gConfig.VersionTextShort       
 strProductName       = gConfig.ProductName        
 
 EXIT 


!-------------------------------------                
SetVersionByProject ROUTINE 
!-------------------------------------        

 IF CLIP(gConfig.FileVersionNumberRev) > ' '       
    strRev = qConfig.FileVersionNumberRev   
 ELSE
    strRev = qConfig.BuildNumber  ! we use strRev because we dont want this value stored
 END 

 strFileVersion     = CLIP(qConfig.FileVersionNumberMaj) & ',' & CLIP(qConfig.FileVersionNumberMin) & ',' & CLIP(qConfig.FileVersionNumberSub) & ',' & CLIP(strRev)
 strFileVersionDOTS = CLIP(qConfig.FileVersionNumberMaj) & '.' & CLIP(qConfig.FileVersionNumberMin) & '.' & CLIP(qConfig.FileVersionNumberSub) & '.' & CLIP(strRev)
 
 IF CLIP(qConfig.ProductVersionNumberMaj) > ' '
    strProductVersion     = CLIP(qConfig.ProductVersionNumberMaj) & ',' & CLIP(qConfig.ProductVersionNumberMin) & ',' & CLIP(qConfig.ProductVersionNumberSub) & ',' & CLIP(strRev)
    strProductVersionDOTS = CLIP(qConfig.ProductVersionNumberMaj) & '.' & CLIP(qConfig.ProductVersionNumberMin) & '.' & CLIP(qConfig.ProductVersionNumberSub) & '.' & CLIP(strRev)
 ELSE 
    strProductVersion = strFileVersion
 END 
  
 IF CLIP(qConfig.VersionText) > ' '
    strVersionText       = qConfig.VersionText
 ELSE 
    strVersionText       = gConfig.VersionText
 END 
 
 IF CLIP(qConfig.VersionText) > ' '
    strVersionTextShort  = qConfig.VersionTextShort
 ELSE 
    strVersionTextShort  = gConfig.VersionTextShort
 END 

 intBuildNumber       = qConfig.BuildNumber
 strProductName       = CLIP(gConfig.ProductName) & ' - ' & CLIP(qConfig.ProjectName)        
 
 EXIT   
  
!-----------------------------------  
BuildVersionFile ROUTINE 
!-----------------------------------    

 oST.SetValue('LANGUAGE 0x0409<13,10>' |
            & '<13,10>' |
            & '1 VERSIONINFO<13,10>' |
            & ' FILEVERSION $FILEVERSION$<13,10>' |
            & ' PRODUCTVERSION $PRODUCTVERSION$<13,10>' |
            & ' FILEFLAGSMASK 0x3FL<13,10>' |
            & ' FILEFLAGS 0x1L<13,10>' |
            & ' FILEOS VOS__WINDOWS32<13,10>' |
            & ' FILETYPE $DLLOREXE$<13,10>' |
            & ' FILESUBTYPE 0x0L<13,10>' |
            & 'BEGIN<13,10>' |
            & '  BLOCK "StringFileInfo"<13,10>' |
            & '  BEGIN<13,10>' |
            & '    BLOCK "040904E4"<13,10>' |
            & '      BEGIN<13,10>' |
            & '        VALUE "CompanyName", "$COMPANYNAME$\0"<13,10>' |
            & '        VALUE "FileDescription", "$VERSIONTEXTSHORT$ $FILEVERSIONDOTS$ Build $BUILDNUMBER$\0"<13,10>' |            
            & '        VALUE "FileVersion", "$FILEVERSIONDOTS$\0"<13,10>' |
            & '        VALUE "InternalName", "$BINARYNAME$\0"<13,10>' |
            & '        VALUE "LegalCopyright", "Copyright (c) $STARTYEAR$-$CURRENTYEAR$ $COMPANYNAME$\0"<13,10>' |
            & '        VALUE "LegalTrademarks", "$VERSIONTEXT$ $YYYYMMDD$\0"<13,10>' |
            & '        VALUE "OriginalFilename", "$BINARYFULLNAME$\0"<13,10>' |
            & '        VALUE "ProductName", "$PRODUCT$\0"<13,10>' |
            & '        VALUE "ProductVersion", "$FILEVERSIONDOTS$\0"<13,10>' |            
            & '        VALUE "Comments", "$FILEVERSIONDOTS$ Build $BUILDNUMBER$\0"<13,10>' |
            & '      END<13,10>' |
            & '    END<13,10>' |
            & '    BLOCK "VarFileInfo"<13,10>' |
            & '    BEGIN<13,10>' |
            & '        VALUE "Translation", 0x0409, 1252<13,10>' |
            & '    END<13,10>' |
            & 'END<13,10>')
            
 oST.Replace('$FILEVERSION$',CLIP(strFileVersion))
 oST.Replace('$FILEVERSIONDOTS$',CLIP(strFileVersionDOTS))
 oST.Replace('$PRODUCTVERSION$',CLIP(strProductVersion))         ! If your XML config leaves ProductVersionNumberMaj blank, product version will equal file version.
 oST.Replace('$PRODUCTVERSIONDOTS$',CLIP(strProductVersionDOTS)) ! If your XML config leaves ProductVersionNumberMaj blank, product version will equal file version.
 oST.Replace('$DLLOREXE$',CLIP(strDLLorEXE))
 oST.Replace('$BINARYNAME$',CLIP(strBinaryName))
 oST.Replace('$BINARYFULLNAME$',CLIP(strBinaryFullName))
 oST.Replace('$COMPANYNAME$',CLIP(gConfig.CompanyName))
 oST.Replace('$STARTYEAR$',CLIP(gConfig.CopyrightStartYear))
 oST.Replace('$CURRENTYEAR$',CLIP(YEAR(TODAY())))
 oST.Replace('$VERSIONTEXT$',CLIP(strVersionText))
 oST.Replace('$YYYYMMDD$',CLIP(FORMAT(TODAY(),@D10-)))
 oST.Replace('$VERSIONTEXTSHORT$',CLIP(strVersionTextShort))
 oST.Replace('$BUILDNUMBER$',CLIP(intBuildNumber))
 oST.Replace('$PRODUCT$',CLIP(strProductName))
 
  CASE gConfig.VersionType
     OF EQ:ConfigVersionTypePRJ
        oST.SaveFile(CLIP(strAppFolder) & '\' & CLIP(strProjectName) & '.version') 
        
     OF EQ:ConfigVersionTypeSLN
        oST.SaveFile(CLIP(strAppFolder) & '\' & CLIP(strBinaryName) & '.version') 
  END 
 
 ! create setupbuilder ini for auto versioning the installer and control panel app's info. 
 !
 !SB ini looks LIKE this:
 ![build]
 !version=major.minor.sub.rev.build example: 2019.5.24.930
 
 IF CLIP(gConfig.SBIniFile) > ' '
    oST.SetValue('[build]<13,10>version=' & CLIP(strFileVersionDots))
    oST.SaveFile(gConfig.SBIniFile)
 END 
 
 EXIT 
 
!-------------------------------------------     
LoadProjectConfig ROUTINE 
!-------------------------------------------     
 DATA
intFoundPrj LONG 
intLoop     LONG 

 CODE 

 oXML.Load(qConfig,CLIP(strAppFolder) & '\' & CLIP(strBinaryName) & '_VersionMe.xml','Projects','Project')

 IF RECORDS(qConfig) = 0 ! use solution based versioning
 ELSE
    intFoundPrj = 0
    LOOP intLoop = 1 TO RECORDS(qConfig)
       GET(qConfig, intLoop)
       IF LOWER(CLIP(qConfig.ProjectName)) = LOWER(CLIP(strBinaryName))
          intFoundPrj = 1
          BREAK
       END         
    END 
 END  
     
 EXIT 
  
!-----------------------------------------                    
VMe_GetFolderPath       PROCEDURE(LONG pCSIDLFolderType, <BYTE pCreateFlag>)!,STRING 
!-----------------------------------------
strFolder STRING(256)
 CODE 
   
  IF OMITTED(pCreateFlag)
     strFolder = VMe_Internal_GetFolderPath(pCSIDLFolderType)
  ELSE
     strFolder = VMe_Internal_GetFolderPath(pCSIDLFolderType,pCreateFlag)
  END  
  
  RETURN(strFolder)
  
!--------------------------------------------------------------------------
VMe_Internal_GetFolderPath        PROCEDURE(LONG FolderID,<BYTE CreateFlag>)!,STRING
!--------------------------------------------------------------------------
SHGFP_TYPE_CURRENT            EQUATE(0)
SHGFP_TYPE_DEFAULT            EQUATE(1)
E_INVALIDARG                  EQUATE(080070057h)
VMe::CSIDL_FLAG_CREATE         EQUATE(08000h)

dirstr CSTRING(512)
result LONG

  CODE

  IF VMe_Internal_LoadDLLProc('SHGetFolderPathA','shell32',fp_VMe_SHGetFolderPath)
     fp_VMe_SHGetFolderPath = 0
     IF VMe_Internal_LoadDLLProc('SHGetFolderPathA','shfolder',fp_VMe_SHGetFolderPath)
        RETURN('') ! Function not found
     END
  END
  
  IF OMITTED(CreateFlag)
     result = VMe_SHGetFolderPath(0,FolderID,0,SHGFP_TYPE_CURRENT,dirstr)
  ELSE
     IF CreateFlag
        result = VMe_SHGetFolderPath(0,FolderID+VMe::CSIDL_FLAG_CREATE,0,SHGFP_TYPE_CURRENT,dirstr)
     ELSE
        result = VMe_SHGetFolderPath(0,FolderID,0,SHGFP_TYPE_CURRENT,dirstr)
     END
  END
  
  CASE result
  OF 0 ! Success
     RETURN(CLIP(dirstr))

  OF 1 ! Folder does not exist
     RETURN('')

  ELSE ! E_INVALIDARG
     RETURN('')
  END

!--------------------------------------------------------------------------
VMe_Internal_LoadDLLProc       PROCEDURE(STRING pProc,STRING pDLL,*ULONG pProcAddress,<*ULONG pInstance>)
!--------------------------------------------------------------------------
hInstance       ULONG
lpLibFileName   CSTRING(255)
lpProcName      CSTRING(255)
success         LONG
NonExistent     ULONG

  CODE

  NonExistent = 0ffffffffh
  IF pProcAddress = NonExistent ! Proc does not exist
     RETURN(TRUE)
  END 
  
  IF pProcAddress <> 0 ! Load DLL once
     RETURN(FALSE)
  END 
  
  lpLibFileName = CLIP(pDLL) & '<0>'
  hInstance = VMe_LoadLibrary(lpLibFileName)
  
  IF hInstance
     lpProcName = clip(pProc) & '<0>'
     pProcAddress = VMe_GetProcAddress(hInstance, lpProcName)
     IF pProcAddress
        IF ~OMITTED(pInstance)
           pInstance = hInstance
        END
        RETURN(FALSE)
     ELSE
        success = VMe_FreeLibrary(hInstance)
        IF ~success
        END
        pProcAddress = NonExistent ! Flag as non existent
        RETURN(TRUE)
     END
  ELSE
     pProcAddress = NonExistent ! Flag as non existent
     RETURN(TRUE)
  END
  
  
