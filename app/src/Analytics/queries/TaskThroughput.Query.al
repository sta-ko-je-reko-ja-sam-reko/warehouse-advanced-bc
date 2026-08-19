namespace WarehouseAdvanced.Analytics;

using WarehouseAdvanced.DirectedWork;

query 50700 "WHA Task Throughput"
{
    QueryType = API;
    APIPublisher = 'matr';
    APIGroup = 'analytics';
    APIVersion = 'v1.0';
    EntityName = 'taskThroughput';
    EntitySetName = 'taskThroughputs';
    Caption = 'Task throughput';
    DataAccessIntent = ReadOnly;
    OrderBy = descending(taskCount);

    elements
    {
        dataitem(WarehouseTask; "WHA Warehouse Task")
        {
            column(locationCode; "Location Code")
            {
                Caption = 'Location code';
            }
            column(taskType; "Task Type")
            {
                Caption = 'Task type';
            }
            column(status; Status)
            {
                Caption = 'Status';
            }
            column(taskCount)
            {
                Caption = 'Task count';
                Method = Count;
            }
            column(quantity; Quantity)
            {
                Caption = 'Quantity';
                Method = Sum;
            }
            column(quantityHandled; "Quantity Handled")
            {
                Caption = 'Quantity handled';
                Method = Sum;
            }

            filter(completedDateTimeFilter; "Completed At")
            {
                Caption = 'Completed date time filter';
            }
        }
    }
}
