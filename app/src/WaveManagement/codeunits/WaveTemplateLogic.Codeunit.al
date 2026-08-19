namespace WarehouseAdvanced.WaveManagement;

codeunit 50157 "WHA Wave Template Logic" implements "WHA IWaveTemplate"
{
    Access = Public;

    var
        BlockedErr: Label 'Wave template %1 is blocked, so it builds nothing.', Comment = '%1 = the wave template code';
        LocationMissingErr: Label 'Give wave template %1 a location before running it, so the waves it builds gather work from one part of the warehouse.', Comment = '%1 = the wave template code';
        HasWavesErr: Label 'Wave template %1 has built %2 wave(s), so it cannot be deleted. Block it instead, so those waves still name something.', Comment = '%1 = the wave template code, %2 = how many waves it built';
        DescribeJobsLbl: Label '%1 at %2, up to %3 job(s).', Comment = '%1 = the strategy, %2 = the location code, %3 = how many jobs the wave takes';
        DescribeMinutesLbl: Label '%1 at %2, up to %3 job(s) or %4 minutes of work, whichever comes first.', Comment = '%1 = the strategy, %2 = the location code, %3 = how many jobs the wave takes, %4 = how many minutes of work the wave takes';
        DescribeReleaseLbl: Label ' The wave goes to the floor as soon as it is built.';
        DescribeHoldLbl: Label ' The wave waits for somebody to release it.';

    /// <summary>
    /// Refuses to delete a template that has already built waves.
    /// </summary>
    /// <param name="WaveTemplate">The template being deleted.</param>
    procedure Trigger_OnDelete(var WaveTemplate: Record "WHA Wave Template")
    var
        Wave: Record "WHA Wave";
    begin
        Wave.SetRange("Template Code", WaveTemplate."Code");
        if Wave.IsEmpty() then
            exit;

        Error(HasWavesErr, WaveTemplate."Code", Wave.Count());
    end;

    /// <summary>
    /// Builds a wave from the template, fills it, and releases it when the template says so. A run that
    /// gathers nothing leaves no wave behind.
    /// </summary>
    /// <param name="WaveTemplate">The template to build from.</param>
    /// <param name="Wave">Receives the wave that was built, when one was.</param>
    /// <returns>How many jobs the wave gathered.</returns>
    procedure CreateWave(var WaveTemplate: Record "WHA Wave Template"; var Wave: Record "WHA Wave"): Integer
    var
        WaveLogic: Codeunit "WHA Wave Logic";
        Gathered: Integer;
    begin
        if WaveTemplate.Blocked then
            Error(BlockedErr, WaveTemplate."Code");
        if WaveTemplate."Location Code" = '' then
            Error(LocationMissingErr, WaveTemplate."Code");

        Clear(Wave);
        Wave.Init();
        Wave.Description := WaveTemplate.Description;
        Wave."Location Code" := WaveTemplate."Location Code";
        Wave.Strategy := WaveTemplate.Strategy;
        Wave."Max Tasks" := WaveTemplate."Max Tasks";
        Wave."Max Minutes" := WaveTemplate."Max Minutes";
        Wave."Template Code" := WaveTemplate."Code";
        Wave.Insert(true);

        Gathered := WaveLogic.Fill(Wave);
        if Gathered = 0 then begin
            Wave.Delete(true);
            Clear(Wave);
            StampRun(WaveTemplate, '');
            exit(0);
        end;

        if WaveTemplate."Release Automatically" then
            WaveLogic.Release(Wave);

        StampRun(WaveTemplate, Wave."No.");
        exit(Gathered);
    end;

    /// <summary>
    /// Builds a wave from every template marked for the scheduled run.
    /// </summary>
    /// <param name="LocationCode">Limit the run to one location, or blank for every location.</param>
    /// <returns>How many waves were built and left behind.</returns>
    procedure RunScheduled(LocationCode: Code[10]): Integer
    var
        WaveTemplate: Record "WHA Wave Template";
        Wave: Record "WHA Wave";
        Built: Integer;
    begin
        WaveTemplate.SetCurrentKey(Scheduled, Blocked, "Location Code");
        WaveTemplate.SetRange(Scheduled, true);
        WaveTemplate.SetRange(Blocked, false);
        if LocationCode <> '' then
            WaveTemplate.SetRange("Location Code", LocationCode)
        else
            WaveTemplate.SetFilter("Location Code", '<>%1', '');
        if not WaveTemplate.FindSet() then
            exit(0);

        repeat
            if CreateWave(WaveTemplate, Wave) > 0 then
                Built += 1;
        until WaveTemplate.Next() = 0;

        exit(Built);
    end;

    /// <summary>
    /// Describes in one line what a template will build.
    /// </summary>
    /// <param name="WaveTemplate">The template to describe.</param>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(var WaveTemplate: Record "WHA Wave Template"): Text
    var
        Summary: Text;
    begin
        if WaveTemplate."Max Minutes" > 0 then
            Summary := StrSubstNo(DescribeMinutesLbl, WaveTemplate.Strategy, WaveTemplate."Location Code", WaveTemplate."Max Tasks", WaveTemplate."Max Minutes")
        else
            Summary := StrSubstNo(DescribeJobsLbl, WaveTemplate.Strategy, WaveTemplate."Location Code", WaveTemplate."Max Tasks");

        if WaveTemplate."Release Automatically" then
            exit(Summary + DescribeReleaseLbl);
        exit(Summary + DescribeHoldLbl);
    end;

    local procedure StampRun(var WaveTemplate: Record "WHA Wave Template"; WaveNo: Code[20])
    begin
        WaveTemplate."Last Run At" := CurrentDateTime;
        WaveTemplate."Last Wave No." := WaveNo;
        WaveTemplate.Modify(true);
    end;
}
