{
   Renames a CK-defined property. This alters Papyrus data on an object, 
   which is an entirely different thing from altering the Papyrus script 
   itself.
   
   Created by DavidJCobb.
}
Unit CobbSingleRenamePapyrusProperty;
Uses 'Skyrim - Papyrus Resource Library';
Uses 'CobbTES5EditUtil';

var
   rePropRegex: TPerlRegEx;
   sScriptTarget: String;
   sPropertyOldName: String;
   sPropertyNewName: String;

Function Initialize: integer;
Var
   slResult: TStringList;
Begin
   rePropRegex := TPerlRegEx.Create;
   rePropRegex.Options := [preCaseLess, preMultiLine, preSingleLine];
   rePropRegex.RegEx := '^[\w\[\]]+\sProperty\s(\w+)(.*?)$';
   rePropRegex.Study;
   slResult := PromptFor3Strings('Options', 'Modify property on what script? (Leave blank to modify properties on all found scripts; be careful when doing that!)', 'What CK-defined property do you want to rename?', 'What name should we give the property?');
   If slResult.Count = 0 Then Begin
      Result := 1;
      Exit;
   End Else Begin
      sScriptTarget := slResult[0];
      sPropertyOldName := slResult[1];
      sPropertyNewName := slResult[2];
   End;
End;

Function Process(aeForm: IInterface) : Integer;
Var
   eVMAD: IInterface;
   eScripts: IInterface;
   iCurrentScript: Integer;
   eCurrentScript: IInterface;
Begin
   If ElementType(aeForm) = etMainRecord Then
      eVMAD := ElementBySignature(aeForm, 'VMAD');
      If Assigned(eVMAD) Then Begin
         If sScriptTarget <> '' Then Begin
            RenamePropertyOnScript(GetScript(aeForm, sScriptTarget) , sPropertyOldName, sPropertyNewName);
         End Else Begin
            //
            // Manually loop through all scripts.
            //
            eScripts := ElementByPath(eVMAD, 'Data\Scripts');
            If Signature(aeForm) = 'QUST' Then eScripts := ElementByPath(eVMAD, 'Data\Quest VMAD\Scripts');
            For iCurrentScript := 0 To ElementCount(eScripts) - 1 Do Begin
               eCurrentScript := ElementByIndex(eScripts, iCurrentScript);
               RenamePropertyOnScript(eCurrentScript, sPropertyOldName, sPropertyNewName);
            End;
         End;
      End;
End;

End.