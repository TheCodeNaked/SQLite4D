unit MainForm;

interface

uses
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.Comp.DataSet,
  FireDAC.Comp.UI,
  FireDAC.DApt,
  FireDAC.DApt.Intf,
  FireDAC.DatS,
  FireDAC.FMXUI.Wait,
  FireDAC.Phys,
  FireDAC.Phys.Intf,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Phys.SQLiteWrapper.Stat,
  FireDAC.Stan.Async,
  FireDAC.Stan.Def,
  FireDAC.Stan.Error,
  FireDAC.Stan.ExprFuncs,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Param,
  FireDAC.Stan.Pool,
  FMX.Controls,
  FMX.Controls.Presentation,
  FMX.Dialogs,
  FMX.DialogService,
  FMX.Edit,
  FMX.Forms,
  FMX.Graphics,
  FMX.Memo,
  FMX.Memo.Types,
  FMX.Objects,
  FMX.ScrollBox,
  FMX.StdCtrls,
  FMX.Types,
  SQLite4D,
  System.Classes,
  System.Diagnostics,
  System.IOUtils,
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Variants;

type
  TFormMain = class(TForm)
    btnCreateDatabase: TButton;
    btnCreateTableCustomer: TButton;
    btnAddSimpleFields: TButton;
    btnAddSimpleIndex: TButton;
    btnAddCompositeIndex: TButton;
    btnDeleteAllIndex: TButton;
    btnDeleteTable: TButton;
    btnDeleteDatabase: TButton;
    btnCreateRelatedTables: TButton;
    btnViewDBStructure: TButton;
    btnRenameTable: TButton;
    btnAlterTableStructure: TButton;
    btnCreateFDMemTable: TButton;
    btnInsertData: TButton;
    btnCreateSQLiteTableFromFDMemTable: TButton;
    btnTransferData: TButton;
    btnViewRecords: TButton;
    rbCustomers: TRadioButton;
    rbUsers: TRadioButton;
    rbOrders: TRadioButton;
    rbOrderDetails: TRadioButton;
    rbSuppliers: TRadioButton;
    gbxDBSample: TGroupBox;
    gbxTableCustomer: TGroupBox;
    gbxRelatedTables: TGroupBox;
    gbxViewData: TGroupBox;
    MemoData: TMemo;
    GroupBox1: TGroupBox;
    procedure btnCreateDatabaseClick(Sender: TObject);
    procedure btnCreateTableCustomerClick(Sender: TObject);
    procedure btnAddSimpleFieldsClick(Sender: TObject);
    procedure btnAddSimpleIndexClick(Sender: TObject);
    procedure btnAddCompositeIndexClick(Sender: TObject);
    procedure btnDeleteAllIndexClick(Sender: TObject);
    procedure btnDeleteTableClick(Sender: TObject);
    procedure btnDeleteDatabaseClick(Sender: TObject);
    procedure btnCreateRelatedTablesClick(Sender: TObject);
    procedure btnViewDBStructureClick(Sender: TObject);
    procedure btnRenameTableClick(Sender: TObject);
    procedure btnAlterTableStructureClick(Sender: TObject);
    procedure btnCreateFDMemTableClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnInsertDataClick(Sender: TObject);
    procedure btnCreateSQLiteTableFromFDMemTableClick(Sender: TObject);
    procedure btnTransferDataClick(Sender: TObject);
    procedure btnViewRecordsClick(Sender: TObject);
  private
    { Private declarations }
    MemTable : TFDMemTable;

    function GetDatabasePath(const ADatabaseName: string): string;
    procedure ValidateDatabaseConnection(ASQLite4D: TSQLite4D);

  public
    { Public declarations }
  end;

var
  FormMain: TFormMain;

implementation

{$R *.fmx}

{$region ' AUXILIARY METHODS '}
function TFormMain.GetDatabasePath(const ADatabaseName: string): string;
(*
  Returns the full path to the SQLite database file based on the target
  platform.

  On Android:
    - Uses the public storage directory (shared access).
  On Other Platforms (Windows, macOS, etc.):
    - Uses the application's executable path.

  This abstraction helps ensure that the SQLite file is stored in a valid,
  writable location depending on the deployment environment.

  @param ADatabaseName The filename of the SQLite database (e.g., 'SampleDB.db')
  @return Full absolute path to the database file
*)
begin
  {$IF defined(ANDROID)}
    Result := TPath.Combine(TPath.GetPublicPath, ADatabaseName);
  {$ELSE}
    Result := TPath.Combine(ExtractFilePath(ParamStr(0)), ADatabaseName);
  {$ENDIF}
end;

procedure TFormMain.ValidateDatabaseConnection(ASQLite4D: TSQLite4D);
(*
  Validates the connection status to the SQLite database.

  If the provided `TSQLite4D` instance is not currently connected to the
  database, this method raises an exception, preventing further operations
  on an invalid connection.

  @param ASQLite4D The instance of TSQLite4D to validate.
  @raises Exception if the connection is not active.
*)
begin
  if not Assigned(ASQLite4D) then
    raise Exception.Create('TSQLite4D instance is not assigned.');

  if not ASQLite4D.IsConnected then
    raise Exception.Create('Failed to connect to the database.');
end;
{$endregion}

{$region ' DATABASE SAMPLE '}
procedure TFormMain.btnCreateDatabaseClick(Sender: TObject);
(*
  This method checks if the SQLite database file already exists.
  If it does not, it creates the database and ensures the connection is valid.
*)
const
  DBName = 'SampleDB.db';
var
  LSQLite4D: TSQLite4D;
  LDBPath: string;
begin
  LDBPath := GetDatabasePath(DBName);

  try
    if FileExists(LDBPath) then
    begin
      ShowMessage(Format('The SQLite database "%s" already exists.', [DBName]));
    end
    else
    begin
      ShowMessage(Format('The database "%s" does not exist. Creating now...', [DBName]));
      LSQLite4D := TSQLite4D.GetInstance(LDBPath);
      try
        ValidateDatabaseConnection(LSQLite4D);
        ShowMessage(Format('Database "%s" created successfully.', [DBName]));
      finally
        TSQLite4D.ReleaseInstance;
      end;
    end;
  except
    on E: Exception do
      ShowMessage(Format('Error creating the database "%s": %s - %s', [DBName, E.ClassName, E.Message]));
  end;
end;

procedure TFormMain.btnDeleteDatabaseClick(Sender: TObject);
(*
  This method checks if an SQLite database file exists at the specified path.
  If it exists, it attempts to delete the database using the `DeleteDatabase`
  method from the `TSQLite4D` class.
  Messages are shown to indicate success or failure.
*)
const
  DBName = 'SampleDB.db';
var
  LSQLite4D: TSQLite4D;
  LDBPath: string;
begin
  LDBPath := GetDatabasePath(DBName);

  try
    if FileExists(LDBPath) then
    begin
      LSQLite4D := TSQLite4D.GetInstance(LDBPath);
      try
        if LSQLite4D.DeleteDatabase then
          ShowMessage(Format('The database "%s" was successfully deleted.', [DBName]))
        else
          ShowMessage(Format('The database "%s" could not be deleted.', [DBName]));
      finally
        TSQLite4D.ReleaseInstance;
      end;
    end
    else
      ShowMessage(Format('The database "%s" was not found.', [DBName]));
  except
    on E: Exception do
      ShowMessage(Format('Error while trying to delete the database "%s": %s - %s',
        [DBName, E.ClassName, E.Message]));
  end;
end;

procedure TFormMain.btnViewDBStructureClick(Sender: TObject);
(*
  Displays the structure of the SQLite database, including:
  - Existing tables
  - Columns with data types and constraints
  - Indexes and their configurations
  - Foreign key relationships

  If no structure is found (i.e., no tables exist), it shows a message informing the user.
*)
const
  DBName = 'SampleDB.db';
var
  LSQLite4D: TSQLite4D;
  LStructure: TStringList;
  LDBPath: string;
begin
  LDBPath := GetDatabasePath(DBName);

  if not FileExists(LDBPath) then
  begin
    ShowMessage(Format('The database "%s" does not exist.', [DBName]));
    Exit;
  end;

  LSQLite4D := TSQLite4D.GetInstance(LDBPath);
  try
    ValidateDatabaseConnection(LSQLite4D);

    LStructure := LSQLite4D.GetDatabaseStructure;
    try
      // Checks for any information about tables, fields, indexes, etc.
      if (LStructure.Text.Trim = '') or (LStructure.Count = 0) then
      begin
        ShowMessage('The database exists but has no tables or defined structure.');
        Exit;
      end;

      ShowMessage(LStructure.Text);
    finally
      LStructure.Free;
    end;
  finally
    TSQLite4D.ReleaseInstance;
  end;
end;
{$endregion}

{$region ' TABLE CUSTOMER '}
procedure TFormMain.btnCreateTableCustomerClick(Sender: TObject);
(*
  Creates the "Customers" table in the SQLite database using a fluent interface.
  Includes primary key, NOT NULL, UNIQUE, and a CHECK constraint on the balance
  field. Designed for clarity: all logic is kept in this method for immediate
  comprehension.
*)
const
  DBName = 'SampleDB.db';
  TableName = 'Customers';
var
  LSQLite4D: TSQLite4D;
  LDBPath: string;
begin
  LDBPath := GetDatabasePath(DBName);

  try
    LSQLite4D := TSQLite4D.GetInstance(LDBPath);
    try
      ValidateDatabaseConnection(LSQLite4D);

      LSQLite4D.CreateTable(TableName)
        .AddField('ID', sftINTEGER)
          .PrimaryKey
          .AutoIncrement
          .EndField
        .AddField('Name', sftTEXT, 100)
          .NotNull
          .Unique
          .EndField
        .AddField('Email', sftTEXT)
          .NotNull
          .EndField
        .AddField('Balance', sftREAL)
          .Check('Balance >= 0')
          .EndField
        .BuildTable;

      ShowMessage(Format('Table "%s" created successfully in "%s".', [TableName, DBName]));

    finally
      TSQLite4D.ReleaseInstance;
    end;
  except
    on E: Exception do
      ShowMessage(Format('Error creating table "%s": %s - %s', [TableName, E.ClassName, E.Message]));
  end;
end;

procedure TFormMain.btnAddSimpleFieldsClick(Sender: TObject);
(*
  Adds new fields to the existing "Customers" table using a fluent interface.
  Useful for evolving the schema without destroying existing data.
  Each field can define type, size, constraints (e.g., NOT NULL, CHECK), and
  default values.
*)

const
  DBName = 'SampleDB.db';
  TableName = 'Customers';
var
  LSQLite4D: TSQLite4D;
  LDBPath: string;
begin
  LDBPath := GetDatabasePath(DBName);

  try
    if not FileExists(LDBPath) then
    begin
      ShowMessage(Format('The database "%s" does not exist.', [DBName]));
      Exit;
    end;

    LSQLite4D := TSQLite4D.GetInstance(LDBPath);
    try
      ValidateDatabaseConnection(LSQLite4D);

      // Adds new fields to the existing table, with validations and defaults
      LSQLite4D.CreateTable(TableName)
        .AddFieldToExistingTable('NewField_TEXT', sftTEXT, 100, [foNotNull], '', '"DefaultText"')
        .AddFieldToExistingTable('NewField_INTEGER', sftINTEGER)
        .AddFieldToExistingTable('NewField_NUMERIC', sftNUMERIC)
        .AddFieldToExistingTable('NewField_REAL', sftREAL, 0, [foNotNull], 'NewField_REAL >= 0', '1.0')
        .AddFieldToExistingTable('VIPCustomer', sftINTEGER, 0, [foNotNull], '', '0')
        .AddFieldToExistingTable('DiscountRate', sftREAL, 0, [foNotNull], 'DiscountRate BETWEEN 0 AND 1', '0.1')
        .AddFieldToExistingTable('ReferenceCode', sftTEXT, 50, [foNotNull], '', '"DefaultRefCode"')
        .AddFieldToExistingTable('CustomerStatus', sftTEXT, 10, [foNotNull], '', '"Active"');

      ShowMessage(Format('Fields successfully added to table "%s".', [TableName]));

    finally
      TSQLite4D.ReleaseInstance;
    end;
  except
    on E: Exception do
      ShowMessage(Format('Error adding fields to table "%s": %s - %s',
        [TableName, E.ClassName, E.Message]));
  end;
end;

procedure TFormMain.btnAddSimpleIndexClick(Sender: TObject);
(*
  Adds simple indexes to the existing "Customers" table using a fluent
  interface. This is useful for optimizing query performance where filtering or
  sorting is performed on individual fields. Each index defines a target column
  and the desired sort order (ASC or DESC).
*)
const
  DBName = 'SampleDB.db';
  TableName = 'Customers';
var
  LSQLite4D: TSQLite4D;
  LDBPath: string;
begin
  LDBPath := GetDatabasePath(DBName);

  try
    LSQLite4D := TSQLite4D.GetInstance(LDBPath);
    try
      ValidateDatabaseConnection(LSQLite4D);

      LSQLite4D.CreateTable(TableName)
        .AddIndex('Name', ioAsc)
        .AddIndex('Balance', ioDesc)
        .AddIndex('Email', ioDesc)
        .BuildIndexes;

      ShowMessage(Format('Indexes successfully added to table "%s".', [TableName]));
    finally
      TSQLite4D.ReleaseInstance;
    end;
  except
    on E: Exception do
      ShowMessage(Format('Error adding indexes to table "%s": %s - %s',
        [TableName, E.ClassName, E.Message]));
  end;
end;

procedure TFormMain.btnAddCompositeIndexClick(Sender: TObject);
(*
  Adds composite indexes to the existing "Customers" table using a fluent
  interface. Composite indexes are useful when queries filter or sort by
  multiple columns together.

  In this example:
  - The first composite index is unnamed, so the system will auto-generate its
    name.
  - The second composite index is explicitly named as
    "idx_custom_idx_name_balance".

  Both indexes are finalized by calling BuildCompositeIndexes.
*)
const
  DBName = 'SampleDB.db';
  TableName = 'Customers';
var
  LSQLite4D: TSQLite4D;
  LDBPath: string;
begin
  LDBPath := GetDatabasePath(DBName);

  try
    LSQLite4D := TSQLite4D.GetInstance(LDBPath);
    try
      ValidateDatabaseConnection(LSQLite4D);

      LSQLite4D.CreateTable(TableName)
        .AddCompositeIndex(['Name', 'Balance'], ioAsc)
        .AddCompositeIndex(['Name', 'Balance'], ioAsc, 'idx_custom_idx_name_balance')
        .BuildCompositeIndexes;

      ShowMessage(Format('Composite indexes successfully added to table "%s".', [TableName]));
    finally
      TSQLite4D.ReleaseInstance;
    end;
  except
    on E: Exception do
      ShowMessage(Format('Error adding composite indexes to table "%s": %s - %s',
        [TableName, E.ClassName, E.Message]));
  end;
end;

procedure TFormMain.btnDeleteAllIndexClick(Sender: TObject);
(*
  Deletes all specified indexes from the "Customers" table using a fluent
  interface. This is useful when restructuring index strategy or cleaning up
  obsolete indexes.

  The method calls `DropIndex` for each target index:
    - idx_Customers_Name
    - idx_Customers_Balance
    - idx_Customers_Email
    - idx_comp_Name_Balance
    - idx_custom_idx_name_balance

  After dropping all, a success message is displayed.
*)
var
  LSQLite4D: TSQLite4D;
begin
  try
    LSQLite4D := TSQLite4D.GetInstance(GetDatabasePath('SampleDB.db'));
    try
      ValidateDatabaseConnection(LSQLite4D);

      LSQLite4D.CreateTable('Customers')
        .DropIndex('idx_Customers_Name')
        .DropIndex('idx_Customers_Balance')
        .DropIndex('idx_Customers_Email')
        .DropIndex('idx_comp_Name_Balance')
        .DropIndex('idx_custom_idx_name_balance');

      ShowMessage('All specified indexes deleted successfully.');
    finally
      TSQLite4D.ReleaseInstance;
    end;
  except
    on E: Exception do
      ShowMessage('Error deleting indexes - ' + E.ClassName + ': ' + E.Message);
  end;
end;

procedure TFormMain.btnDeleteTableClick(Sender: TObject);
(*
  Deletes the "Customers" table from the SQLite database if it exists. This
  method uses the `DeleteTable` method provided by the `TSQLite4D` class to
  safely check for the existence of the table before attempting to delete it.

  The operation is wrapped in a try/except block to handle any exceptions that
  may occur during the process (e.g., file locks, invalid connections, etc.).

  Success: A confirmation message is shown if the table was deleted.
  Failure: A warning is shown if the table does not exist or cannot be deleted.
*)
var
  LSQLite4D: TSQLite4D;
begin
  try
    LSQLite4D := TSQLite4D.GetInstance(GetDatabasePath('SampleDB.db'));
    try
      ValidateDatabaseConnection(LSQLite4D);

      if LSQLite4D.DeleteTable('Customers') then
        ShowMessage('Table "Customers" deleted successfully.')
      else
        ShowMessage('Error when trying to delete table "Customers".');
    finally
      TSQLite4D.ReleaseInstance;
    end;
  except
    on E: Exception do
      ShowMessage('Error when deleting table "Customers": ' +
        E.ClassName + ' - ' + E.Message);
  end;
end;
{$endregion}

{$region ' TABLES USERS/ORDERS/ORDERDETAILS '}
procedure TFormMain.btnCreateRelatedTablesClick(Sender: TObject);
(*
  Creates a sample relational database with foreign key constraints. This
  method initializes a new SQLite database named "SampleDB.db" and creates
  three related tables: Users, Orders, and OrderDetails.

  • The Users table contains basic user information and enforces uniqueness on
    name and email fields.
  • The Orders table references Users via the UserID field using foreign key
    constraints with CASCADE rules.
  • The OrderDetails table references Orders and includes quantity and price
    validations using CHECK constraints.

  After creating the tables, sample records are inserted into each of them to
  demonstrate the relational structure and referential integrity in action.

  Demonstrated Features:
  • Primary keys with autoincrement
  • NOT NULL and UNIQUE constraints
  • Foreign key relationships with cascading rules
  • CHECK constraints for data validation
  • Scalar query execution (e.g., getting last inserted IDs)
*)
var
  LSQLite4D: TSQLite4D;
  LUserID, LOrderID: Integer;
begin
  try
    if not FileExists(GetDatabasePath('SampleDB.db')) then
    begin
      ShowMessage('Database does not exist. Creating a new one...');
    end;

    LSQLite4D := TSQLite4D.GetInstance(GetDatabasePath('SampleDB.db'));
    try
      ValidateDatabaseConnection(LSQLite4D);

      // Create Users table
      LSQLite4D.CreateTable('Users')
        .AddField('UserID', sftINTEGER)
          .PrimaryKey
          .AutoIncrement
          .EndField
        .AddField('Name', sftTEXT, 100)
          .NotNull
          .Unique
          .EndField
        .AddField('Email', sftTEXT, 200)
          .NotNull
          .Unique
          .EndField
        .BuildTable;

      // Create Orders table with foreign key to Users
      LSQLite4D.CreateTable('Orders')
        .AddField('OrderID', sftINTEGER)
          .PrimaryKey
          .AutoIncrement
          .EndField
        .AddField('UserID', sftINTEGER)
          .NotNull
          .EndField
        .AddField('OrderDate', sftTEXT)
          .NotNull
          .EndField
        .AddForeignKey('UserID', 'Users', 'UserID', 'CASCADE', 'CASCADE', '')
        .BuildTable;

      // Create OrderDetails table with foreign key to Orders
      LSQLite4D.CreateTable('OrderDetails')
        .AddField('DetailID', sftINTEGER)
          .PrimaryKey
          .AutoIncrement
          .EndField
        .AddField('OrderID', sftINTEGER)
          .NotNull
          .EndField
        .AddField('ProductName', sftTEXT, 150)
          .NotNull
          .EndField
        .AddField('Quantity', sftINTEGER)
          .NotNull
          .Check('Quantity > 0')
          .EndField
        .AddField('Price', sftREAL)
          .NotNull
          .Check('Price >= 0')
          .EndField
        .AddForeignKey('OrderID', 'Orders', 'OrderID', 'CASCADE', 'CASCADE', '')
        .BuildTable;

      // Insert sample users
      LSQLite4D.ExecuteSQL('INSERT INTO Users (Name, Email) VALUES ("Alice", "alice1@example.com");');
      LSQLite4D.ExecuteSQL('INSERT INTO Users (Name, Email) VALUES ("Bob", "bob1@example.com");');
      LSQLite4D.ExecuteSQL('INSERT INTO Users (Name, Email) VALUES ("Charlie", "charlie1@example.com");');

      // Retrieve UserID for Alice
      LUserID := LSQLite4D.ExecuteSQLScalar('SELECT UserID FROM Users WHERE Name = "Alice";');

      // Insert sample orders
      LSQLite4D.ExecuteSQL(Format('INSERT INTO Orders (UserID, OrderDate) VALUES (%d, "2024-12-10");', [LUserID]));
      LSQLite4D.ExecuteSQL(Format('INSERT INTO Orders (UserID, OrderDate) VALUES (%d, "2024-12-11");', [LUserID]));

      // Get the first order's ID for Alice
      LOrderID := LSQLite4D.ExecuteSQLScalar('SELECT OrderID FROM Orders WHERE UserID = ' + LUserID.ToString + ' LIMIT 1;');

      // Insert sample order details
      LSQLite4D.ExecuteSQL(Format('INSERT INTO OrderDetails (OrderID, ProductName, Quantity, Price) VALUES (%d, "Product A", 2, 19.99);', [LOrderID]));
      LSQLite4D.ExecuteSQL(Format('INSERT INTO OrderDetails (OrderID, ProductName, Quantity, Price) VALUES (%d, "Product B", 1, 9.99);', [LOrderID]));

      ShowMessage('Database, tables, and foreign keys created and populated successfully!');
    finally
      TSQLite4D.ReleaseInstance;
    end;
  except
    on E: Exception do
      ShowMessage('Error - ' + E.ClassName + ': ' + E.Message);
  end;
end;

procedure TFormMain.btnAlterTableStructureClick(Sender: TObject);
(*
  Demonstrates a safe and structured way to modify the schema of an existing
  SQLite table.

  This method performs the following operations:
    - Temporarily disables foreign key constraints.
    - Creates a temporary table to hold the current data.
    - Drops the original table (Users).
    - Recreates the Users table with a new schema (with renamed columns and
      constraints).
    - Restores the data into the new table structure.
    - Deletes the temporary table.
    - Re-enables foreign key constraints.

  This is the recommended pattern for altering SQLite table schemas beyond
  basic operations, as SQLite does not support all ALTER TABLE operations
  directly.
*)
const
  DBFileName = 'SampleDB.db';
  OriginalTable = 'Users';
  TempTable = 'Users_temp';
var
  LSQLite4D: TSQLite4D;
  LSQLCommands: TArray<string>;
begin
  try
    LSQLite4D := TSQLite4D.GetInstance(GetDatabasePath(DBFileName));
    try
      ValidateDatabaseConnection(LSQLite4D);

      LSQLCommands := [
        // Step 1: Disable foreign key checks during schema change
        'PRAGMA foreign_keys = OFF;',

        // Step 2: Create a temporary table as a copy of the current Users table
        Format('CREATE TABLE %s AS SELECT * FROM %s;', [TempTable, OriginalTable]),

        // Step 3: Drop the original Users table
        Format('DROP TABLE IF EXISTS %s;', [OriginalTable]),

        // Step 4: Recreate Users table with new schema (example: rename "Name" to "NameNew")
        'CREATE TABLE Users (' +
        '    UserID   INTEGER PRIMARY KEY AUTOINCREMENT,' +
        '    NameNew  TEXT(100) UNIQUE NOT NULL,' +
        '    Email    TEXT(200) UNIQUE NOT NULL' +
        ');',

        // Step 5: Restore data from the temporary table into the new Users table
        // "Name" from temp table becomes "NameNew" in new structure
        'INSERT INTO Users (UserID, NameNew, Email) ' +
        Format('SELECT UserID, Name, Email FROM %s;', [TempTable]),

        // Step 6: Drop the temporary table
        Format('DROP TABLE IF EXISTS %s;', [TempTable]),

        // Step 7: Re-enable foreign key checks
        'PRAGMA foreign_keys = ON;'
      ];

      // Execute the entire batch
      if LSQLite4D.ExecuteMultipleSQL(LSQLCommands) then
        ShowMessage('User table structure modified successfully.');
    finally
      TSQLite4D.ReleaseInstance;
    end;
  except
    on E: Exception do
      ShowMessage('Error executing SQL commands: ' + E.ClassName + ' - ' + E.Message);
  end;
end;

procedure TFormMain.btnRenameTableClick(Sender: TObject);
(*
  Renames a table in the SQLite database using a fluent interface. This method
  renames the existing `Users` table to `NewUsers` by calling the `RenameTable`
  method of the `TSQLite4D` class. Renaming a table is useful when refactoring
  your schema or adapting naming conventions.

  Demonstrated Features:
  • Runtime table renaming
  • Table existence verification
  • Exception handling
*)
var
  LSQLite4D: TSQLite4D;
begin
  try
    LSQLite4D := TSQLite4D.GetInstance(GetDatabasePath('SampleDB.db'));
    try
      ValidateDatabaseConnection(LSQLite4D);

      // Attempts to rename the "Users" table to "NewUsers"
      if LSQLite4D.RenameTable('Users', 'NewUsers') then
        ShowMessage('Table renamed successfully!')
      else
        ShowMessage('Failed to rename table "Users".');
    finally
      TSQLite4D.ReleaseInstance;
    end;
  except
    on E: Exception do
      ShowMessage('Error renaming table - ' + E.ClassName + ': ' + E.Message);
  end;
end;

procedure TFormMain.btnViewRecordsClick(Sender: TObject);
(*
  This method displays up to 10 records from the selected table in the MemoData
  control, showing field names and values in a readable format. It avoids dialog
  interruptions and is better suited for quick inspection or teaching purposes.
*)
const
  RECORD_LIMIT = 10000;
var
  LSQLite4D: TSQLite4D;
  LQuery: string;
  LTableName: string;
  LColumnIndex: Integer;
  LDataSet: TFDQuery;
  LTotalRecords: Integer;
begin
  try
    // Determine the selected table
    if rbCustomers.IsChecked then
      LTableName := 'Customers'
    else if rbUsers.IsChecked then
      LTableName := 'Users'
    else if rbOrders.IsChecked then
      LTableName := 'Orders'
    else if rbOrderDetails.IsChecked then
      LTableName := 'OrderDetails'
    else if rbSuppliers.IsChecked then
      LTableName := 'Suppliers'
    else
    begin
      TDialogService.ShowMessage('Select a table to view records.');
      Exit;
    end;

    MemoData.Lines.Clear;

    // Get the SQLite4D instance
    LSQLite4D := TSQLite4D.GetInstance(GetDatabasePath('SampleDB.db'));
    try
      ValidateDatabaseConnection(LSQLite4D);

      // Count total records
      LQuery := Format('SELECT COUNT(*) FROM %s;', [LTableName]);
      LTotalRecords := LSQLite4D.ExecuteSQLScalar(LQuery);

      if LTotalRecords = 0 then
      begin
        MemoData.Lines.Add(Format('Table "%s" is empty.', [LTableName]));
        Exit;
      end;

      MemoData.Lines.Add(Format('Table "%s" - Showing first %d of %d records:', [LTableName, RECORD_LIMIT, LTotalRecords]));
      MemoData.Lines.Add('');

      // Configure query
      LQuery := Format('SELECT * FROM %s LIMIT %d;', [LTableName, RECORD_LIMIT]);

      // Create and configure DataSet
      LDataSet := TFDQuery.Create(nil);
      try
        LDataSet.Connection := LSQLite4D.GetConnection;
        LDataSet.SQL.Text := LQuery;
        LDataSet.Open;

        while not LDataSet.Eof do
        begin
          for LColumnIndex := 0 to LDataSet.FieldCount - 1 do
          begin
            MemoData.Lines.Add(Format('%s: %s',
              [LDataSet.Fields[LColumnIndex].FieldName,
               LDataSet.Fields[LColumnIndex].AsString]));
          end;
          MemoData.Lines.Add('----------------------------------------');
          LDataSet.Next;
        end;
      finally
        LDataSet.Free;
      end;
    finally
      TSQLite4D.ReleaseInstance;
    end;
  except
    on E: Exception do
      MemoData.Lines.Add('Error viewing records: ' + E.ClassName + ': ' + E.Message);
  end;
end;
{$endregion}

{$region ' CREATE SQLITE TABLE FROM FDMEMTABLE '}
procedure TFormMain.btnCreateFDMemTableClick(Sender: TObject);
(*
  Creates an in-memory table (TFDMemTable) with a predefined schema. This
  method initializes a TFDMemTable instance with various fields of different
  data types, suitable for temporary data manipulation or future persistence
  to SQLite.

  Highlights:
  - Frees any previous instance to prevent memory leaks.
  - Defines fields explicitly with FieldDefs for type safety.
  - Includes fields: Integer, String, Date, Boolean, Float, Memo, and DateTime.
  - Handles exceptions and notifies the user.
*)
begin
  // Free previous instance if it exists
  FreeAndNil(MemTable);

  // Create and define the FDMemTable schema
  MemTable := TFDMemTable.Create(nil);
  try
    with MemTable.FieldDefs do
    begin
      with AddFieldDef do begin
        Name := 'ID';
        DataType := ftInteger;
        Required := True;
      end;

      Add('Name',      ftString,   100); // String up to 100 chars
      Add('BirthDate', ftDate);          // Date field
      Add('IsActive',  ftBoolean);       // Boolean flag
      Add('Balance',   ftFloat);         // Floating-point value
      Add('Notes',     ftMemo);          // Large text/memo
      Add('Created',   ftDateTime);      // Date and time
    end;

    MemTable.CreateDataSet;
    MemTable.Open;

    ShowMessage('FDMemTable created successfully.');
  except
    on E: Exception do
    begin
      FreeAndNil(MemTable);
      ShowMessage('Error creating FDMemTable - ' + E.ClassName + ': ' + E.Message);
    end;
  end;
end;

procedure TFormMain.btnInsertDataClick(Sender: TObject);
(*
  Inserts 10,000 sample records into the in-memory FDMemTable.

  This method fills the dataset with randomized and sequential values to
  simulate real-world content. It's useful for testing, performance
  benchmarking, and UI demonstrations.

  Fields populated:
    - ID        (Integer, incremental)
    - Name      (String with suffix)
    - BirthDate (Date, increasing by index)
    - IsActive  (Boolean, alternating true/false)
    - Balance   (Float, random)
    - Notes     (Memo, text with ID)
    - Created   (DateTime, decreasing pattern)

  Notes:
    - Disables controls for better performance.
    - Uses batch operations to reduce overhead.
    - Displays elapsed time after insertion.
*)
const
  TotalRecords = 10000;
var
  I: Integer;
  LStopwatch: TStopwatch;
begin
  if not Assigned(MemTable) then
  begin
    ShowMessage('FDMemTable must be created before inserting data.');
    Exit;
  end;

  LStopwatch := TStopwatch.StartNew;

  MemTable.DisableControls;
  MemTable.LogChanges := False;
  MemTable.FetchOptions.RecsMax := TotalRecords;
  MemTable.ResourceOptions.SilentMode := True;

  MemTable.BeginBatch;
  try
    for I := 1 to TotalRecords do
    begin
      MemTable.Append;
      MemTable.FieldByName('ID').AsInteger         := I;
      MemTable.FieldByName('Name').AsString        := 'John Doe ' + I.ToString;
      MemTable.FieldByName('BirthDate').AsDateTime := EncodeDate(1990, 1, 1) + I;
      MemTable.FieldByName('IsActive').AsBoolean   := (I mod 2 = 0);
      MemTable.FieldByName('Balance').AsFloat      := Random * 10000;
      MemTable.FieldByName('Notes').AsString       := 'Memo for record #' + I.ToString;
      MemTable.FieldByName('Created').AsDateTime   := Now - (I mod 365);
      MemTable.Post;
    end;
  finally
    MemTable.EndBatch;
    MemTable.EnableControls;
    LStopwatch.Stop;

    ShowMessage(Format('Inserted %d records in %d ms.', [TotalRecords, LStopwatch.ElapsedMilliseconds]));
  end;
end;

procedure TFormMain.btnCreateSQLiteTableFromFDMemTableClick(Sender: TObject);
(*
  Creates a SQLite table named "Suppliers" based on the structure of the
  in-memory FDMemTable.

  This method uses the `CreateSQLiteTableFromMemTable` method from the
  `TSQLite4D` class to translate Delphi field definitions into SQLite-compatible
  schema automatically.

  Key Features:
    - Reads structure directly from TFDMemTable (MemTable).
    - Avoids overwriting existing tables by setting ForceRecreate = False.
    - Ensures database connection is valid before attempting creation.
    - Ideal for hybrid architectures or offline data persistence.

  Parameters:
    - MemTable     : Source dataset containing the field definitions.
    - "Suppliers"  : Target table name in SQLite.
    - ForceRecreate: False (do not delete table if it exists).
*)
const
  DBFileName = 'SampleDB.db';
  TableName = 'Suppliers';
var
  LSQLite4D: TSQLite4D;
  LDatabasePath: string;
begin
  if not Assigned(MemTable) then
  begin
    ShowMessage('FDMemTable must be created before generating the SQLite table.');
    Exit;
  end;

  LDatabasePath := GetDatabasePath(DBFileName);
  LSQLite4D := TSQLite4D.GetInstance(LDatabasePath);
  try
    ValidateDatabaseConnection(LSQLite4D);

    LSQLite4D.CreateSQLiteTableFromMemTable(MemTable, TableName, False);

    ShowMessage(Format('SQLite table "%s" created successfully.', [TableName]));
  finally
    TSQLite4D.ReleaseInstance;
  end;
end;

procedure TFormMain.btnTransferDataClick(Sender: TObject);
(*
  Transfers records from the in-memory TFDMemTable (MemTable) to the SQLite
  table "Suppliers".

  This method uses `CopyDataFromMemTableToSQLite` from the `TSQLite4D` class
  to copy rows from memory into a physical SQLite table.

  Key Features:
    - Updates progress through a callback (currently empty, but ready for use).
    - Synchronous execution (main thread) – suitable for small datasets or
      demos.
    - UI button is temporarily disabled to prevent reentry.

  Parameters:
    - TableName: Target SQLite table name ("Suppliers").
    - MemTable : Source in-memory dataset.

  Note:
    - For large datasets, consider wrapping the operation in a background
      thread to avoid UI freeze.
*)
const
  DBFileName = 'SampleDB.db';
  TableName = 'Suppliers';
var
  LSQLite4D: TSQLite4D;
begin
  if not Assigned(MemTable) then
  begin
    ShowMessage('MemTable must be created and filled with data before transferring.');
    Exit;
  end;

  TButton(Sender).Enabled := False;

  try
    LSQLite4D := TSQLite4D.GetInstance(GetDatabasePath(DBFileName));
    try
      ValidateDatabaseConnection(LSQLite4D);

      LSQLite4D.CopyDataFromMemTableToSQLite(
        TableName, MemTable, 1,
        procedure(Progress: Integer)
        begin
          // Optional: Implement progress feedback if needed
        end
      );
    finally
      TSQLite4D.ReleaseInstance;
    end;

    ShowMessage('Records transferred to SQLite successfully.');
  except
    on E: Exception do
      ShowMessage('Error during data transfer - ' + E.ClassName + ': ' + E.Message);
  end;

  TButton(Sender).Enabled := True;
end;
{$endregion}

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  if Assigned(MemTable) then
    FreeAndNil(MemTable);
end;

end.
