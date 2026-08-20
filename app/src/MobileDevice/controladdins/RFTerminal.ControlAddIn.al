namespace WarehouseAdvanced.MobileDevice;

controladdin "WHA RF Terminal"
{
    Scripts = 'src/MobileDevice/js/rfterminal.js';
    StyleSheets = 'src/MobileDevice/css/rfterminal.css';
    StartupScript = 'src/MobileDevice/js/rfterminalstart.js';

    RequestedHeight = 640;
    MinimumHeight = 420;
    MaximumHeight = 900;
    RequestedWidth = 460;
    MinimumWidth = 300;
    VerticalStretch = true;
    HorizontalStretch = true;

    /// <summary>
    /// Draws the whole terminal from one state document. Everything the operator sees is in it, and the
    /// add-in decides nothing: which step they are on, what the instruction says, whether a scan is
    /// wanted and what a wrong scan was told are all worked out in AL and sent here to be shown.
    /// </summary>
    /// <param name="StateJson">The state document, built by `WHA RF Terminal State`.</param>
    procedure Render(StateJson: Text);

    /// <summary>
    /// Puts the cursor back in the scan box. A handheld that loses focus stops accepting the scanner,
    /// which reads to an operator as the device being broken.
    /// </summary>
    procedure FocusScan();

    /// <summary>
    /// Raised once the add-in has loaded and can be drawn on.
    /// </summary>
    event Ready();

    /// <summary>
    /// Raised when something has been scanned or typed into the scan box.
    /// </summary>
    /// <param name="ScannedValue">What came off the scanner.</param>
    event Scanned(ScannedValue: Text);

    /// <summary>
    /// Raised when the operator asks for the next job.
    /// </summary>
    event NextTaskRequested();

    /// <summary>
    /// Raised when the operator confirms the job they are holding.
    /// </summary>
    event ConfirmRequested();

    /// <summary>
    /// Raised when the operator says there was less on the shelf than the job asked for.
    /// </summary>
    event ShortPickRequested();

    /// <summary>
    /// Raised when the operator gives the job back to the queue.
    /// </summary>
    event HandBackRequested();
}
