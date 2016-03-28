{
   Remove a script from the selected forms.
   
   Limit of 512 scripts per form per run, but I seriously doubt you have 
   513 of the same script attached to a single form, so that shouldn't be 
   an issue.
   
   Created by DavidJCobb.
}
Unit CobbSingleRemoveScript;
Uses 'Skyrim - Papyrus Resource Library';
Uses 'CobbTES5EditUtil';

var
   sScriptToRemove: String;

Function Initialize: integer;
Var
   sInput: String;
Begin
   //
   // Ask the user what to do.
   //
   If Not PromptForString('Delete what script from the objects?', 'Delete what script from the objects?', sScriptToRemove) Then Begin
      Result := 1;
      Exit;
   End;
End;

Function Process(e: IInterface) : Integer;
Begin
   If ElementType(e) = etMainRecord Then
      If ElementExists(e, 'VMAD') Then RemoveScript(e, sScriptToRemove);
End;

End.