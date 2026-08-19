namespace WarehouseAdvanced.HandlingUnit;

using System.Environment.Configuration;
using WarehouseAdvanced.Core;

codeunit 50052 "WHA HU App Area Sub."
{
    Access = Internal;
    SingleInstance = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt. Facade", OnGetEssentialExperienceAppAreas, '', true, true)]
    local procedure SetAppAreasOnGetEssentialExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
        TempApplicationAreaSetup."WHA Handling Units" := FeatureMgt.IsEnabled(Enum::"WHA Feature"::WHAHandlingUnits);
    end;

    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
}
