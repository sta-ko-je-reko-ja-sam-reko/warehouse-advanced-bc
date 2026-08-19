namespace WarehouseAdvanced.Labelling;

using System.Environment.Configuration;
using WarehouseAdvanced.Core;

codeunit 50602 "WHA Label App Area Sub."
{
    Access = Internal;
    SingleInstance = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt. Facade", OnGetEssentialExperienceAppAreas, '', true, true)]
    local procedure SetAppAreasOnGetEssentialExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
        TempApplicationAreaSetup."WHA Labelling" := FeatureMgt.IsEnabled(Enum::"WHA Feature"::WHALabelling);
    end;

    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
}
