namespace WarehouseAdvanced.Packing;

using System.Environment.Configuration;
using WarehouseAdvanced.Core;

codeunit 50402 "WHA Pack App Area Sub."
{
    Access = Internal;
    SingleInstance = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt. Facade", OnGetEssentialExperienceAppAreas, '', true, true)]
    local procedure SetAppAreasOnGetEssentialExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
        TempApplicationAreaSetup."WHA Packing" := FeatureMgt.IsEnabled(Enum::"WHA Feature"::WHAPacking);
    end;

    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
}
