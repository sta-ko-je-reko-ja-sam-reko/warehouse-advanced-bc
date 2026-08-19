namespace WarehouseAdvanced.LabourManagement;

using System.Environment.Configuration;
using WarehouseAdvanced.Core;

codeunit 50354 "WHA Lab. App Area Sub."
{
    Access = Internal;
    SingleInstance = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt. Facade", OnGetEssentialExperienceAppAreas, '', true, true)]
    local procedure SetAppAreasOnGetEssentialExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
        TempApplicationAreaSetup."WHA Labour Management" := FeatureMgt.IsEnabled(Enum::"WHA Feature"::WHALabourManagement);
    end;

    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
}
