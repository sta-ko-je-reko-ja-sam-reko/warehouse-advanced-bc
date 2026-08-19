namespace WarehouseAdvanced.DirectedWork;

using System.Environment.Configuration;
using WarehouseAdvanced.Core;

codeunit 50202 "WHA Task App Area Sub."
{
    Access = Internal;
    SingleInstance = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt. Facade", OnGetEssentialExperienceAppAreas, '', true, true)]
    local procedure SetAppAreasOnGetEssentialExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
        TempApplicationAreaSetup."WHA Directed Work" := FeatureMgt.IsEnabled(Enum::"WHA Feature"::WHADirectedWork);
    end;

    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
}
