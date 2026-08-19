namespace WarehouseAdvanced.WaveManagement;

using System.Environment.Configuration;
using WarehouseAdvanced.Core;

codeunit 50152 "WHA Wave App Area Sub."
{
    Access = Internal;
    SingleInstance = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt. Facade", OnGetEssentialExperienceAppAreas, '', true, true)]
    local procedure SetAppAreasOnGetEssentialExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
        TempApplicationAreaSetup."WHA Wave Management" := FeatureMgt.IsEnabled(Enum::"WHA Feature"::WHAWaveManagement);
    end;

    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
}
