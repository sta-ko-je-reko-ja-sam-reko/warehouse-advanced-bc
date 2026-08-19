namespace WarehouseAdvanced.Core;

using System.Environment.Configuration;

codeunit 50001 "WHA Feature Mgt."
{
    Access = Public;
    SingleInstance = true;

    var
        RestartMsg: Label 'The session will restart in #1 second(s) so that the changes take effect.', Comment = '#1 = the number of seconds remaining before the session restarts';
        FeatureDisabledErr: Label 'The %1 feature is not enabled. Enable it in the warehouse advanced setup before using it.', Comment = '%1 = the caption of the feature that is switched off';

    /// <summary>
    /// Determines whether a feature is switched on.
    /// </summary>
    /// <param name="Feature">The feature to test.</param>
    /// <returns>True when the feature is enabled.</returns>
    /// <remarks>
    /// Resolved through the feature enum's interface implementation, so a feature answers for itself and
    /// no branch is added here as features ship. The flag is safe to cache for the session because
    /// changing it restarts the session.
    /// </remarks>
    procedure IsEnabled(Feature: Enum "WHA Feature"): Boolean
    var
        FeatureSetup: Interface "WHA IFeatureSetup";
    begin
        FeatureSetup := Feature;
        exit(FeatureSetup.IsEnabled());
    end;

    /// <summary>
    /// Raises an error when a feature is switched off. Call from the write triggers of a feature's
    /// writable API pages, so the flag is authoritative across the UI and the API.
    /// </summary>
    /// <param name="Feature">The feature to test.</param>
    procedure CheckEnabled(Feature: Enum "WHA Feature")
    begin
        if not IsEnabled(Feature) then
            Error(FeatureDisabledErr, Format(Feature));
    end;

    /// <summary>
    /// Recomputes the application areas for the current company from the feature setups. Safe to call
    /// repeatedly. Does not restart the session.
    /// </summary>
    procedure RefreshExperienceAreas()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        ApplicationAreaMgmtFacade.RefreshExperienceTierCurrentCompany();
    end;

    /// <summary>
    /// Shows a countdown, then abandons the current session and starts a new one so that application area
    /// changes take effect. Must be the last client-facing call in any code path that uses it.
    /// </summary>
    procedure RestartSession()
    var
        SessionSetting: SessionSettings;
        RestartDialog: Dialog;
        Countdown: Integer;
    begin
        RestartDialog.Open(RestartMsg);
        for Countdown := 5 downto 1 do begin
            RestartDialog.Update(1, Countdown);
            Sleep(1000);
        end;
        RestartDialog.Close();

        SessionSetting.Init();
        SessionSetting.RequestSessionUpdate(true);
    end;

    /// <summary>
    /// Refreshes the application areas and restarts the session in one call. Used by the standalone setup
    /// page; the guided setup hub refreshes per step and restarts once instead.
    /// </summary>
    procedure ApplyExperienceChange()
    begin
        RefreshExperienceAreas();
        RestartSession();
    end;

    /// <summary>
    /// Builds a fingerprint of every feature's enabled state. Compare the value taken when a page opens
    /// with the value when it closes to decide whether a session restart is owed.
    /// </summary>
    /// <returns>A text fingerprint of the current enabled states.</returns>
    procedure GetEnabledFingerprint(): Text
    var
        Fingerprint: TextBuilder;
        Ordinal: Integer;
    begin
        foreach Ordinal in Enum::"WHA Feature".Ordinals() do
            Fingerprint.Append(Format(IsEnabled(Enum::"WHA Feature".FromInteger(Ordinal))));
        exit(Fingerprint.ToText());
    end;
}
