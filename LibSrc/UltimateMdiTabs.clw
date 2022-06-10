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
Text                            STRING(1000)
                              END

ThreadQ                       QUEUE
Thread                          SIGNED
TabFeq                          SIGNED
IsHidden                        BOOL
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

    ThreadQ.Text = ThreadQ.StackQ.Text
    PUT(ThreadQ)

    DELETE(ThreadQ.StackQ)
  END

  SELF.Sync.Release()
  
!==============================================================================
Sync.SetText                  PROCEDURE(STRING Text)
  CODE
  IF IsDead THEN RETURN.
  SELF.Sync.Wait()

  IF SELF.FetchThreadQ() = Level:Benign
    ThreadQ.Text = Text
    PUT(ThreadQ)
    SELF.UpdateTabs()
  END

  SELF.Sync.Release()

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
UltimateMdiTabsFrame.Init     PROCEDURE(SIGNED SheetFeq)
  CODE
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
NewActiveThread                         SIGNED(0)
ThreadIndex                             SIGNED,AUTO
  CODE
  Sync.Wait()

  ThreadQ.TabFeq = SELF.SheetFeq{PROP:ChoiceFEQ}
  !STOP(ThreadQ.TabFeq)
  GET(ThreadQ, ThreadQ.TabFeq)
  IF ERRORCODE() = NoError  |
      AND ThreadQ.Thread <> SYSTEM{PROP:Active}
    NewActiveThread = ThreadQ.Thread
  END

  Sync.Release()

  IF NewActiveThread <> 0
    SYSTEM{PROP:Active} = NewActiveThread
  END

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
  !STOP(ThreadQ.TabFeq)

SelectTab                     ROUTINE
  IF SELF.SheetFeq{PROP:ChoiceFEQ} <> ThreadQ.TabFeq
    SELF.SheetFeq{PROP:ChoiceFEQ} = ThreadQ.TabFeq
  END

SetTabText                    ROUTINE
  IF ThreadQ.TabFeq{PROP:Text} <> ThreadQ.Text
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
UltimateMdiTabsWindow.SetText PROCEDURE(<STRING Text>)
  CODE
  IF NOT OMITTED(Text)
    Sync.SetText(Text)
  ELSIF SELF.ManualText
    Sync.SetText(SELF.ManualText)
  ELSE
    Sync.SetText(0{PROP:Text})
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
  SELF.SetText()
  !ST::Debug('Event: '& ST::DebugEventName())
  
!==============================================================================
!UltimateMdiTabsWindow.GainFocus   PROCEDURE
!  CODE
!  Sync.SetActiveThread(THREAD())
  
!==============================================================================
!UltimateMdiTabsWindow.SetActiveThread PROCEDURE
!  CODE
  
!==============================================================================
