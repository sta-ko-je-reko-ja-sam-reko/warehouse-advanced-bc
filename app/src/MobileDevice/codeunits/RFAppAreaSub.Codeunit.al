namespace WarehouseAdvanced.MobileDevice;

using System.Environment.Configuration;
using WarehouseAdvanced.Core;

codeunit 50102 "WHA RF App Area Sub."
{
    Access = Internal;
    SingleInstance = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt. Facade", OnGetEssentialExperienceAppAreas, '', true, true)]
    local procedure SetAppAreasOnGetEssentialExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
        TempApplicationAreaSetup."WHA Mobile Device" := FeatureMgt.IsEnabled(Enum::"WHA Feature"::WHAMobileDevice);
    end;

    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
}
