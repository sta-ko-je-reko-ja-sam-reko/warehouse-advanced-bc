namespace WarehouseAdvanced.Analytics;

using System.Environment.Configuration;
using WarehouseAdvanced.Core;

codeunit 50703 "WHA KPI App Area Sub."
{
    Access = Internal;
    SingleInstance = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt. Facade", OnGetEssentialExperienceAppAreas, '', true, true)]
    local procedure SetAppAreasOnGetEssentialExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
        TempApplicationAreaSetup."WHA Analytics" := FeatureMgt.IsEnabled(Enum::"WHA Feature"::WHAAnalytics);
    end;

    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
}
