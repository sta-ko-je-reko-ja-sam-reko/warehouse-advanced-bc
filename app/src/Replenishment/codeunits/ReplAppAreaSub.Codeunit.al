namespace WarehouseAdvanced.Replenishment;

using System.Environment.Configuration;
using WarehouseAdvanced.Core;

codeunit 50252 "WHA Repl. App Area Sub."
{
    Access = Internal;
    SingleInstance = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt. Facade", OnGetEssentialExperienceAppAreas, '', true, true)]
    local procedure SetAppAreasOnGetEssentialExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
        TempApplicationAreaSetup."WHA Replenishment" := FeatureMgt.IsEnabled(Enum::"WHA Feature"::WHAReplenishment);
    end;

    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
}
