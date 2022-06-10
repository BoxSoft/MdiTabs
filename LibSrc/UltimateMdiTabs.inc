!ABCIncludeFile

UltimateMdiTabsFrame          CLASS,TYPE,MODULE('UltimateMdiTabs.clw'),LINK('UltimateMdiTabs.clw',_ABCLinkMode_),DLL(_ABCDllMode_)
SheetFeq                        SIGNED,PROTECTED
Init                            PROCEDURE(SIGNED SheetFeq)
DestroyTab                      PROCEDURE(SIGNED TabFeq),VIRTUAL
TakeEvent                       PROCEDURE,VIRTUAL
TakeNewSelection                PROCEDURE
UpdateTabs                      PROCEDURE(SIGNED NotifyThread,LONG NotifyParameter),VIRTUAL
                              END

UltimateMdiTabsWindow         CLASS,TYPE,MODULE('UltimateMdiTabs.clw'),LINK('UltimateMdiTabs.clw',_ABCLinkMode_),DLL(_ABCDllMode_)
ManualText                      CSTRING(1000)
Construct                       PROCEDURE
Destruct                        PROCEDURE
SetText                         PROCEDURE(<STRING Text>)
HideTab                         PROCEDURE
UnhideTab                       PROCEDURE
TakeEvent                       PROCEDURE
!TakeOpenWindow                 PROCEDURE
!TakeGainFocus                  PROCEDURE
!SetActiveThread                PROCEDURE
                              END
