!ABCIncludeFile

UltimateMdiTabsFrame          CLASS,TYPE,MODULE('UltimateMdiTabs.clw'),LINK('UltimateMdiTabs.clw',_ABCLinkMode_),DLL(_ABCDllMode_)
Window                          &WINDOW,PROTECTED
SheetFeq                        SIGNED,PROTECTED
BoldTabFeq                      UNSIGNED,PROTECTED
Init                            PROCEDURE(*WINDOW Window,SIGNED SheetFeq)
DestroyTab                      PROCEDURE(SIGNED TabFeq),VIRTUAL
SwitchBold                      PROCEDURE(SIGNED TabFeq)
TakeEvent                       PROCEDURE,VIRTUAL
TakeNewSelection                PROCEDURE
UpdateTabs                      PROCEDURE(SIGNED NotifyThread,LONG NotifyParameter),VIRTUAL
                              END

UltimateMdiTabsWindow         CLASS,TYPE,MODULE('UltimateMdiTabs.clw'),LINK('UltimateMdiTabs.clw',_ABCLinkMode_),DLL(_ABCDllMode_)
Window                          &WINDOW,PROTECTED
Construct                       PROCEDURE
Destruct                        PROCEDURE
Init                            PROCEDURE(<*WINDOW Window>)
ProvideProp                     PROCEDURE(LONG Prop),STRING,PROTECTED
ProvideIcon                     PROCEDURE,STRING,VIRTUAL
ProvideText                     PROCEDURE,STRING,VIRTUAL
SetIconText                     PROCEDURE(<STRING Icon>,<STRING Text>)
HideTab                         PROCEDURE
UnhideTab                       PROCEDURE
TakeEvent                       PROCEDURE
                              END
