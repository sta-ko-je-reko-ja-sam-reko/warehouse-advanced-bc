namespace WarehouseAdvanced.WaveManagement;

enum 50151 "WHA Wave Strategy" implements "WHA IWaveStrategy"
{
    Caption = 'Wave strategy';
    Extensible = true;
    DefaultImplementation = "WHA IWaveStrategy" = "WHA Wave Default Strategy";

    value(0; WHAMostUrgent)
    {
        Caption = 'Most urgent first';
        Implementation = "WHA IWaveStrategy" = "WHA Wave Default Strategy";
    }
    value(1; WHADueFirst)
    {
        Caption = 'Due first';
        Implementation = "WHA IWaveStrategy" = "WHA Wave Due Strategy";
    }
}
