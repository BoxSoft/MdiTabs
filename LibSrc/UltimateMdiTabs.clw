                              MEMBER

  INCLUDE('UltimateMdiTabs.inc'),ONCE
  INCLUDE('Errors.clw'),ONCE
  INCLUDE('CWSynchC.inc'),ONCE
  INCLUDE('CWSynchM.inc'),ONCE

                              MAP
                                INCLUDE('STDebug.inc')
                              END

!==============================================================================
                              ITEMIZE(1)
NOTIFY:UpdateTabs               EQUATE
NOTIFY:DestroyTab               EQUATE
                              END

!==============================================================================
IsDead                        BOOL(FALSE)

!==============================================================================
StackQ                        QUEUE,TYPE
Icon                            STRING(FILE:MaxFilePath)
Text                            STRING(1000)
                              END

ThreadQ                       QUEUE
Thread                          SIGNED
TabFeq                          SIGNED
IsHidden                        BOOL
Icon                            STRING(FILE:MaxFilePath)
Text                            STRING(1000)
StackQ                          &StackQ
                              END

!==============================================================================
Sync                          CLASS
Sync                            &ICriticalSection
FrameThread                     SIGNED
ActiveThread                    SIGNED
Construct                       PROCEDURE
Destruct                        PROCEDURE
DeleteThreadQ                   PROCEDURE
FreeQueues                      PROCEDURE
FetchThreadQ                    PROCEDURE(<SIGNED ThreadNo>),BYTE,PROC
Wait                            PROCEDURE
Release                         PROCEDURE

StartThread                     PROCEDURE
StopThread                      PROCEDURE
SetActiveThread                 PROCEDURE(SIGNED Thread)
SetFrameThread                  PROCEDURE(SIGNED Thread)

Push                            PROCEDURE
Pop                             PROCEDURE

SetIconText                     PROCEDURE(<STRING Icon>,<STRING Text>)
SetIcon                         PROCEDURE(STRING Icon)
SetText                         PROCEDURE(STRING Text)
HideTab                         PROCEDURE(BOOL IsHidden=TRUE)
UnhideTab                       PROCEDURE
GainFocus                       PROCEDURE

UpdateTabs                      PROCEDURE
                              END

!==============================================================================
ThreadInstance                CLASS,THREAD
Construct                       PROCEDURE
Destruct                        PROCEDURE
                              END

!==============================================================================
!==============================================================================
Sync.Construct                PROCEDURE
  CODE
  SELF.Sync &= NewCriticalSection()
  
!==============================================================================
Sync.Destruct                 PROCEDURE
  CODE
  SELF.FreeQueues()
  IsDead = TRUE
  SELF.Sync.Kill()
  
!==============================================================================
Sync.DeleteThreadQ            PROCEDURE
!Assume CS in effect
  CODE
  IF IsDead THEN RETURN.
  FREE(ThreadQ.StackQ)
  DISPOSE(ThreadQ.StackQ)
  DELETE(ThreadQ)
  
!==============================================================================
Sync.FreeQueues               PROCEDURE
  CODE
  IF IsDead THEN RETURN.
  Sync.Wait()
  DO FreeThreadQ
  Sync.Release()
  
FreeThreadQ                  ROUTINE
  LOOP WHILE RECORDS(ThreadQ)
    GET(ThreadQ, 1)
    SELF.DeleteThreadQ()
  END
  
!==============================================================================
Sync.FetchThreadQ             PROCEDURE(<SIGNED ThreadNo>)!,BYTE
CP                              CriticalProcedure
  CODE
  IF IsDead THEN RETURN Level:Fatal.
  CP.Init(SELF.Sync)

  ThreadQ.Thread = CHOOSE(NOT OMITTED(ThreadNo), ThreadNo, THREAD())
  GET(ThreadQ, ThreadQ.Thread)
  RETURN CHOOSE(ERRORCODE()=NoError, Level:Benign, Level:Notify)
                  
!==============================================================================
Sync.Wait                     PROCEDURE
  CODE
  IF IsDead THEN RETURN.
  SELF.Sync.Wait()
  
!==============================================================================
Sync.Release                  PROCEDURE
  CODE
  IF IsDead THEN RETURN.
  SELF.Sync.Release()
  
!==============================================================================
Sync.StartThread              PROCEDURE
  CODE
  IF IsDead THEN RETURN.
  SELF.Sync.Wait()
  
  SELF.SetActiveThread(THREAD())
  
  CLEAR(ThreadQ)
  ThreadQ.Thread  = THREAD()
  ThreadQ.StackQ &= NEW StackQ
  ADD(ThreadQ, ThreadQ.Thread)
  
  SELF.Sync.Release()
  
!==============================================================================
Sync.StopThread               PROCEDURE
  CODE
  IF IsDead THEN RETURN.
  SELF.Sync.Wait()

  ThreadQ.Thread = THREAD()
  GET(ThreadQ, ThreadQ.Thread)
  IF ERRORCODE() = NoError
    DO TellFrameToDestroyTab
    SELF.DeleteThreadQ()
  END

  SELF.Sync.Release()

TellFrameToDestroyTab         ROUTINE
  IF SELF.FrameThread <> 0
    NOTIFY(NOTIFY:DestroyTab, SELF.FrameThread, ThreadQ.TabFeq)
  END

!==============================================================================
Sync.SetActiveThread          PROCEDURE(SIGNED Thread)
  CODE
  IF IsDead THEN RETURN.
  SELF.Sync.Wait()

  SELF.ActiveThread = Thread
  SELF.UpdateTabs()
  
  SELF.Sync.Release()

!==============================================================================
Sync.SetFrameThread           PROCEDURE(SIGNED Thread)
  CODE
  IF IsDead THEN RETURN.
  SELF.Sync.Wait()
  SELF.FrameThread = Thread
  SELF.Sync.Release()

!==============================================================================
Sync.Push                     PROCEDURE
  CODE
  IF IsDead THEN RETURN.
  SELF.Sync.Wait()

  IF SELF.FetchThreadQ() <> Level:Benign
    ASSERT(False, 'Missing thread #'& THREAD() &' for UltimateMdiTabs/Sync.Push')
  ELSE
    CLEAR(ThreadQ.StackQ)
    ThreadQ.StackQ.Icon = ThreadQ.Icon
    ThreadQ.StackQ.Text = ThreadQ.Text
    ADD(ThreadQ.StackQ)
  END

  SELF.Sync.Release()
  
!==============================================================================
Sync.Pop                      PROCEDURE
  CODE
  IF IsDead THEN RETURN.
  SELF.Sync.Wait()

  IF SELF.FetchThreadQ() <> Level:Benign
    ASSERT(False, 'Missing thread #'& THREAD() &' for UltimateMdiTabs/Sync.Push')
  ELSIF RECORDS(ThreadQ.StackQ) = 0
    ASSERT(False, 'No StackQ records for UltimateMdiTabs/Sync.Push')
  ELSE
    GET(ThreadQ.StackQ, RECORDS(ThreadQ.StackQ))

    ThreadQ.Icon = ThreadQ.StackQ.Icon
    ThreadQ.Text = ThreadQ.StackQ.Text
    PUT(ThreadQ)

    DELETE(ThreadQ.StackQ)
  END

  SELF.Sync.Release()
  
!==============================================================================
Sync.SetIconText              PROCEDURE(<STRING Icon>,<STRING Text>)
  CODE
  IF OMITTED(Icon) AND OMITTED(Text) THEN RETURN.
  
  IF IsDead THEN RETURN.
  SELF.Sync.Wait()

  IF SELF.FetchThreadQ() = Level:Benign
    IF NOT OMITTED(Icon) THEN ThreadQ.Icon = Icon.
    IF NOT OMITTED(Text) THEN ThreadQ.Text = Text.
    PUT(ThreadQ)
    SELF.UpdateTabs()
  END

  SELF.Sync.Release()

!==============================================================================
Sync.SetIcon                  PROCEDURE(STRING Icon)
  CODE
  SELF.SetIconText(Icon)

!==============================================================================
Sync.SetText                  PROCEDURE(STRING Text)
  CODE
  SELF.SetIconText(, Text)

!==============================================================================
Sync.HideTab                  PROCEDURE(BOOL IsHidden=TRUE)
  CODE
  IF IsDead THEN RETURN.
  SELF.Sync.Wait()

  IF SELF.FetchThreadQ() = Level:Benign
    ThreadQ.IsHidden = IsHidden
    PUT(ThreadQ)
    SELF.UpdateTabs()
  END

  SELF.Sync.Release()
  
!==============================================================================
Sync.UnhideTab                PROCEDURE
  CODE
  SELF.HideTab(FALSE)
  
!==============================================================================
Sync.GainFocus                PROCEDURE
  CODE
  SELF.SetActiveThread(THREAD())
  
!==============================================================================
Sync.UpdateTabs     PROCEDURE
  CODE
  IF SELF.FrameThread = 0 THEN RETURN.
  NOTIFY(NOTIFY:UpdateTabs, SELF.FrameThread)
  
!==============================================================================
!==============================================================================
ThreadInstance.Construct      PROCEDURE
  CODE
  IF THREAD() <> 1
    Sync.StartThread()
  END

!==============================================================================
ThreadInstance.Destruct       PROCEDURE
  CODE
  IF THREAD() <> 1
    Sync.StopThread()
  END
  
!==============================================================================
!==============================================================================
UltimateMdiTabsFrame.Init     PROCEDURE(*WINDOW Window,SIGNED SheetFeq)
  CODE
  SELF.Window                &= Window
  SELF.SheetFeq               = SheetFeq
  SELF.SheetFeq{PROP:NoSheet} = TRUE
  Sync.SetFrameThread(THREAD())

!==============================================================================
UltimateMdiTabsFrame.DestroyTab   PROCEDURE(SIGNED TabFeq)
  CODE
  IF TabFeq <> 0 AND TabFeq{PROP:Type} = CREATE:Tab
    DESTROY(TabFeq)
  END

!==============================================================================
UltimateMdiTabsFrame.SwitchBold  PROCEDURE(SIGNED TabFeq)
  CODE
  IF SELF.BoldTabFeq <> 0 AND SELF.BoldTabFeq{PROP:Type} = CREATE:Tab
    SELF.BoldTabFeq{PROP:Font, 4} = BXOR(SELF.BoldTabFeq{PROP:Font, 4}, FONT:Bold)
  END
  TabFeq{PROP:Font, 4} = BOR(TabFeq{PROP:Font, 4}, FONT:Bold)
  SELF.BoldTabFeq = TabFeq

!==============================================================================
UltimateMdiTabsFrame.TakeEvent    PROCEDURE
NotifyCode                          UNSIGNED
NotifyThread                        SIGNED
NotifyParameter                     LONG
  CODE
  ST::Debug('UltimateMdiTabsFrame.TakeEvent : ' & ST::DebugEventName())
  CASE EVENT()
  OF EVENT:Notify
    NOTIFICATION(NotifyCode, NotifyThread, NotifyParameter)
    CASE NotifyCode
      ;OF NOTIFY:UpdateTabs;  SELF.UpdateTabs(NotifyThread, NotifyParameter)
      ;OF NOTIFY:DestroyTab;  SELF.DestroyTab(NotifyParameter)
    END
  OF EVENT:NewSelection
    IF FIELD() = SELF.SheetFeq
      SELF.TakeNewSelection()
    END
  END

!==============================================================================
UltimateMdiTabsFrame.TakeNewSelection PROCEDURE
TabFeq                                  SIGNED,AUTO
NewActiveThread                         SIGNED(0)
  CODE
  TabFeq = SELF.SheetFeq{PROP:Child, Choice(SELF.SheetFeq)}  !SELF.SheetFeq{PROP:ChoiceFEQ} doesn't work, but this does. Thanks, Carl Barnes!
  DO FindNewActiveThread
  IF NewActiveThread
    DO ActivateNewThread
  END

FindNewActiveThread           ROUTINE
  Sync.Wait()
  ThreadQ.TabFeq = TabFeq
  GET(ThreadQ, ThreadQ.TabFeq)
  IF ERRORCODE() = NoError AND ThreadQ.Thread <> SYSTEM{PROP:Active}
    NewActiveThread = ThreadQ.Thread
  END
  Sync.Release()

ActivateNewThread             ROUTINE
  SETTARGET(, NewActiveThread)
  0{PROP:Active} = True
  SETTARGET()

!==============================================================================
UltimateMdiTabsFrame.UpdateTabs   PROCEDURE(SIGNED NotifyThread,LONG NotifyParameter)
ThreadIndex                         SIGNED,AUTO
ActiveThread                        SIGNED,AUTO
  CODE
  Sync.Wait()
      
  ActiveThread = SYSTEM{PROP:Active}
  
  LOOP ThreadIndex = 1 TO RECORDS(ThreadQ)
    GET(ThreadQ, ThreadIndex)
                            
    IF ThreadQ.Text = '' OR ThreadQ.IsHidden
      DO HideTab
    ELSIF ThreadQ.Text <> ''
      DO UnhideTab
      IF ActiveThread = ThreadQ.Thread
        DO SelectTab
      END
      DO SetTabText
    END
  END
  Sync.Release()

HideTab                       ROUTINE
  IF ThreadQ.TabFeq <> 0 |
      AND NOT ThreadQ.TabFeq{PROP:Hide}
    ThreadQ.TabFeq{PROP:Hide} = TRUE
  END

UnhideTab                     ROUTINE
  IF ThreadQ.TabFeq = 0
    DO CreateTab
  END
  IF ThreadQ.TabFeq{PROP:Hide}
    ThreadQ.TabFeq{PROP:Hide} = FALSE
  END

CreateTab                     ROUTINE
  ThreadQ.TabFeq = CREATE(0, CREATE:Tab, SELF.SheetFeq)
  ThreadQ.TabFeq{PROP:Hide} = FALSE
  PUT(ThreadQ)
  SELF.SwitchBold(ThreadQ.TabFeq)
  !STOP(ThreadQ.TabFeq)

SelectTab                     ROUTINE
  IF SELF.SheetFeq{PROP:ChoiceFEQ} <> ThreadQ.TabFeq
    SELF.SheetFeq{PROP:ChoiceFEQ} = ThreadQ.TabFeq
    SELF.SwitchBold(ThreadQ.TabFeq)
  END

SetTabText                    ROUTINE
  IF ThreadQ.TabFeq{PROP:Text} <> ThreadQ.Text
    ThreadQ.TabFeq{PROP:Icon} = ThreadQ.Icon
    ThreadQ.TabFeq{PROP:Text} = ThreadQ.Text
  END

!==============================================================================
!==============================================================================
UltimateMdiTabsWindow.Construct   PROCEDURE
  CODE
  Sync.Push()
  
!==============================================================================
UltimateMdiTabsWindow.Destruct    PROCEDURE
  CODE
  Sync.Pop()
  
!==============================================================================
UltimateMdiTabsWindow.Init    PROCEDURE(<*WINDOW Window>)
  CODE
  IF OMITTED(Window)
    SELF.Window &= NULL
  ELSE
    SELF.Window &= Window
  END

!==============================================================================
UltimateMdiTabsWindow.ProvideProp PROCEDURE(LONG Prop)!,STRING
  CODE
  IF SELF.Window &= NULL
    RETURN 0{Prop}
  ELSE
    RETURN SELF.Window{Prop}
  END
  
!==============================================================================
UltimateMdiTabsWindow.ProvideIcon PROCEDURE!,STRING
  CODE
  RETURN Self.ProvideProp(PROP:Icon)
  
!==============================================================================
UltimateMdiTabsWindow.ProvideText PROCEDURE!,STRING
  CODE
  RETURN Self.ProvideProp(PROP:Text)
  
!==============================================================================
UltimateMdiTabsWindow.SetIconText PROCEDURE(<STRING Icon>,<STRING Text>)
  CODE
  IF OMITTED(Icon)
    IF OMITTED(Text)
      Sync.SetIconText(SELF.ProvideIcon(), SELF.ProvideText())
    ELSE
      Sync.SetIconText(SELF.ProvideIcon(), Text)
    END
  ELSE
    IF OMITTED(Text)
      Sync.SetIconText(Icon, SELF.ProvideText())
    ELSE
      Sync.SetIconText(Icon, Text)
    END
  END
  
!==============================================================================
UltimateMdiTabsWindow.HideTab PROCEDURE
  CODE
  Sync.HideTab()
  
!==============================================================================
UltimateMdiTabsWindow.UnhideTab   PROCEDURE
  CODE
  Sync.UnhideTab()

!==============================================================================
UltimateMdiTabsWindow.TakeEvent   PROCEDURE
  CODE
  CASE EVENT()
  !OF EVENT:OpenWindow
  OF EVENT:GainFocus
    Sync.SetActiveThread(THREAD())
  END
  SELF.SetIconText()
  !ST::Debug('Event: '& ST::DebugEventName())
  
!==============================================================================
