namespace WarehouseAdvanced.Replenishment;

using Microsoft.Inventory.Item;

codeunit 50250 "WHA Repl. Rule Logic" implements "WHA IReplenishment"
{
    Access = Public;

    var
        MinimumAboveMaximumErr: Label 'The minimum quantity %1 is more than the maximum quantity %2. A rule cannot ask for a bin to be filled past what it is allowed to hold.', Comment = '%1 = the minimum quantity entered, %2 = the maximum quantity on the rule';

    /// <summary>
    /// Applies the defaults a new replenishment rule needs.
    /// </summary>
    /// <param name="ReplenishmentRule">The rule being inserted.</param>
    procedure Trigger_OnInsert(var ReplenishmentRule: Record "WHA Replenishment Rule")
    var
        Setup: Record "WHA Repl. Setup";
    begin
        Setup.SetLoadFields("Default Method", "Default Priority");
        if not Setup.Get() then
            exit;

        if ReplenishmentRule.Method = ReplenishmentRule.Method::WHABinContent then
            ReplenishmentRule.Method := Setup."Default Method";
        if ReplenishmentRule.Priority = 0 then
            ReplenishmentRule.Priority := Setup."Default Priority";
    end;

    /// <summary>
    /// Clears the variant and unit of measure when the item changes, then copies the base unit of
    /// measure from the item.
    /// </summary>
    /// <param name="ReplenishmentRule">The rule being validated.</param>
    /// <param name="xReplenishmentRule">The rule as it was before the change.</param>
    procedure Validate_ItemNo(var ReplenishmentRule: Record "WHA Replenishment Rule"; xReplenishmentRule: Record "WHA Replenishment Rule")
    var
        Item: Record Item;
    begin
        if ReplenishmentRule."Item No." = xReplenishmentRule."Item No." then
            exit;

        ReplenishmentRule."Variant Code" := '';
        ReplenishmentRule."Unit of Measure Code" := '';

        if ReplenishmentRule."Item No." = '' then
            exit;

        Item.SetLoadFields("Base Unit of Measure");
        if not Item.Get(ReplenishmentRule."Item No.") then
            exit;

        ReplenishmentRule."Unit of Measure Code" := Item."Base Unit of Measure";
    end;

    /// <summary>
    /// Refuses a minimum above the maximum.
    /// </summary>
    /// <param name="ReplenishmentRule">The rule being validated.</param>
    /// <param name="xReplenishmentRule">The rule as it was before the change.</param>
    procedure Validate_MinimumQuantity(var ReplenishmentRule: Record "WHA Replenishment Rule"; xReplenishmentRule: Record "WHA Replenishment Rule")
    begin
        if ReplenishmentRule."Minimum Quantity" = xReplenishmentRule."Minimum Quantity" then
            exit;

        CheckRange(ReplenishmentRule);
    end;

    /// <summary>
    /// Refuses a maximum below the minimum.
    /// </summary>
    /// <param name="ReplenishmentRule">The rule being validated.</param>
    /// <param name="xReplenishmentRule">The rule as it was before the change.</param>
    procedure Validate_MaximumQuantity(var ReplenishmentRule: Record "WHA Replenishment Rule"; xReplenishmentRule: Record "WHA Replenishment Rule")
    begin
        if ReplenishmentRule."Maximum Quantity" = xReplenishmentRule."Maximum Quantity" then
            exit;

        CheckRange(ReplenishmentRule);
    end;

    local procedure CheckRange(var ReplenishmentRule: Record "WHA Replenishment Rule")
    begin
        if ReplenishmentRule."Maximum Quantity" = 0 then
            exit;
        if ReplenishmentRule."Minimum Quantity" <= ReplenishmentRule."Maximum Quantity" then
            exit;

        Error(MinimumAboveMaximumErr, ReplenishmentRule."Minimum Quantity", ReplenishmentRule."Maximum Quantity");
    end;
}
