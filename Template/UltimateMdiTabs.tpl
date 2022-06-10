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
  #DECLARE(%MdiTabManualText)
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
%[20]MdiTabsWindowObject UltimateMdiTabsWindow
#ENDAT
#!*****
#AT(%WindowManagerMethodCodeSection,'TakeEvent','(),BYTE'),WHERE(%WindowAffectsTabs()),PRIORITY(6327)
    #IF(%MdiTabManualText)
%MdiTabsWindowObject.ManualText = %MdiTabManualText
    #ENDIF
%MdiTabsWindowObject.TakeEvent()
#ENDAT
#!Do this if it's legacy
#!AT(%AcceptLoopAfterEventHandling),WHERE(%WindowAffectsTabs()),PRIORITY(4027)
#!%MdiTabsWindowObject.TakeEvent()
#!ENDAT
#!*****************************************************************************
#GROUP(%WindowAffectsTabs)
  #RETURN(%MdiTabEnabled)
#!*****************************************************************************
#!*****************************************************************************
#EXTENSION(MdiTabsLocal,'MdiTabs Local Override'),DESCRIPTION('MdiTabs Local Override')
  #BOXED('MdiTabs Local Override')
    #PROMPT('Disable MdiTab for this window/thread',CHECK),%MdiTabDisabled,AT(10,,180)
    #ENABLE(~%MdiTabDisabled)
      #PROMPT('Manual Tab Text:',EXPR),%ManualTabText
    #ENDENABLE
  #ENDBOXED
#!**********
#AT(%GatherSymbols),PRIORITY(2000)
  #CALL(%mdiTabsGatherSymbols2)
#ENDAT
#!*****************************************************************************
#!*****************************************************************************
#GROUP(%mdiTabsGatherSymbols1)
#!Global survey, set default configuration
  #IF(%Window)
    #IF(EXTRACT(%WindowStatement, 'APPLICATION'))
      #SET(%MdiTabEnabled, %False)
    #ELSE
      #SET(%MdiTabEnabled, %True)
    #ENDIF
  #ELSE
    #SET(%MdiTabEnabled, %False)
  #ENDIF
  #CLEAR(%MdiTabManualText)
#!*****************************************************************************
#GROUP(%mdiTabsGatherSymbols2)
#!Local intervention
  #IF(%MdiTabDisabled)
    #SET(%MdiTabEnabled, %False)
  #ENDIF
  #IF(%ManualTabText)
    #SET(%MdiTabManualText, %ManualTabText)
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
%MdiTabsFrameObject.Init(%Control)
      #BREAK
    #ENDFOR
#ENDAT
#!*****
#AT(%AcceptLoopBeforeEventHandling),PRIORITY(1327)
%MdiTabsFrameObject.TakeEvent()
#ENDAT
#!*****************************************************************************
