namespace WarehouseAdvanced.QualityHold;

enum 50553 "WHA Hold Stock Policy" implements "WHA IHoldStockPolicy"
{
    Caption = 'What a hold does to stock';
    Extensible = true;
    DefaultImplementation = "WHA IHoldStockPolicy" = "WHA Hold Records Only";

    value(0; WHARecordOnly)
    {
        Caption = 'Record the hold and nothing else';
    }
    value(1; WHABlockBin)
    {
        Caption = 'Block movement in the bin the goods stand in';
        Implementation = "WHA IHoldStockPolicy" = "WHA Hold Blocks Bin";
    }
    value(2; WHABlockLot)
    {
        Caption = 'Block the lot the goods belong to';
        Implementation = "WHA IHoldStockPolicy" = "WHA Hold Blocks Lot";
    }
}
