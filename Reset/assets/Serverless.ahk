#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SetKeyDelay 20

^+a::
   send, (bool containsObject, string caption) = await PassesImageModerationAsync(image);{enter}
   Sleep, 500 ;<-- let the command settle
   send, inputDocument.IsApproved = containsObject && passesText;{enter}
   Sleep, 500 ;<-- let the command settle
   send, inputDocument.Caption = caption;{enter}
Return

^+b::
   send, Cute cat
Return