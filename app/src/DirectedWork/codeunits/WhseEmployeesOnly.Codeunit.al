namespace WarehouseAdvanced.DirectedWork;

using Microsoft.Warehouse.Setup;

codeunit 50215 "WHA Whse. Employees Only" implements "WHA IWhseAccessPolicy"
{
    Access = Public;

    var
        DescriptionLbl: Label 'Only somebody Business Central lists as a warehouse employee at that location can be given work there. This app then lets the same people work as Business Central''s own warehouse pages do.';
        NotAnEmployeeErr: Label '%1 is not a warehouse employee at location %2, so this job cannot be given to them. Add them on the Warehouse Employees page, or give the job to somebody who is.', Comment = '%1 = the user ID; %2 = the location code';
        NotAnEmployeeAnywhereErr: Label '%1 is not a warehouse employee at any location, so this job cannot be given to them. Add them on the Warehouse Employees page, or give the job to somebody who is.', Comment = '%1 = the user ID';

    /// <summary>
    /// Refuses a person Business Central would not let into that warehouse.
    /// </summary>
    /// <remarks>
    /// The list is read directly rather than through `WMS Management.CheckUserIsWhseEmployeeForLocation`,
    /// and that is deliberate. Business Central's own check offers to open the Warehouse Employees page
    /// and only errors if the answer is no — a dialog, which is fine on a page and wrong everywhere this
    /// runs: a handheld, an API call, a job queue. What is wanted here is the same rule with a plain
    /// refusal, so the rule is applied and the dialog is not.
    ///
    /// A job that does not yet say where the work happens is checked against **any** location, because
    /// somebody with no warehouse at all is wrong however the job ends up. Which location it turns out to
    /// be is checked when the job names one.
    /// </remarks>
    /// <param name="UserIdToCheck">The person the work is being given to.</param>
    /// <param name="LocationCode">Where the work happens. Blank when the job does not say yet.</param>
    procedure Check(UserIdToCheck: Code[50]; LocationCode: Code[10])
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        if UserIdToCheck = '' then
            exit;

        WarehouseEmployee.SetRange("User ID", UserIdToCheck);
        if LocationCode <> '' then
            WarehouseEmployee.SetRange("Location Code", LocationCode);
        if not WarehouseEmployee.IsEmpty() then
            exit;

        if LocationCode = '' then
            Error(NotAnEmployeeAnywhereErr, UserIdToCheck);
        Error(NotAnEmployeeErr, UserIdToCheck, LocationCode);
    end;

    /// <summary>
    /// Describes in one line who this policy lets work.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text
    begin
        exit(DescriptionLbl);
    end;
}
