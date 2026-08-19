namespace WarehouseAdvanced.LabourManagement;

codeunit 50350 "WHA Labour Std. Logic" implements "WHA ILabourStandardRule"
{
    Access = Public;

    var
        NoTimeAtAllErr: Label 'A standard has to allow some time. Give the standard for %1 either minutes per job or minutes per unit.', Comment = '%1 = the kind of work the standard covers';

    /// <summary>
    /// Applies the defaults a new labour standard needs.
    /// </summary>
    /// <param name="LabourStandard">The standard being inserted.</param>
    procedure Trigger_OnInsert(var LabourStandard: Record "WHA Labour Standard")
    var
        Setup: Record "WHA Labour Setup";
    begin
        Setup.SetLoadFields("Default Basis");
        if not Setup.Get() then
            exit;

        if LabourStandard.Basis = LabourStandard.Basis::WHAFixedPlusUnit then
            LabourStandard.Basis := Setup."Default Basis";
    end;

    /// <summary>
    /// Refuses a standard of no time at all.
    /// </summary>
    /// <param name="LabourStandard">The standard being validated.</param>
    /// <param name="xLabourStandard">The standard as it was before the change.</param>
    procedure Validate_Minutes(var LabourStandard: Record "WHA Labour Standard"; xLabourStandard: Record "WHA Labour Standard")
    begin
        if (LabourStandard."Minutes Per Job" > 0) or (LabourStandard."Minutes Per Unit" > 0) then
            exit;
        if (xLabourStandard."Minutes Per Job" = 0) and (xLabourStandard."Minutes Per Unit" = 0) then
            exit;

        Error(NoTimeAtAllErr, LabourStandard."Task Type");
    end;
}
