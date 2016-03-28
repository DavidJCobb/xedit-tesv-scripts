{
   Replace one substring with another in the selected forms' attached scripts' names.
   
   Created by DavidJCobb.
}
Unit CobbSingleReplaceInScriptNames;
Uses 'Skyrim - Papyrus Resource Library';
Uses 'CobbTES5EditUtil';

Var
   gsReplace: String;
   gsWith: String;
   giOperatedOnCount: Integer;

Function Initialize: integer;
Var
   sInput: String;
   slResult: TstringList;
   eKeyword: IInterface;
Begin
   //
   // Ask the user what to do.
   //
   slResult := PromptFor2Strings('Replace in script names', 'Replace what substring?', 'Replace it with?');
   If slResult.Count = 0 Then Begin
      Result := 1;
      Exit;
   End Else Begin
      gsReplace := slResult[0];
      gsWith := slResult[1];
   End;
End;

Procedure SearchAndReplace(aeElement: IInterface);
Var
  sFinal: String;
Begin
  If Not Assigned(aeElement) Then Exit;
  sFinal := StringReplace(GetEditValue(aeElement), gsReplace, gsWith, [rfReplaceAll, rfIgnoreCase]); // remove rfIgnoreCase to be case sensitive
  If Not SameText(sFinal, GetEditValue(aeElement)) Then Begin
    giOperatedOnCount := giOperatedOnCount + 1;
    AddMessage('Replacing in ' + FullPath(aeElement));
    SetEditValue(aeElement, sFinal);
  End;
End;

Function Process(e: IInterface) : Integer;
Var
   sElemName: String;
   eVMAD: IInterface;
   eScripts: IInterface;
   iCurrentScript: Integer;
   eCurrentScript: IInterface;
Begin
   If ElementType(e) = etMainRecord Then Begin
      eVMAD := ElementBySignature(e, 'VMAD');
      If Not Assigned(eVMAD) Then Exit;
      eScripts := ElementByPath(eVMAD, 'Data\Scripts');
      If Signature(e) = 'QUST' Then eScripts := ElementByPath(eVMAD, 'Data\Quest VMAD\Scripts');
      For iCurrentScript := 0 To ElementCount(eScripts) - 1 Do Begin
         eCurrentScript := ElementByIndex(eScripts, iCurrentScript);
         If Name(eCurrentScript) = 'Script' Then Begin
            SearchAndReplace(ElementByName(eCurrentScript, 'scriptName'));
         End;
      End;
   End;
End;

Function Finalize: Integer;
Begin
   AddMessage(Format('Replaced %d occurrences.', [giOperatedOnCount]));
End;

End.