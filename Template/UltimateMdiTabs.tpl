#!*****************************************************************************
#TEMPLATE(UltimateMdiTabs,'MdiTabs Template'),FAMILY('ABC','CW20')
#!*****************************************************************************
#!*****************************************************************************
#EXTENSION(MdiTabsGlobal,'MdiTabs Global Support'),APPLICATION,DESCRIPTION('MdiTabs Global Support')
#PROMPT('Frame Object Name:',@S100),%MdiTabsFrameObject,DEFAULT('MdiTabsFrame')
#PROMPT('Local Window Object Name:',@S100),%MdiTabsWindowObject,DEFAULT('MdiTabsWindow')
#!*****
#AT(%AfterGlobalIncludes),DESCRIPTION('MdiTabsClass Include')
   INCLUDE('UltimateMdiTabs.inc'),ONCE
#ENDAT
#!*****
#ATSTART
  #DECLARE(%MdiTabEnabled)
  #DECLARE(%MdiTabDerived)
  #DECLARE(%MdiTabManualText)
  #DECLARE(%MdiTabManualIcon)
#ENDAT
#!**********
#AT(%GatherSymbols),PRIORITY(1000)
  #CALL(%mdiTabsGatherSymbols1)
#ENDAT
#!**********
#AT(%GatherSymbols),PRIORITY(3000)
  #CALL(%mdiTabsGatherSymbols3)
#ENDAT
#!*****
#AT(%DataSection),WHERE(%WindowAffectsTabs()),PRIORITY(8427)
    #IF(NOT %MdiTabDerived)
%[20]MdiTabsWindowObject UltimateMdiTabsWindow
    #ELSE
%[20]MdiTabsWindowObject CLASS(UltimateMdiTabsWindow)
ProvideIcon            PROCEDURE,STRING,DERIVED
ProvideText            PROCEDURE,STRING,DERIVED
                     END
    #ENDIF
#ENDAT
#!*****
#AT(%AfterWindowOpening),WHERE(%WindowAffectsTabs()),PRIORITY(8427)
%MdiTabsWindowObject.Init(%Window)
#ENDAT
#!*****
#AT(%WindowManagerMethodCodeSection,'TakeEvent','(),BYTE'),WHERE(%WindowAffectsTabs()),PRIORITY(6327)
%MdiTabsWindowObject.TakeEvent()
#ENDAT
#!---Legacy
#AT(%AcceptLoopAfterEventHandling),WHERE(%WindowAffectsTabs()),PRIORITY(4027)
%MdiTabsWindowObject.TakeEvent()
#ENDAT
#!*****
#AT(%LocalProcedures),PRIORITY(8427),WHERE(%MdiTabDerived)

%MdiTabsWindowObject.ProvideIcon PROCEDURE!,STRING
  CODE
  #EMBED(%MdiTabProvideIcon,'MdiTabs ProvideIcon method to return tab icon')
        #IF(%MdiTabManualIcon)
  RETURN '~%MdiTabManualIcon'
        #ELSE
  RETURN PARENT.ProvideIcon()
        #ENDIF

%MdiTabsWindowObject.ProvideText PROCEDURE!,STRING
  CODE
  #EMBED(%MdiTabProvideText,'MdiTabs ProvideText method to return tab text')
        #IF(%MdiTabManualText)
  RETURN %MdiTabManualText
        #ELSE
  RETURN PARENT.ProvideText()
        #ENDIF

#ENDAT
#!*****************************************************************************
#GROUP(%WindowAffectsTabs)
  #RETURN(%MdiTabEnabled)
#!*****************************************************************************
#!*****************************************************************************
#EXTENSION(MdiTabsLocal,'MdiTabs Local Override'),DESCRIPTION('MdiTabs Local Override')
  #BOXED('MdiTabs Local Override')
    #PROMPT('Support this window/thread',DROP('Automatic|Derived|Disabled')),%LocalSupport,DEFAULT('Automatic')
    #ENABLE(%LocalSupport <> 'Disabled')
      #PROMPT('Manual Tab Text:',EXPR),%ManualTabText
      #PROMPT('Icon File:',OPENDIALOG('Select Icon for the MDI tab','Icons|*.ICO')),%ManualTabIcon
    #ENDENABLE
  #ENDBOXED
#!**********
#AT(%CustomGlobalDeclarations)
  #CALL(%StandardAddIconToProject(ABC), %ManualTabIcon)
#ENDAT
#!**********
#AT(%GatherSymbols),PRIORITY(2000)
  #!Local intervention
  #IF(%ManualTabText)
    #SET(%MdiTabManualText, %ManualTabText)
    #SET(%MdiTabDerived, %True)
  #ENDIF
  #IF(%ManualTabIcon)
    #SET(%MdiTabManualIcon, %ManualTabIcon)
    #SET(%MdiTabDerived, %True)
  #ENDIF
  #CASE(%LocalSupport)
  #OF('Derived')
    #SET(%MdiTabDerived, %True)
  #OF('Disabled')
    #SET(%MdiTabEnabled, %False)
  #ENDCASE
#ENDAT
#!*****************************************************************************
#!*****************************************************************************
#GROUP(%mdiTabsGatherSymbols1)
#!Global survey, set default configuration
  #SET(%MdiTabDerived, %False)
  #CLEAR(%MdiTabManualText)
  #CLEAR(%MdiTabManualIcon)
  #IF(%Window AND ~EXTRACT(%WindowStatement, 'APPLICATION') AND ~EXTRACT(%WindowStatement, 'TOOLBOX'))
    #SET(%MdiTabEnabled, %True)
  #ELSE
    #SET(%MdiTabEnabled, %False)
  #ENDIF
#!*****************************************************************************
#GROUP(%mdiTabsGatherSymbols3)
#!Global response
#!*****************************************************************************
#!*****************************************************************************
#CONTROL(MdiTabsFrame,'MdiTabs Frame Support'),DESCRIPTION('MdiTabs Frame Support')
  CONTROLS
    SHEET,AT(,,,12),USE(?MdiTabsSheet),FULL,NOSHEET
    END
  END
#!*****
#AT(%DataSection),PRIORITY(8427)
%[20]MdiTabsFrameObject UltimateMdiTabsFrame
#ENDAT
#!*****
#AT(%AfterWindowOpening),PRIORITY(8427)
    #FOR(%Control),WHERE(%ControlInstance = %ActiveTemplateInstance)
%MdiTabsFrameObject.Init(%Window, %Control)
      #BREAK
    #ENDFOR
#ENDAT
#!*****
#AT(%AcceptLoopBeforeEventHandling),PRIORITY(1327)
%MdiTabsFrameObject.TakeEvent()
#ENDAT
#!*****************************************************************************
