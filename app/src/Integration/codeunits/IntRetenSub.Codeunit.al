namespace WarehouseAdvanced.Integration;

using System.DataAdministration;

codeunit 50662 "WHA Int. Reten. Sub."
{
    Access = Internal;
    SingleInstance = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reten. Pol. Allowed Tables", OnRefreshAllowedTables, '', true, true)]
    local procedure AddMessageLogOnRefreshAllowedTables()
    var
        IntRetention: Codeunit "WHA Int. Retention";
    begin
        IntRetention.RegisterAllowedTable();
    end;
}
