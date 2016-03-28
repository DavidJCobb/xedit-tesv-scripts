{
   Attach a script to the selected forms.
   
   Created by DavidJCobb.
}
Unit CobbSingleAttachScript;
Uses 'Skyrim - Papyrus Resource Library';
Uses 'CobbTES5EditUtil';

Var
   gsScriptToAdd: String;
   gbRedundantAdd: Boolean; // Add redundant scripts to all objects?

Function Initialize: integer;
Var
   sInput: String;
Begin
   //
   // Ask the user what to do.
   //
   If Not PromptForString('Add what script to the objects?', 'Add what script to the objects?', gsScriptToAdd) Then Begin
      Result := 1;
      Exit;
   End;
   //gbRedundantAdd := False;
   //PromptForString('Add redundant script?', 'Add the script to objects that already have it (Y), or just objects that don''t (any other input)?', sInput);
   //If (sInput = 'Y') Or (sInput = 'y') Then gbRedundantAdd := True;
   gbRedundantAdd := UIConfirm('Add redundant script?','Add the script to objects that already have it, or just ones that don''t?','Yes','No');
End;

Function Process(aeElement: IInterface) : Integer;
Begin
   If ElementType(aeElement) = etMainRecord Then AttachScript(aeElement, gsScriptToAdd, gbRedundantAdd);
End;

End.