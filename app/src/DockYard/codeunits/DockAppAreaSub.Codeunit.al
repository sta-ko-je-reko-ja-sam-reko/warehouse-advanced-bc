namespace WarehouseAdvanced.DockYard;

using System.Environment.Configuration;
using WarehouseAdvanced.Core;

codeunit 50453 "WHA Dock App Area Sub."
{
    Access = Internal;
    SingleInstance = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt. Facade", OnGetEssentialExperienceAppAreas, '', true, true)]
    local procedure SetAppAreasOnGetEssentialExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
        TempApplicationAreaSetup."WHA Dock Yard" := FeatureMgt.IsEnabled(Enum::"WHA Feature"::WHADockYard);
    end;

    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
}
