namespace WarehouseAdvanced.QualityHold;

using System.Environment.Configuration;
using WarehouseAdvanced.Core;

codeunit 50553 "WHA QC App Area Sub."
{
    Access = Internal;
    SingleInstance = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt. Facade", OnGetEssentialExperienceAppAreas, '', true, true)]
    local procedure SetAppAreasOnGetEssentialExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
        TempApplicationAreaSetup."WHA Quality Hold" := FeatureMgt.IsEnabled(Enum::"WHA Feature"::WHAQualityHold);
    end;

    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
}
