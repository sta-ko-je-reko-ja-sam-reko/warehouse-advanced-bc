namespace WarehouseAdvanced.WaveManagement;

interface "WHA IWaveTemplate"
{
    /// <summary>
    /// Refuses to delete a template that has already built waves, so the waves it built still name
    /// something. A template that is finished with is blocked, not removed.
    /// </summary>
    /// <param name="WaveTemplate">The template being deleted.</param>
    procedure Trigger_OnDelete(var WaveTemplate: Record "WHA Wave Template");

    /// <summary>
    /// Builds a wave from the template, fills it, and releases it when the template says so. A run that
    /// gathers nothing leaves no wave behind — an empty wave every morning is noise, not a record.
    /// </summary>
    /// <param name="WaveTemplate">The template to build from.</param>
    /// <param name="Wave">Receives the wave that was built, when one was.</param>
    /// <returns>How many jobs the wave gathered. Zero means no wave was left behind.</returns>
    procedure CreateWave(var WaveTemplate: Record "WHA Wave Template"; var Wave: Record "WHA Wave"): Integer;

    /// <summary>
    /// Builds a wave from every template marked for the scheduled run. This is what a job queue entry
    /// calls; when and how often it happens is set up there, because Business Central already knows how
    /// to schedule things and this feature should not learn.
    /// </summary>
    /// <param name="LocationCode">Limit the run to one location, or blank for every location.</param>
    /// <returns>How many waves were built and left behind.</returns>
    procedure RunScheduled(LocationCode: Code[10]): Integer;

    /// <summary>
    /// Describes in one line what a template will build, so whoever is about to run it can see what they
    /// are asking for.
    /// </summary>
    /// <param name="WaveTemplate">The template to describe.</param>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(var WaveTemplate: Record "WHA Wave Template"): Text;
}
