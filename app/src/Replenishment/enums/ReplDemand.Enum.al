namespace WarehouseAdvanced.Replenishment;

enum 50251 "WHA Repl. Demand" implements "WHA IReplDemand"
{
    Caption = 'Replenishment demand';
    Extensible = true;
    DefaultImplementation = "WHA IReplDemand" = "WHA Repl. No Demand";

    value(0; WHANone)
    {
        Caption = 'What is in the bin now';
        Implementation = "WHA IReplDemand" = "WHA Repl. No Demand";
    }
    value(1; WHAOutstandingPicks)
    {
        Caption = 'What is in the bin less what is already promised';
        Implementation = "WHA IReplDemand" = "WHA Repl. Pick Demand";
    }
    value(2; WHAWave)
    {
        Caption = 'What is in the bin less what one wave will take';
        Implementation = "WHA IReplDemand" = "WHA Repl. Wave Demand";
    }
}
