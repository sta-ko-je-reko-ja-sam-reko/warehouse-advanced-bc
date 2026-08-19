namespace WarehouseAdvanced.Counting;

using System.Environment.Configuration;
using WarehouseAdvanced.Core;

codeunit 50503 "WHA Count App Area Sub."
{
    Access = Internal;
    SingleInstance = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt. Facade", OnGetEssentialExperienceAppAreas, '', true, true)]
    local procedure SetAppAreasOnGetEssentialExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
        TempApplicationAreaSetup."WHA Counting" := FeatureMgt.IsEnabled(Enum::"WHA Feature"::WHACounting);
    end;

    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
}
