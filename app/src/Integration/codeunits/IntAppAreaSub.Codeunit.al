namespace WarehouseAdvanced.Integration;

using System.Environment.Configuration;
using WarehouseAdvanced.Core;

codeunit 50652 "WHA Int. App Area Sub."
{
    Access = Internal;
    SingleInstance = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt. Facade", OnGetEssentialExperienceAppAreas, '', true, true)]
    local procedure SetAppAreasOnGetEssentialExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
        TempApplicationAreaSetup."WHA Integration" := FeatureMgt.IsEnabled(Enum::"WHA Feature"::WHAIntegration);
    end;

    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
}
