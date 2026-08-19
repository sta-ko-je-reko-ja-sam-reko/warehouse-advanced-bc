namespace WarehouseAdvanced.Slotting;

using System.Environment.Configuration;
using WarehouseAdvanced.Core;

codeunit 50303 "WHA Slot. App Area Sub."
{
    Access = Internal;
    SingleInstance = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt. Facade", OnGetEssentialExperienceAppAreas, '', true, true)]
    local procedure SetAppAreasOnGetEssentialExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
        TempApplicationAreaSetup."WHA Slotting" := FeatureMgt.IsEnabled(Enum::"WHA Feature"::WHASlotting);
    end;

    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
}
