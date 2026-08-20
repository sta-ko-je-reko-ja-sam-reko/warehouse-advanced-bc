namespace WarehouseAdvanced.Telemetry;

using System.Telemetry;

codeunit 50850 "WHA Telemetry"
{
    Access = Public;

    var
        RunEventIdTok: Label 'WHA0001', Locked = true;
        SkippedEventIdTok: Label 'WHA0002', Locked = true;
        RunFinishedTok: Label 'Scheduled run finished', Locked = true;
        RunSkippedTok: Label 'Scheduled run did nothing', Locked = true;
        HandledDimTok: Label 'WhaHandled', Locked = true;
        RunDimTok: Label 'WhaRun', Locked = true;
        ReasonDimTok: Label 'WhaReason', Locked = true;

    /// <summary>
    /// Records that a scheduled run finished, and how much it did.
    /// </summary>
    /// <remarks>
    /// Five features and the integration spine are designed to be pointed at by a job queue entry and to
    /// run with nobody watching. Before this, a run that did nothing every night for a month looked
    /// exactly like a run that was working, and the only trace of a failure was the error text on the
    /// job queue entry itself — which nobody reads until somebody notices the stock is wrong.
    /// </remarks>
    /// <param name="FeatureName">The feature the run belongs to.</param>
    /// <param name="RunName">What the run does, in a word or two.</param>
    /// <param name="Handled">How many things the run dealt with. Zero is a finding, not a failure.</param>
    procedure LogScheduledRun(FeatureName: Text; RunName: Text; Handled: Integer)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUsage(RunEventIdTok, FeatureName, RunFinishedTok, RunDimensions(RunName, Handled));
    end;

    /// <summary>
    /// Records that a scheduled run stopped before doing anything, and why. A run that refuses is not the
    /// same as a run that found nothing, and telling them apart from the outside is the whole point.
    /// </summary>
    /// <param name="FeatureName">The feature the run belongs to.</param>
    /// <param name="RunName">What the run does, in a word or two.</param>
    /// <param name="Reason">Why it stopped. A fixed phrase, never anything read out of the data.</param>
    procedure LogRunSkipped(FeatureName: Text; RunName: Text; Reason: Text)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUsage(SkippedEventIdTok, FeatureName, RunSkippedTok, SkipDimensions(RunName, Reason));
    end;

    /// <summary>
    /// Builds the custom dimensions a finished run is reported with. Kept apart from the emitting so that
    /// what leaves this tenant can be asserted by a test without a telemetry endpoint to read.
    /// </summary>
    /// <param name="RunName">What the run does.</param>
    /// <param name="Handled">How many things the run dealt with.</param>
    /// <returns>The dimensions, carrying nothing but the run's name and a count.</returns>
    procedure RunDimensions(RunName: Text; Handled: Integer): Dictionary of [Text, Text]
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add(RunDimTok, RunName);
        Dimensions.Add(HandledDimTok, Format(Handled, 0, 9));
        exit(Dimensions);
    end;

    /// <summary>
    /// Builds the custom dimensions a skipped run is reported with.
    /// </summary>
    /// <param name="RunName">What the run does.</param>
    /// <param name="Reason">Why it stopped.</param>
    /// <returns>The dimensions, carrying nothing but the run's name and a fixed reason.</returns>
    procedure SkipDimensions(RunName: Text; Reason: Text): Dictionary of [Text, Text]
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add(RunDimTok, RunName);
        Dimensions.Add(ReasonDimTok, Reason);
        exit(Dimensions);
    end;
}
