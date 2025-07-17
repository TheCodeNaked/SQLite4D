unit SQLite4D;

interface

uses
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.Comp.DataSet,
  FireDAC.Stan.Option,
  FMX.Dialogs,
  FMX.Types,
  System.Classes,
  System.Diagnostics,
  System.Math,
  System.SysUtils;

type
  TSQLiteFieldType = (sftBLOB, sftINTEGER, sftNUMERIC, sftREAL, sftTEXT);
  TFieldOption = (foPrimaryKey, foUnique, foNotNull);

  TFieldOptions = set of TFieldOption;
  TIndexOrder = (ioAsc, ioDesc);
  TProgressCallback = reference to procedure(AProgress: Integer);

  ITableDefinition = interface;

  IFieldConfigurator = interface
    ['{9F286CBF-455E-4119-A04E-79DD2D544CBB}']
    function AutoIncrement: IFieldConfigurator;
    function Check(const ACheckClause: string): IFieldConfigurator;
    function EndField: ITableDefinition;
    function NotNull: IFieldConfigurator;
    function PrimaryKey: IFieldConfigurator;
    function Unique: IFieldConfigurator;
  end;

  ITableDefinition = interface
    ['{D30191D3-F117-481B-AFEA-2CBB06C8B14A}']
    function AddCompositeIndex(const AFieldNames: TArray<string>; AOrder: TIndexOrder; const AIndexName: string = ''): ITableDefinition;
    function AddField(const AFieldName: string; AFieldType: TSQLiteFieldType; ASize: Integer = 0): IFieldConfigurator;
    function AddFieldToExistingTable(const AFieldName: string; AFieldType: TSQLiteFieldType; ASize: Integer = 0; AOptions: TFieldOptions = []; const ACheckClause: string = ''; const ADefaultValue: string = ''): ITableDefinition;
    function AddForeignKey(const AFieldName, AReferenceTable, AReferenceField, AOnDelete, AOnUpdate, AMatch: string): ITableDefinition;
    function AddIndex(const AFieldName: string; AOrder: TIndexOrder = ioAsc): ITableDefinition;
    function DropIndex(const AIndexName: string): ITableDefinition;
    procedure AddOptionToField(AFieldIndex: Integer; AOption: TFieldOption);
    procedure BuildCompositeIndexes;
    procedure BuildIndexes;
    procedure BuildTable;
    procedure SetFieldAutoIncrement(AFieldIndex: Integer; AIsAutoIncrement: Boolean);
    procedure SetFieldCheckClause(AFieldIndex: Integer; const ACheckClause: string);
  end;

  TFieldDefinition = record
    FieldName: string;
    FieldType: TSQLiteFieldType;
    Size: Integer;
    Options: TFieldOptions;
    CheckClause: string;
    IsAutoIncrement: Boolean;
    function BuildDefinition: string;
  end;

  TForeignKeyDefinition = record
    FieldName: string;
    ReferenceTable: string;
    ReferenceField: string;
    OnDelete: string;
    OnUpdate: string;
    Match: string;
    function BuildDefinition: string;
  end;

  TIndexDefinition = record
    FieldName: string;
    Order: TIndexOrder;
    function BuildDefinition(const ATableName: string): string;
  end;

  TCompositeIndexDefinition = record
    IndexName: string;
    FieldNames: TArray<string>;
    Order: TIndexOrder;
    function BuildDefinition(const ATableName: string): string;
  end;

  TFieldConfigurator = class(TInterfacedObject, IFieldConfigurator)
  private
    FTableDefinition: ITableDefinition;
    FCurrentFieldIndex: Integer;
  public
    constructor Create(ATableDefinition: ITableDefinition; AFieldIndex: Integer);
    function AutoIncrement: IFieldConfigurator;
    function Check(const ACheckClause: string): IFieldConfigurator;
    function EndField: ITableDefinition;
    function NotNull: IFieldConfigurator;
    function PrimaryKey: IFieldConfigurator;
    function Unique: IFieldConfigurator;
  end;

  TTableDefinition = class(TInterfacedObject, ITableDefinition)
  private
    FTableName: string;
    FFields: TArray<TFieldDefinition>;
    FForeignKeys: TArray<TForeignKeyDefinition>;
    FIndexes: TArray<TIndexDefinition>;
    FCompositeIndexes: TArray<TCompositeIndexDefinition>;
    FConnection: TFDConnection;

    function FieldExists(const AFieldName: string): Boolean;
    procedure ValidateNotNullField(const AFieldName: string; AOptions: TFieldOptions; const ADefaultValue: string);
    function GenerateCompositeIndexName(const AFieldNames: TArray<string>): string;
    function IndexExists(const AIndexName: string): Boolean;
    function TableExists: Boolean;
  public
    constructor Create(const ATableName: string; AConnection: TFDConnection);
    function AddCompositeIndex(const AFieldNames: TArray<string>; AOrder: TIndexOrder; const AIndexName: string = ''): ITableDefinition;
    function AddField(const AFieldName: string; AFieldType: TSQLiteFieldType; ASize: Integer = 0): IFieldConfigurator;
    function AddFieldToExistingTable(const AFieldName: string; AFieldType: TSQLiteFieldType; ASize: Integer = 0; AOptions: TFieldOptions = []; const ACheckClause: string = ''; const ADefaultValue: string = ''): ITableDefinition;
    function AddForeignKey(const AFieldName, AReferenceTable, AReferenceField, AOnDelete, AOnUpdate, AMatch: string): ITableDefinition;
    function AddIndex(const AFieldName: string; AOrder: TIndexOrder = ioAsc): ITableDefinition;
    function DropIndex(const AIndexName: string): ITableDefinition;
    procedure AddOptionToField(AFieldIndex: Integer; AOption: TFieldOption);
    procedure BuildCompositeIndexes;
    procedure BuildIndexes;
    procedure BuildTable;
    procedure SetFieldAutoIncrement(AFieldIndex: Integer; AIsAutoIncrement: Boolean);
    procedure SetFieldCheckClause(AFieldIndex: Integer; const ACheckClause: string);
  end;

  TSQLite4D = class(TObject)
  private
    // Class variable to store the single instance
    class var FInstance: TSQLite4D;
    FConnection: TFDConnection;
    FIndexDefs: TStringList;

    // Private constructor to prevent direct instantiation
    constructor CreatePrivate(const ADatabasePath: string);
    class function FieldTypeToString(AFieldType: TSQLiteFieldType): string;
    procedure ToggleTableIndexes(ATableName: string; AEnable: Boolean);
  public
    // Singleton
    destructor Destroy; override;
    class function GetInstance(const ADatabasePath: string = ''): TSQLite4D;
    class procedure ReleaseInstance;
    function CreateSQLiteTableFromMemTable(AMemTable: TFDMemTable; const ATableName: string; const ForceRecreate: Boolean = False): Boolean;
    function CreateTable(const ATableName: string): ITableDefinition;
    function DeleteDatabase: Boolean;
    function DeleteTable(const ATableName: string): Boolean;
    function ExecuteSQLScalar(const ASQL: string; UseTransaction: Boolean = False): Variant;
    function GetConnection: TFDConnection;
    function GetDatabaseStructure: TStringList;
    function IsConnected: Boolean;
    function MapFDFieldTypeToSQLite(const AField: TField): TSQLiteFieldType;
    function RenameTable(const OldTableName, NewTableName: string): Boolean;
    procedure CopyDataFromMemTableToSQLite(const ATableName: string; AMemTable: TFDMemTable; ABatchSize: Integer = 500; AProgressCallback: TProgressCallback = nil);
    function ExecuteMultipleSQL(const ASQLCommands: TArray<string>): Boolean;
    procedure ExecuteSQL(const ASQL: string; UseTransaction: Boolean = True);
  end;

const
  SQLITE_DRIVER_NAME = 'SQLite';

  SQL_CHECK_TABLE_EXISTS = 'SELECT COUNT(*) FROM sqlite_master WHERE type = ''table'' AND name = :TableName;';
  SQL_TABLE_COLUMNS_INFO = 'PRAGMA table_info(%s);';

  SQL_ALTER_TABLE_ADD_COLUMN = 'ALTER TABLE %s ADD COLUMN %s %s %s;';
  SQL_CREATE_TABLE = 'CREATE TABLE IF NOT EXISTS %s (%s);';
  SQL_DROP_TABLE_IF_EXISTS = 'DROP TABLE IF EXISTS %s;';
  SQL_RENAME_TABLE = 'ALTER TABLE %s RENAME TO %s;';

  FIELD_TYPE_BLOB = 'BLOB';
  FIELD_TYPE_INTEGER = 'INTEGER';
  FIELD_TYPE_NUMERIC = 'NUMERIC';
  FIELD_TYPE_REAL = 'REAL';
  FIELD_TYPE_TEXT = 'TEXT';
  FIELD_TYPE_UNKNOWN = 'UNKNOWN';

  FIELD_CONSTRAINT_AUTOINCREMENT = ' AUTOINCREMENT';
  FIELD_CONSTRAINT_NOT_NULL = ' NOT NULL';
  FIELD_CONSTRAINT_PRIMARY_KEY = ' PRIMARY KEY';
  FIELD_CONSTRAINT_UNIQUE = ' UNIQUE';

  SQL_FOREIGN_KEY_REFERENCES = 'FOREIGN KEY(%s) REFERENCES %s(%s)%s';
  SQL_PRAGMA_FOREIGN_KEY_LIST = 'PRAGMA foreign_key_list(%s);';

  // Options for foreign keys
  SQL_ON_DELETE = ' ON DELETE ';
  SQL_ON_UPDATE = ' ON UPDATE ';
  SQL_MATCH = ' MATCH ';

  SQL_CREATE_INDEX = 'CREATE INDEX IF NOT EXISTS idx_%s_%s ON %s (%s %s);';
  SQL_CREATE_INDEX_IF_NOT_EXISTS = 'CREATE INDEX IF NOT EXISTS %s ON %s (%s %s);';
  SQL_DROP_INDEX_IF_EXISTS = 'DROP INDEX IF EXISTS %s;';
  SQL_SELECT_COUNT_INDEX_FROM_MASTER = 'SELECT COUNT(*) FROM sqlite_master WHERE type = ''index'' AND name = %s';
  SQL_SELECT_INDEXES_INFO = 'SELECT name, sql FROM sqlite_master WHERE type = ''index'' AND tbl_name = ''%s'' AND sql IS NOT NULL;';

  SORT_ORDER_ASC = 'ASC';
  SORT_ORDER_DESC = 'DESC';

  SQL_INSERT_INTO_VALUES = 'INSERT INTO %s (%s) VALUES (%s)';

  EXCEPTION_AUTOINCREMENT_ONLY_INTEGER = 'AUTOINCREMENT only applies to INTEGER fields.';
  EXCEPTION_AUTOINCREMENT_WITHOUT_PRIMARY_KEY = 'AUTOINCREMENT can only be used on INTEGER fields that are also defined as PRIMARY KEY. Check the definition of the field "%s" to ensure it is correctly declared.';
  EXCEPTION_CANNOT_ADD_NOT_NULL_WITHOUT_DEFAULT_VALUE = 'Cannot add a NOT NULL column without a default value.';
  EXCEPTION_CANNOT_RENAME_TABLE_BECAUSE_FOREIGN_KEY_DEPENDENCIES = 'Cannot rename table "%s" because it has foreign key dependencies.';
  EXCEPTION_CONNECTION_IS_NOT_INITIALIZED = 'Connection is not initialized.';
  EXCEPTION_DATABASE_CONNECTION_INACTIVE = 'Database connection is not active.';
  EXCEPTION_DATABASE_FILE_NAME_NOT_FOUND = 'Database file not found: %s';
  EXCEPTION_DATABASE_FILE_NOT_FOUND = 'Database file not found.';
  EXCEPTION_DATABASE_PATH_IS_MANDATORY_FIRST_BOOT = 'Database path is mandatory on first boot.';
  EXCEPTION_ERROR_EXECUTING_SQL = 'Error executing SQL: %s - %s';
  EXCEPTION_ERROR_RENAMING_TABLE = 'Error renaming table "%s" to "%s" - %s';
  EXCEPTION_FAILED_DELETE_DATABASE_FILE = 'Failed to delete the database file: %s';
  EXCEPTION_FIELD_ALREADY_EXISTS_IN_TABLE = 'The field "%s" already exists in the table "%s".';
  EXCEPTION_FIELD_DOES_NOT_EXIST_IN_TABLE = 'The field "%s" does not exist in the table "%s".';
  EXCEPTION_FIELD_INDEX_OUT_OF_BOUNDS = 'Field index is out of bounds.';
  EXCEPTION_INDEX_ALREADY_EXISTS = 'The index "%s" already exists.';
  EXCEPTION_INDEX_ALREADY_EXISTS_IN_TABLE = 'The index "%s" already exists in the table "%s".';
  EXCEPTION_INDEX_DOES_NOT_EXIST = 'Index "%s" does not exist.';
  EXCEPTION_MEMTABLE_CANNOT_BE_NIL = 'The MemTable cannot be nil.';
  EXCEPTION_TABLE_ALREADY_EXISTS = 'The table "%s" already exists.';
  EXCEPTION_TABLE_DOES_NOT_EXIST = 'The table "%s" does not exist in SQLite.';
  EXCEPTION_TABLE_HAS_FOREIGN_KEY_DEPENDENCIES_DELETION_ABORTED = 'The table "%s" has foreign key dependencies. Deletion aborted.';
  EXCEPTION_TABLE_NAME_CANNOT_BE_EMPTY = 'The table name cannot be empty.';
  EXCEPTION_THE_FIELD_LIST_FOR_THE_COMPOSITE_INDEX_IS_EMPTY = 'The field list for the composite index cannot be empty.';
  EXCEPTION_TRANSACTION_FAILED_COPYING_DATA_FOR_TABLE = 'The transaction failed while copying data to the table "%s". Error: %s';
  EXCEPTION_UNSUPPORTED_FIELD_TYPE = 'Unsupported field type: %s.';

implementation

{ TFieldDefinition }
function TFieldDefinition.BuildDefinition: string;
begin
  Result := FieldName + ' ' + TSQLite4D.FieldTypeToString(FieldType);

  if (FieldType = sftTEXT) and (Size > 0) then
  begin
    Result := Result + Format('(%d)', [Size]);
  end;

  if foPrimaryKey in Options then
  begin
    Result := Result + FIELD_CONSTRAINT_PRIMARY_KEY;
    if (IsAutoIncrement) and (FieldType = sftINTEGER) then
    begin
        Result := Result + FIELD_CONSTRAINT_AUTOINCREMENT;
    end else if IsAutoIncrement then
    begin
      // This prevents adding AUTOINCREMENT without PRIMARY KEY, which is not allowed
      raise Exception.CreateFmt(EXCEPTION_AUTOINCREMENT_WITHOUT_PRIMARY_KEY, [FieldName]);
    end;
  end;

  if foUnique in Options then
    Result := Result + FIELD_CONSTRAINT_UNIQUE;

  if foNotNull in Options then
    Result := Result + FIELD_CONSTRAINT_NOT_NULL;

  if CheckClause <> '' then
    Result := Result + ' CHECK(' + CheckClause + ')';
end;


{ TForeignKeyDefinition }
function TForeignKeyDefinition.BuildDefinition: string;
var
  LOptions: string;
begin
  LOptions := '';
  if OnDelete <> '' then
    LOptions := LOptions + SQL_ON_DELETE + OnDelete;

  if OnUpdate <> '' then
    LOptions := LOptions + SQL_ON_UPDATE + OnUpdate;

  if Match <> '' then
    LOptions := LOptions + SQL_MATCH + Match;

  Result := Format(SQL_FOREIGN_KEY_REFERENCES, [FieldName, ReferenceTable, ReferenceField, LOptions]);
end;


{ TIndexDefinition }
function TIndexDefinition.BuildDefinition(const ATableName: string): string;
var
  LOrderStr: string;
begin
  case Order of
    ioAsc: LOrderStr := SORT_ORDER_ASC;
    ioDesc: LOrderStr := SORT_ORDER_DESC;
  else
    LOrderStr := SORT_ORDER_ASC;
  end;

  Result := Format(SQL_CREATE_INDEX, [ATableName, FieldName, ATableName, FieldName, LOrderStr]);
end;


{ TCompositeIndexDefinition }
function TCompositeIndexDefinition.BuildDefinition(const ATableName: string): string;
var
  LFields: string;
  LOrderStr: string;
begin
  case Order of
    ioAsc: LOrderStr := SORT_ORDER_ASC;
    ioDesc: LOrderStr := SORT_ORDER_DESC;
  else
    LOrderStr := SORT_ORDER_ASC;
  end;

  LFields := String.Join(', ', FieldNames);

  if LFields = '' then
    raise Exception.Create(EXCEPTION_THE_FIELD_LIST_FOR_THE_COMPOSITE_INDEX_IS_EMPTY);

  Result := Format(SQL_CREATE_INDEX_IF_NOT_EXISTS, [IndexName, ATableName, LFields, LOrderStr]);
end;


{ TFieldConfigurator - Public }
constructor TFieldConfigurator.Create(ATableDefinition: ITableDefinition; AFieldIndex: Integer);
begin
  inherited Create;
  FTableDefinition := ATableDefinition;
  FCurrentFieldIndex := AFieldIndex;
end;

function TFieldConfigurator.AutoIncrement: IFieldConfigurator;
begin
  FTableDefinition.SetFieldAutoIncrement(FCurrentFieldIndex, True);

  Result := Self;
end;

function TFieldConfigurator.Check(const ACheckClause: string): IFieldConfigurator;
begin
  FTableDefinition.SetFieldCheckClause(FCurrentFieldIndex, ACheckClause);

  Result := Self;
end;

function TFieldConfigurator.EndField: ITableDefinition;
begin
  Result := FTableDefinition;
end;

function TFieldConfigurator.NotNull: IFieldConfigurator;
begin
  FTableDefinition.AddOptionToField(FCurrentFieldIndex, foNotNull);

  Result := Self;
end;

function TFieldConfigurator.PrimaryKey: IFieldConfigurator;
begin
  FTableDefinition.AddOptionToField(FCurrentFieldIndex, foPrimaryKey);

  Result := Self;
end;

function TFieldConfigurator.Unique: IFieldConfigurator;
begin
  FTableDefinition.AddOptionToField(FCurrentFieldIndex, foUnique);

  Result := Self;
end;


{ TTableDefinition - Private }
function TTableDefinition.FieldExists(const AFieldName: string): Boolean;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text := Format(SQL_TABLE_COLUMNS_INFO, [QuotedStr(FTableName)]);
    LQuery.Open;
    Result := False;
    while not LQuery.Eof do
    begin
      if LQuery.FieldByName('name').AsString = AFieldName then
      begin
        Result := True;
        Break;
      end;
      LQuery.Next;
    end;
  finally
    LQuery.Free;
  end;
end;

procedure TTableDefinition.ValidateNotNullField(const AFieldName: string; AOptions: TFieldOptions; const ADefaultValue: string);
begin
  if (foNotNull in AOptions) and (ADefaultValue = '') then
    raise Exception.CreateFmt(EXCEPTION_CANNOT_ADD_NOT_NULL_WITHOUT_DEFAULT_VALUE, [AFieldName]);
end;

function TTableDefinition.GenerateCompositeIndexName(const AFieldNames: TArray<string>): string;
begin
  Result := 'idx_comp_' + String.Join('_', AFieldNames);
end;

function TTableDefinition.IndexExists(const AIndexName: string): Boolean;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text := Format(SQL_SELECT_COUNT_INDEX_FROM_MASTER, [QuotedStr(AIndexName)]);
    LQuery.Open;
    Result := LQuery.Fields[0].AsInteger > 0;
  finally
    LQuery.Free;
  end;
end;

function TTableDefinition.TableExists: Boolean;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text := SQL_CHECK_TABLE_EXISTS;
    LQuery.ParamByName('TableName').AsString := FTableName;
    LQuery.Open;

    Result := LQuery.Fields[0].AsInteger > 0;
  finally
    LQuery.Free;
  end;
end;


{ TTableDefinition - Public }
constructor TTableDefinition.Create(const ATableName: string; AConnection: TFDConnection);
begin
  if ATableName.Trim.IsEmpty then
    raise EArgumentException.Create(EXCEPTION_TABLE_NAME_CANNOT_BE_EMPTY);

  inherited Create;
  FTableName := ATableName;
  FConnection := AConnection;
  SetLength(FFields, 0);
end;

function TTableDefinition.AddCompositeIndex(const AFieldNames: TArray<string>; AOrder: TIndexOrder; const AIndexName: string = ''): ITableDefinition;
var
  LCompositeIndex: TCompositeIndexDefinition;
  LGeneratedIndexName: string;
begin
  // If index name was not provided, generate one automatically
  if AIndexName.IsEmpty then
    LGeneratedIndexName := GenerateCompositeIndexName(AFieldNames)
  else
    LGeneratedIndexName := AIndexName;

  LCompositeIndex.IndexName := LGeneratedIndexName;
  LCompositeIndex.FieldNames := Copy(AFieldNames, 0, Length(AFieldNames));
  LCompositeIndex.Order := AOrder;

  // Add CompositeIndex to the composite index array
  SetLength(FCompositeIndexes, Length(FCompositeIndexes) + 1);
  FCompositeIndexes[High(FCompositeIndexes)] := LCompositeIndex;

  Result := Self;
end;

function TTableDefinition.AddField(const AFieldName: string; AFieldType: TSQLiteFieldType; ASize: Integer): IFieldConfigurator;
var
  LFieldDef: TFieldDefinition;
begin
  // Optional validation for NOT NULL without default value
  ValidateNotNullField(AFieldName, [], '');
  LFieldDef.FieldName := AFieldName;
  LFieldDef.FieldType := AFieldType;
  LFieldDef.Size := ASize;
  LFieldDef.Options := [];
  LFieldDef.CheckClause := '';
  SetLength(FFields, Length(FFields) + 1);
  FFields[High(FFields)] := LFieldDef;

  Result := TFieldConfigurator.Create(Self, High(FFields));
end;

function TTableDefinition.AddFieldToExistingTable(const AFieldName: string; AFieldType: TSQLiteFieldType; ASize: Integer = 0; AOptions: TFieldOptions = []; const ACheckClause: string = ''; const ADefaultValue: string = ''): ITableDefinition;
var
  LSQL, LFieldType, LConstraints, LDefault: string;
begin
  if not TableExists then
    raise Exception.CreateFmt(EXCEPTION_TABLE_DOES_NOT_EXIST, [FTableName]);

  if FieldExists(AFieldName) then
    raise Exception.CreateFmt(EXCEPTION_FIELD_ALREADY_EXISTS_IN_TABLE, [AFieldName, FTableName]);

  ValidateNotNullField(AFieldName, AOptions, ADefaultValue);

  LFieldType := TSQLite4D.FieldTypeToString(AFieldType);

  if (ASize > 0) and (AFieldType = sftTEXT) then
    LFieldType := Format('%s(%d)', [LFieldType, ASize]);

  LConstraints := '';

  if foNotNull in AOptions then
    LConstraints := LConstraints + FIELD_CONSTRAINT_NOT_NULL;

  if foUnique in AOptions then
    LConstraints := LConstraints + FIELD_CONSTRAINT_UNIQUE;

  if ACheckClause <> '' then
    LConstraints := LConstraints + ' CHECK(' + ACheckClause + ')';

  if ADefaultValue <> '' then
    LDefault := ' DEFAULT ' + ADefaultValue;

  // Add the field directly with all options
  LSQL := Format(SQL_ALTER_TABLE_ADD_COLUMN, [FTableName, AFieldName, LFieldType, LConstraints + LDefault]);
  FConnection.ExecSQL(LSQL);

  Result := Self;
end;

function TTableDefinition.AddForeignKey(const AFieldName, AReferenceTable, AReferenceField, AOnDelete, AOnUpdate, AMatch: string): ITableDefinition;
var
  LForeignKeyDef: TForeignKeyDefinition;
begin
  LForeignKeyDef.FieldName := AFieldName;
  LForeignKeyDef.ReferenceTable := AReferenceTable;
  LForeignKeyDef.ReferenceField := AReferenceField;
  LForeignKeyDef.OnDelete := AOnDelete;
  LForeignKeyDef.OnUpdate := AOnUpdate;
  LForeignKeyDef.Match := AMatch;
  SetLength(FForeignKeys, Length(FForeignKeys) + 1);
  FForeignKeys[High(FForeignKeys)] := LForeignKeyDef;

  Result := Self;
end;

function TTableDefinition.AddIndex(const AFieldName: string; AOrder: TIndexOrder): ITableDefinition;
var
  LIndexDef: TIndexDefinition;
begin
  LIndexDef.FieldName := AFieldName;
  LIndexDef.Order := AOrder;
  SetLength(FIndexes, Length(FIndexes) + 1);
  FIndexes[High(FIndexes)] := LIndexDef;

  Result := Self;
end;

function TTableDefinition.DropIndex(const AIndexName: string): ITableDefinition;
var
  LQuery: TFDQuery;
  LIndexExists: Boolean;
begin
  if not FConnection.Connected then
    raise Exception.Create(EXCEPTION_DATABASE_CONNECTION_INACTIVE);

  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    // Check if the index exists
    LQuery.SQL.Text := Format(SQL_SELECT_COUNT_INDEX_FROM_MASTER, [QuotedStr(AIndexName)]);
    LQuery.Open;

    LIndexExists := LQuery.Fields[0].AsInteger > 0;
    LQuery.Close;

    if LIndexExists then
    begin
      // Delete the index
      FConnection.ExecSQL(Format(SQL_DROP_INDEX_IF_EXISTS, [AIndexName]));
    end
    else
    begin
      raise Exception.CreateFmt(EXCEPTION_INDEX_DOES_NOT_EXIST, [AIndexName]);
    end;
  finally
    LQuery.Free;
  end;

  Result := Self;
end;

procedure TTableDefinition.AddOptionToField(AFieldIndex: Integer; AOption: TFieldOption);
begin
  if (AFieldIndex < 0) or (AFieldIndex >= Length(FFields)) then
    raise EArgumentOutOfRangeException.Create(EXCEPTION_FIELD_INDEX_OUT_OF_BOUNDS);

  Include(FFields[AFieldIndex].Options, AOption);
end;

procedure TTableDefinition.BuildCompositeIndexes;
var
  LCompositeIndexIndex, LFieldNameIndex: Integer;
  LCompositeIndex: TCompositeIndexDefinition;
begin
  if not TableExists then
    raise Exception.CreateFmt(EXCEPTION_TABLE_DOES_NOT_EXIST, [FTableName]);

  for LCompositeIndexIndex := Low(FCompositeIndexes) to High(FCompositeIndexes) do
  begin
    LCompositeIndex := FCompositeIndexes[LCompositeIndexIndex];

    // Checks if the index already exists
    if IndexExists(LCompositeIndex.IndexName) then
    begin
      //Continue; // Skip to the next index, as this one already exists
      raise Exception.CreateFmt(EXCEPTION_INDEX_ALREADY_EXISTS_IN_TABLE, [LCompositeIndex.IndexName, FTableName]);
    end;

    // Checks whether each field in the composite index exists
    for LFieldNameIndex := Low(LCompositeIndex.FieldNames) to High(LCompositeIndex.FieldNames) do
    begin
      if not FieldExists(LCompositeIndex.FieldNames[LFieldNameIndex]) then
        raise Exception.CreateFmt(EXCEPTION_FIELD_DOES_NOT_EXIST_IN_TABLE, [LCompositeIndex.FieldNames[LFieldNameIndex], FTableName]);
    end;

    // If the index does not exist and all fields exist, construct the composite index
    FConnection.ExecSQL(LCompositeIndex.BuildDefinition(FTableName));
  end;
end;

procedure TTableDefinition.BuildIndexes;
var
  LIndexDefinitionIndex: Integer;
  LIndexName: string;
begin
  if not TableExists then
    raise Exception.CreateFmt(EXCEPTION_TABLE_DOES_NOT_EXIST, [FTableName]);

  for LIndexDefinitionIndex := Low(FIndexes) to High(FIndexes) do
  begin
    if not FieldExists(FIndexes[LIndexDefinitionIndex].FieldName) then
      raise Exception.CreateFmt(EXCEPTION_FIELD_DOES_NOT_EXIST_IN_TABLE, [FIndexes[LIndexDefinitionIndex].FieldName, FTableName]);

    LIndexname := Format('idx_%s_%s', [FTableName, FIndexes[LIndexDefinitionIndex].FieldName]);
    if IndexExists(LIndexName) then
      raise Exception.CreateFmt(EXCEPTION_INDEX_ALREADY_EXISTS, [LIndexName]);

    FConnection.ExecSQL(FIndexes[LIndexDefinitionIndex].BuildDefinition(FTableName));
  end;
end;

procedure TTableDefinition.BuildTable;
var
  LSQLCreateTable, LFieldsStr, LForeignKeysStr: string;
  LFieldIndex, LForeignKeyIndex: Integer;
begin
  if TableExists then
    raise Exception.CreateFmt(EXCEPTION_TABLE_ALREADY_EXISTS, [FTableName]);

  // Builds the table fields
  LFieldsStr := '';
  for LFieldIndex := Low(FFields) to High(FFields) do
  begin
    if LFieldIndex > Low(FFields) then
      LFieldsStr := LFieldsStr + ', ';
    LFieldsStr := LFieldsStr + FFields[LFieldIndex].BuildDefinition;
  end;

  // Builds foreign keys
  LForeignKeysStr := '';
  for LForeignKeyIndex := Low(FForeignKeys) to High(FForeignKeys) do
  begin
    if LForeignKeysStr <> '' then
      LForeignKeysStr := LForeignKeysStr + ', ';
    LForeignKeysStr := LForeignKeysStr + FForeignKeys[LForeignKeyIndex].BuildDefinition;
  end;

  if LForeignKeysStr <> '' then
    LFieldsStr := LFieldsStr + ', ' + LForeignKeysStr;

  // Create the table
  LSQLCreateTable := Format(SQL_CREATE_TABLE, [FTableName, LFieldsStr]);

  FConnection.ExecSQL(LSQLCreateTable);
end;

procedure TTableDefinition.SetFieldAutoIncrement(AFieldIndex: Integer; AIsAutoIncrement: Boolean);
begin
  if (AFieldIndex >= 0) and (AFieldIndex < Length(FFields)) then
  begin
    if FFields[AFieldIndex].FieldType = sftINTEGER then
    begin
      FFields[AFieldIndex].IsAutoIncrement := AIsAutoIncrement;
    end
    else
    begin
      raise Exception.Create(EXCEPTION_AUTOINCREMENT_ONLY_INTEGER);
    end;
  end
  else
    raise Exception.Create(EXCEPTION_FIELD_INDEX_OUT_OF_BOUNDS);
end;

procedure TTableDefinition.SetFieldCheckClause(AFieldIndex: Integer; const ACheckClause: string);
begin
  if (AFieldIndex >= 0) and (AFieldIndex < Length(FFields)) then
  begin
    FFields[AFieldIndex].CheckClause := ACheckClause;
  end
  else
    raise Exception.Create(EXCEPTION_FIELD_INDEX_OUT_OF_BOUNDS);
end;


{ TSQLiteHelper - Private }
constructor TSQLite4D.CreatePrivate(const ADatabasePath: string);
begin
  inherited Create;
  try
    FConnection := TFDConnection.Create(nil);
    FConnection.DriverName := SQLITE_DRIVER_NAME;
    FConnection.Params.Values['Database'] := ADatabasePath;
    FConnection.LoginPrompt := False;
    FConnection.Connected := True;

    // For deleting and later recreating indexes
    FIndexDefs := TStringList.Create;
  except
    on E: Exception do
    begin
      FConnection := nil;
      raise Exception.Create(EXCEPTION_DATABASE_CONNECTION_INACTIVE + E.Message);
    end;
  end;
end;

class function TSQLite4D.FieldTypeToString(AFieldType: TSQLiteFieldType): string;
begin
  case AFieldType of
    sftBLOB: Result := FIELD_TYPE_BLOB;
    sftINTEGER: Result := FIELD_TYPE_INTEGER;
    sftNUMERIC: Result := FIELD_TYPE_NUMERIC;
    sftREAL: Result := FIELD_TYPE_REAL;
    sftTEXT: Result := FIELD_TYPE_TEXT;
  else
    Result := FIELD_TYPE_UNKNOWN;
  end;
end;

procedure TSQLite4D.ToggleTableIndexes(ATableName: string; AEnable: Boolean);
var
  LIndexQuery: TFDQuery;
  LIndexDefinitionIndex: Integer;
  LCurrentIndexName: string;
begin
  LIndexQuery := TFDQuery.Create(nil);
  try
    LIndexQuery.Connection := FConnection;

    if AEnable then
    begin
      // Recreates indexes using SQL definitions previously stored in FIndexDefs
      for LIndexDefinitionIndex := 0 to FIndexDefs.Count - 1 do
      begin
        FConnection.ExecSQL(FIndexDefs[LIndexDefinitionIndex]);
      end;

      // Clear settings after rebuilding indexes
      FIndexDefs.Clear;
    end
    else
    begin
      // Clears previous settings
      FIndexDefs.Clear;

      // Captures the names and SQL definitions of all indexes for TableName
      LIndexQuery.SQL.Text := Format(SQL_SELECT_INDEXES_INFO, [ATableName]);
      LIndexQuery.Open;
      while not LIndexQuery.Eof do
      begin
        // Captures the index name
        LCurrentIndexName := LIndexQuery.Fields[0].AsString;

        // Stores the SQL definition of the index
        FIndexDefs.Add(LIndexQuery.Fields[1].AsString);

        // Deletes the index by name
        FConnection.ExecSQL(Format(SQL_DROP_INDEX_IF_EXISTS, [LCurrentIndexName]));

        LIndexQuery.Next;
      end;
      LIndexQuery.Close;
    end;
  finally
    LIndexQuery.Free;
  end;
end;

{ TSQLiteHelper - Public }
destructor TSQLite4D.Destroy;
begin
  if Assigned(FConnection) then
    FConnection.Free;

  // For deletion and subsequent recreation of indexes
  if Assigned(FIndexDefs) then
    FIndexDefs.Free;

  inherited Destroy;
end;

class function TSQLite4D.GetInstance(const ADatabasePath: string = ''): TSQLite4D;
begin
  // If there is no instance, create a new one
  if not Assigned(FInstance) then
  begin
    // Checks if the database path was provided on the first call
    if ADatabasePath = '' then
      raise Exception.Create(EXCEPTION_DATABASE_PATH_IS_MANDATORY_FIRST_BOOT);

    // Create the instance using the private constructor
    FInstance := TSQLite4D.CreatePrivate(ADatabasePath);
  end;

  Result := FInstance;
end;

class procedure TSQLite4D.ReleaseInstance;
begin
  if Assigned(FInstance) then
  begin
    // Closes the connection and frees resources
    if Assigned(FInstance.FConnection) then
    begin
      FInstance.FConnection.Close;
      FreeAndNil(FInstance.FConnection);
    end;

    if Assigned(FInstance.FIndexDefs) then
      FreeAndNil(FInstance.FIndexDefs);

    // Releases the singleton instance
    FreeAndNil(FInstance);
  end;
end;

function TSQLite4D.CreateSQLiteTableFromMemTable(AMemTable: TFDMemTable; const ATableName: string; const ForceRecreate: Boolean): boolean;
  function TableExists(const TableName: string): Boolean;
  var
    LQuery: TFDQuery;
  begin
    Result := False;

    if not FConnection.Connected then
      raise Exception.Create('Database connection is not active.');

    LQuery := TFDQuery.Create(nil);
    try
      LQuery.Connection := FConnection;
      LQuery.SQL.Text := 'SELECT COUNT(*) FROM sqlite_master WHERE type = ''table'' AND name = :TableName;';
      LQuery.ParamByName('TableName').AsString := TableName;
      LQuery.Open;

      Result := LQuery.Fields[0].AsInteger > 0;
    finally
      LQuery.Free;
    end;
  end;
var
  LTableDef: ITableDefinition;
  LIndexDef: TIndexDef;
begin
  Result := False;

  if not Assigned(AMemTable) then
    raise Exception.Create('The MemTable cannot be nil.');

  if ATableName.Trim.IsEmpty then
    raise Exception.Create('The table name cannot be empty.');

  if not FConnection.Connected then
    raise Exception.Create('Database connection is not active.');

  try
    FConnection.StartTransaction;

    // If the table already exists and forced to be recreated, delete it
    if ForceRecreate and TableExists(ATableName) then
    begin
      if not DeleteTable(ATableName) then
        raise Exception.CreateFmt('Failed to delete table "%s".', [ATableName]);
    end;

    // Create table definition
    LTableDef := CreateTable(ATableName);

    for var I := 0 to AMemTable.FieldDefs.Count - 1 do
    begin
      var Field := AMemTable.Fields[I];
      var FieldType := MapFDFieldTypeToSQLite(Field);

      // Add field to table
      with LTableDef.AddField(Field.FieldName, FieldType, Field.Size) do
      begin
        if Field.FieldKind = fkData then
        begin
          // Identify primary keys
          if Field.Tag = 1 then
            PrimaryKey;

          if Field.Required then
            NotNull;
        end;

        EndField;
      end;
    end;

    // Build the table
    LTableDef.BuildTable;

    // Check indexes in MemTable
    if AMemTable.IndexDefs.Count > 0 then
    begin
      for var I := 0 to AMemTable.IndexDefs.Count - 1 do
      begin
        LIndexDef := AMemTable.IndexDefs[I];

        // Split the index fields
        var FieldNames := LIndexDef.Fields.Split([',']);

        if Length(FieldNames) = 1 then
        begin
          // Simple index
          LTableDef.AddIndex(FieldNames[0], ioAsc);
        end
        else if Length(FieldNames) > 1 then
        begin
          // Composite index
          LTableDef.AddCompositeIndex(FieldNames, ioAsc, LIndexDef.Name);
        end;
      end;

      // Build the indexes
      LTableDef.BuildIndexes;
      LTableDef.BuildCompositeIndexes;
    end;

    FConnection.Commit;

    Result := True;
  except
    on E: Exception do
    begin
      FConnection.Rollback;
      raise Exception.CreateFmt('Failed to create table "%s" - %s', [ATableName, E.Message]);
    end;
  end;
end;

function TSQLite4D.CreateTable(const ATableName: string): ITableDefinition;
begin
  Result := TTableDefinition.Create(ATableName, FConnection);
end;

function TSQLite4D.DeleteDatabase: Boolean;
var
  LDatabasePath: string;
begin
  Result := False;

  if not FConnection.Connected then
    raise Exception.Create(EXCEPTION_DATABASE_CONNECTION_INACTIVE);

  LDatabasePath := FConnection.Params.Values['Database'];
  FConnection.Connected := False;

  if FileExists(LDatabasePath) then
  begin
    if DeleteFile(LDatabasePath) then
      Result := True
    else
      raise Exception.CreateFmt(EXCEPTION_FAILED_DELETE_DATABASE_FILE, [LDatabasePath]);
  end
  else
    raise Exception.CreateFmt(EXCEPTION_DATABASE_FILE_NAME_NOT_FOUND, [LDatabasePath]);
end;

function TSQLite4D.DeleteTable(const ATableName: string): Boolean;
var
  LQuery: TFDQuery;
  LForeignKeysQuery: TFDQuery;
  LHasForeignKeys: Boolean;
  LDatabasePath: string;
begin
  Result := False;

  if not FConnection.Connected then
    raise Exception.Create(EXCEPTION_DATABASE_CONNECTION_INACTIVE);

  // Check if the database still exists
  LDatabasePath := FConnection.Params.Values['Database'];
  if not FileExists(LDatabasePath) then
    raise Exception.Create(EXCEPTION_DATABASE_FILE_NOT_FOUND);

  LQuery := TFDQuery.Create(nil);
  LForeignKeysQuery := TFDQuery.Create(nil);
  try
    // Check if the table exists
    LQuery.Connection := FConnection;
    LQuery.SQL.Text := SQL_CHECK_TABLE_EXISTS;
    LQuery.Params.ParamByName('TableName').AsString := ATableName;
    LQuery.Open;

    if LQuery.Fields[0].AsInteger = 0 then
      raise Exception.CreateFmt(EXCEPTION_TABLE_DOES_NOT_EXIST, [ATableName]);

    // Check dependencies (foreign keys)
    LForeignKeysQuery.Connection := FConnection;
    LForeignKeysQuery.SQL.Text := Format(SQL_PRAGMA_FOREIGN_KEY_LIST, [QuotedStr(ATableName)]);
    LForeignKeysQuery.Open;
    LHasForeignKeys := not LForeignKeysQuery.IsEmpty;

    if LHasForeignKeys then
      raise Exception.CreateFmt(EXCEPTION_TABLE_HAS_FOREIGN_KEY_DEPENDENCIES_DELETION_ABORTED, [ATableName]);

    // Close related connections and delete indexes
    ToggleTableIndexes(ATableName, False);

    // Delete the table
    FConnection.ExecSQL(Format(SQL_DROP_TABLE_IF_EXISTS, [ATableName]));

    Result := True;
  finally
    LQuery.Free;
    LForeignKeysQuery.Free;
  end;
end;

function TSQLite4D.ExecuteSQLScalar(const ASQL: string; UseTransaction: Boolean): Variant;
(* The ExecuteSQLScalar method is used for SQL queries that return a single
   value, such as:
   1. Counting records (SELECT COUNT()).
   2. Retrieving an ID or aggregated value (SELECT MAX(ID) or SELECT SUM(Sales)).

   Unlike ExecuteSQL, it does not use transactions by default (UseTransaction
   = False). This is because simple read-only queries generally do not require
   transactional guarantees. However, in scenarios where read consistency is
   critical, the UseTransaction parameter can be set to True, as in the
   following example:

   OrderID := SQLite4D.ExecuteSQLScalar('SELECT OrderID FROM Orders WHERE
              UserID = 1 LIMIT 1;', True);

   This method is ideal for quickly retrieving specific information without the
   overhead of handling datasets or more complex structures. *)
var
  LQuery: TFDQuery;
begin
  if not Assigned(FConnection) or not FConnection.Connected then
    raise Exception.Create(EXCEPTION_DATABASE_CONNECTION_INACTIVE);

  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;

    if UseTransaction then
      FConnection.StartTransaction;

    try
      LQuery.SQL.Text := ASQL;
      LQuery.Open;

      if not LQuery.IsEmpty then
        Result := LQuery.Fields[0].Value
      else
        Result := VarNull;

      if UseTransaction then
        FConnection.Commit;
    except
      on E: Exception do
      begin
        if UseTransaction then
          FConnection.Rollback;
        raise Exception.CreateFmt(EXCEPTION_ERROR_EXECUTING_SQL, [ASQL, E.Message]);
      end;
    end;
  finally
    LQuery.Free;
  end;
end;

function TSQLite4D.GetConnection: TFDConnection;
begin
  if not Assigned(FConnection) then
    raise Exception.Create(EXCEPTION_CONNECTION_IS_NOT_INITIALIZED);

  Result := FConnection;
end;

function TSQLite4D.GetDatabaseStructure: TStringList;
// No constants were created to represent SQL commands
var
  LQueryTables, LQueryFields, LQueryIndexes, LQueryIndexDetails, LForeignKeysQuery: TFDQuery;
  LTableName, LIndexName, LFieldName, LFieldType, LFieldFlags, LIndexOrder: string;
  LResult: TStringList;
begin
  if not FConnection.Connected then
    raise Exception.Create(EXCEPTION_DATABASE_CONNECTION_INACTIVE);

  LResult := TStringList.Create;
  LQueryTables := TFDQuery.Create(nil);
  LQueryFields := TFDQuery.Create(nil);
  LQueryIndexes := TFDQuery.Create(nil);
  LQueryIndexDetails := TFDQuery.Create(nil);
  LForeignKeysQuery := TFDQuery.Create(nil);
  try
    LQueryTables.Connection := FConnection;
    LQueryFields.Connection := FConnection;
    LQueryIndexes.Connection := FConnection;
    LQueryIndexDetails.Connection := FConnection;
    LForeignKeysQuery.Connection := FConnection;

    // List all tables
    LQueryTables.SQL.Text := 'SELECT name FROM sqlite_master WHERE type = ''table'';';
    LQueryTables.Open;

    while not LQueryTables.Eof do
    begin
      LTableName := LQueryTables.FieldByName('name').AsString;

      {* Retrieve the current table name from the list returned by
         sqlite_master. SQLite includes internal system tables, such as
         "sqlite_sequence", which is automatically created to track
         AUTOINCREMENT values for tables that use the AUTOINCREMENT keyword.

         Since "sqlite_sequence" does not follow the same structure or purpose
         as user-defined tables, we treat it separately to avoid applying
         regular field/index extraction logic, which could cause confusion or
         errors.

         If this is the "sqlite_sequence" table, we document its meaning and
         known fields explicitly; otherwise, we proceed with standard structure
         extraction.
      *}

      if LTableName = 'sqlite_sequence' then
      begin
        // Special handling for sqlite_sequence
        LResult.Add('  sqlite_sequence (Autoincrement Tracking)');
        LResult.Add('    Fields:');
        LResult.Add('      name (TEXT) - Table name');
        LResult.Add('      seq (INTEGER) - Current autoincrement value');
      end
      else
      begin
        // Normal tables
        LResult.Add('  ' + '[' + LTableName + ']');

        // Get table fields
        LResult.Add('    Fields:');
        LQueryFields.SQL.Text := Format('PRAGMA table_info(%s);', [LTableName]);
        LQueryFields.Open;
        while not LQueryFields.Eof do
        begin
          LFieldName := LQueryFields.FieldByName('name').AsString;
          LFieldType := LQueryFields.FieldByName('type').AsString;
          LFieldFlags := '';

          if LQueryFields.FieldByName('pk').AsInteger > 0 then
            LFieldFlags := 'PRIMARY KEY';

          LForeignKeysQuery.SQL.Text := Format('PRAGMA foreign_key_list(%s);', [LTableName]);
          LForeignKeysQuery.Open;
          while not LForeignKeysQuery.Eof do
          begin
            if LForeignKeysQuery.FieldByName('from').AsString = LFieldName then
            begin
              if LFieldFlags <> '' then
                LFieldFlags := LFieldFlags + ', ';
              LFieldFlags := LFieldFlags + 'FOREIGN KEY';
              Break;
            end;
            LForeignKeysQuery.Next;
          end;
          LForeignKeysQuery.Close;

          if LFieldFlags <> '' then
            LResult.Add(Format('      %s (%s) [%s]', [LFieldName, LFieldType, LFieldFlags]))
          else
            LResult.Add(Format('      %s (%s)', [LFieldName, LFieldType]));

          LQueryFields.Next;
        end;
        LQueryFields.Close;

        // Get table indexes
        LResult.Add('    Indexes:');
        LQueryIndexes.SQL.Text := Format('PRAGMA index_list(%s);', [LTableName]);
        LQueryIndexes.Open;
        while not LQueryIndexes.Eof do
        begin
          LIndexName := LQueryIndexes.FieldByName('name').AsString;
          LIndexOrder := 'ASC'; // Default

          // Check index details
          LQueryIndexDetails.SQL.Text := Format('PRAGMA index_info(%s);', [LIndexName]);
          LQueryIndexDetails.Open;
          if LQueryIndexDetails.FindField('desc') <> nil then
          begin
            if LQueryIndexDetails.FieldByName('desc').AsInteger = 1 then
              LIndexOrder := 'DESC';
          end;

          LResult.Add(Format('      %s (%s)', [LIndexName, LIndexOrder]));

          while not LQueryIndexDetails.Eof do
          begin
            LFieldName := LQueryIndexDetails.FieldByName('name').AsString;
            LResult.Add('        Field: ' + LFieldName);
            LQueryIndexDetails.Next;
          end;
          LQueryIndexDetails.Close;

          LQueryIndexes.Next;
        end;
        LQueryIndexes.Close;
      end;

      LQueryTables.Next;
    end;
    LQueryTables.Close;
  finally
    LQueryTables.Free;
    LQueryFields.Free;
    LQueryIndexes.Free;
    LQueryIndexDetails.Free;
    LForeignKeysQuery.Free;
  end;

  Result := LResult;
end;

function TSQLite4D.IsConnected: Boolean;
begin
  Result := Assigned(FConnection) and FConnection.Connected;
end;

function TSQLite4D.MapFDFieldTypeToSQLite(const AField: TField): TSQLiteFieldType;
begin
  case AField.DataType of
    // Text types and characters
    TFieldType.ftString,
    TFieldType.ftWideString,
    TFieldType.ftFixedChar,
    TFieldType.ftFixedWideChar,
    TFieldType.ftMemo,
    TFieldType.ftWideMemo,
    TFieldType.ftFmtMemo,
    TFieldType.ftGuid: Result := TSQLiteFieldType.sftTEXT;

    // Integer numeric types
    TFieldType.ftSmallint,
    TFieldType.ftInteger,
    TFieldType.ftWord,
    TFieldType.ftAutoInc,
    TFieldType.ftLargeint,
    TFieldType.ftLongWord,
    TFieldType.ftShortint,
    TFieldType.ftByte: Result := TSQLiteFieldType.sftINTEGER;

    // Floating point numeric types
    TFieldType.ftFloat,
    TFieldType.ftCurrency,
    TFieldType.ftBCD,
    TFieldType.ftFMTBcd,
    TFieldType.ftExtended,
    TFieldType.ftSingle: Result := TSQLiteFieldType.sftREAL;

    // Boolean type
    TFieldType.ftBoolean: Result := TSQLiteFieldType.sftNUMERIC;

    // Date and time types
    TFieldType.ftDate,
    TFieldType.ftTime,
    TFieldType.ftDateTime,
    TFieldType.ftTimeStamp,
    TFieldType.ftTimeStampOffset,
    TFieldType.ftOraTimeStamp,
    TFieldType.ftOraInterval: Result := TSQLiteFieldType.sftTEXT;

    // Binary types and BLOBs
    TFieldType.ftBytes,
    TFieldType.ftVarBytes,
    TFieldType.ftBlob,
    TFieldType.ftGraphic,
    TFieldType.ftDBaseOle,
    TFieldType.ftTypedBinary,
    TFieldType.ftStream,
    TFieldType.ftOraBlob,
    TFieldType.ftOraClob: Result := TSQLiteFieldType.sftBLOB;

    (* Special types or those not directly supported by SQLite
       Stored as text or blob depending on the specific case
    TFieldType.ftVariant,
    TFieldType.ftInterface,
    TFieldType.ftIDispatch,
    TFieldType.ftADT,
    TFieldType.ftArray,
    TFieldType.ftReference,
    TFieldType.ftDataSet,
    TFieldType.ftConnection,
    TFieldType.ftParams,
    TFieldType.ftObject,
    TFieldType.ftCursor,
    TFieldType.ftParadoxOle: Special treatment or conversion required
    *)

    else
      raise Exception.Create(Format(EXCEPTION_UNSUPPORTED_FIELD_TYPE, [AField.ClassName]));
  end;
end;

function TSQLite4D.RenameTable(const OldTableName, NewTableName: string): Boolean;
var
  LForeignKeyCheck: TFDQuery;
  LForeignKeyCount: Integer;
  LSQL: string;
begin
  Result := False;

  if not Assigned(FConnection) or not FConnection.Connected then
    raise Exception.Create(EXCEPTION_DATABASE_CONNECTION_INACTIVE);

  // Check foreign key dependencies
  LForeignKeyCheck := TFDQuery.Create(nil);
  try
    LForeignKeyCheck.Connection := FConnection;
    LForeignKeyCheck.SQL.Text := Format(SQL_PRAGMA_FOREIGN_KEY_LIST, [QuotedStr(OldTableName)]);
    LForeignKeyCheck.Open;

    LForeignKeyCount := 0;
    while not LForeignKeyCheck.Eof do
    begin
      Inc(LForeignKeyCount);
      LForeignKeyCheck.Next;
    end;

    if LForeignKeyCount > 0 then
      raise Exception.CreateFmt(EXCEPTION_CANNOT_RENAME_TABLE_BECAUSE_FOREIGN_KEY_DEPENDENCIES, [OldTableName]);
  finally
    LForeignKeyCheck.Free;
  end;

  // Rename the table
  try
    LSQL := Format(SQL_RENAME_TABLE, [OldTableName, NewTableName]);
    FConnection.ExecSQL(LSQL);
    Result := True;
  except
    on E: Exception do
      raise Exception.CreateFmt(EXCEPTION_ERROR_RENAMING_TABLE, [OldTableName, NewTableName, E.Message]);
  end;
end;

procedure TSQLite4D.CopyDataFromMemTableToSQLite(const ATableName: string; AMemTable: TFDMemTable; ABatchSize: Integer = 500; AProgressCallback: TProgressCallback = nil);
var
  LSQLiteQuery: TFDQuery;
  LFieldIndex, LBatchIndex: Integer;
  LSQLInsert, LFields, LParams: string;
  LFieldCount, LTotalRecords, LRecordsProcessed: Integer;
  LParamName: string;
begin
  if not Assigned(AMemTable) then
    raise Exception.Create(EXCEPTION_MEMTABLE_CANNOT_BE_NIL);

  LSQLiteQuery := TFDQuery.Create(nil);
  try
    LSQLiteQuery.Connection := FConnection;

    // Deletes the Indexes
    ToggleTableIndexes(ATableName, False);

    LFields := '';
    LParams := '';
    LFieldCount := AMemTable.FieldDefs.Count;
    for LFieldIndex := 0 to LFieldCount - 1 do
    begin
      if LFields <> '' then
      begin
        LFields := LFields + ', ';
        LParams := LParams + ', ';
      end;
      LFields := LFields + AMemTable.FieldDefs[LFieldIndex].Name;
      LParams := LParams + ':P' + IntToStr(LFieldIndex);
    end;

    LSQLInsert := Format(SQL_INSERT_INTO_VALUES, [ATableName, LFields, LParams]);
    LSQLiteQuery.SQL.Text := LSQLInsert;

    LTotalRecords := AMemTable.RecordCount;
    LRecordsProcessed := 0;

    FConnection.StartTransaction;
    try
      AMemTable.First;
      while not AMemTable.Eof do
      begin
        LSQLiteQuery.Params.ArraySize := Min(ABatchSize, LTotalRecords - LRecordsProcessed);
        LBatchIndex := 0;

        while (not AMemTable.Eof) and (LBatchIndex < LSQLiteQuery.Params.ArraySize) do
        begin
          for LFieldIndex := 0 to LFieldCount - 1 do
          begin
            LParamName := 'P' + IntToStr(LFieldIndex);
            // Assigning values according to the type of data
            case AMemTable.Fields[LFieldIndex].DataType of
              // Strings and characters
              TFieldType.ftString,
              TFieldType.ftWideString,
              TFieldType.ftFixedChar,
              TFieldType.ftFixedWideChar,
              TFieldType.ftGuid : LSQLiteQuery.ParamByName(LParamName).AsStrings[LBatchIndex] := AMemTable.Fields[LFieldIndex].AsString;

              // Memo
              TFieldType.ftMemo,
              TFieldType.ftWideMemo,
              TFieldType.ftFmtMemo : LSQLiteQuery.ParamByName(LParamName).AsMemos[LBatchIndex] := AMemTable.Fields[LFieldIndex].AsString;

              // Integer numeric types
              TFieldType.ftSmallint,
              TFieldType.ftInteger,
              TFieldType.ftWord,
              TFieldType.ftAutoInc,
              TFieldType.ftLargeint,
              TFieldType.ftLongWord,
              TFieldType.ftShortint,
              TFieldType.ftByte: LSQLiteQuery.ParamByName(LParamName).AsIntegers[LBatchIndex] := AMemTable.Fields[LFieldIndex].AsInteger;

              // Floating point numeric types
              TFieldType.ftFloat,
              TFieldType.ftCurrency,
              TFieldType.ftBCD,
              TFieldType.ftFMTBcd,
              TFieldType.ftExtended,
              TFieldType.ftSingle: LSQLiteQuery.ParamByName(LParamName).AsFloats[LBatchIndex] := AMemTable.Fields[LFieldIndex].AsFloat;

              // Boolean type
              TFieldType.ftBoolean: LSQLiteQuery.ParamByName(LParamName).AsBooleans[LBatchIndex] := AMemTable.Fields[LFieldIndex].AsBoolean;

              // Date and time types
              TFieldType.ftDate : LSQLiteQuery.ParamByName(LParamName).AsDates[LBatchIndex] := AMemTable.Fields[LFieldIndex].AsDateTime;
              TFieldType.ftTime : LSQLiteQuery.ParamByName(LParamName).AsTimes[LBatchIndex] := AMemTable.Fields[LFieldIndex].AsDateTime;

              TFieldType.ftDateTime,
              TFieldType.ftTimeStamp,
              TFieldType.ftTimeStampOffset,
              TFieldType.ftOraTimeStamp,
              TFieldType.ftOraInterval: LSQLiteQuery.ParamByName(LParamName).AsDateTimes[LBatchIndex] := AMemTable.Fields[LFieldIndex].AsDateTime;
            end;
          end;
          Inc(LBatchIndex);
          AMemTable.Next;
        end;

        LSQLiteQuery.Execute(LSQLiteQuery.Params.ArraySize, 0);
        // Updates the total number of records processed
        Inc(LRecordsProcessed, LBatchIndex);

        // Updates progress after each batch processed
        if Assigned(AProgressCallback) then
        begin
          TThread.Queue(TThread.CurrentThread,
            procedure
            begin
              AProgressCallback((LRecordsProcessed * 100) div LTotalRecords);
            end);
        end;
      end;

      FConnection.Commit;
    except
      on E: Exception do
      begin
        FConnection.Rollback;
        raise Exception.CreateFmt(EXCEPTION_TRANSACTION_FAILED_COPYING_DATA_FOR_TABLE, [ATableName, E.Message]);
      end;
    end;
  finally
    // Recreate the Indexes
    ToggleTableIndexes(ATableName, True);
    LSQLiteQuery.Free;
  end;
end;

function TSQLite4D.ExecuteMultipleSQL(const ASQLCommands: TArray<string>): Boolean;
var
  LCommand: string;
begin
  if not Assigned(FConnection) or not FConnection.Connected then
    raise Exception.Create('Database connection is not active.');

  FConnection.StartTransaction;
  try
    for LCommand in ASQLCommands do
    begin
      FConnection.ExecSQL(LCommand);
    end;
    FConnection.Commit;
    Result := True;
  except
    on E: Exception do
    begin
      FConnection.Rollback;
      raise Exception.Create('Error executing multiple SQL commands: ' + E.Message);
    end;
  end;
end;

procedure TSQLite4D.ExecuteSQL(const ASQL: string; UseTransaction: Boolean);
(* The ExecuteSQL method is designed to execute SQL commands that do not
   return any results, such as:
   1. Inserting data (INSERT INTO).
   2. Updating records (UPDATE).
   3. Deleting data (DELETE).
   4. Creating or modifying structures (CREATE TABLE, ALTER TABLE).

   This method includes built-in support for transactions, controlled by an
   optional parameter (UseTransaction, default True). Transactions ensure that
   operations are atomic, and if something goes wrong, the database remains in
   a consistent state. For example:

   SQLite4D.ExecuteSQL('UPDATE Customers SET Balance = Balance + 100
                       WHERE ID = 1');

   Transactions are especially crucial for data-modifying operations, such as
   multiple INSERTs, where using a transaction can significantly improve
   performance and reliability. *)
begin
  if not Assigned(FConnection) or not FConnection.Connected then
    raise Exception.Create(EXCEPTION_DATABASE_CONNECTION_INACTIVE);

  if UseTransaction then
  begin
    FConnection.StartTransaction;
    try
      FConnection.ExecSQL(ASQL);
      FConnection.Commit;
    except
      on E: Exception do
      begin
        FConnection.Rollback;
        raise Exception.CreateFmt(EXCEPTION_ERROR_EXECUTING_SQL, [ASQL, E.Message]);
      end;
    end;
  end
  else
  begin
    FConnection.ExecSQL(ASQL);
  end;
end;

end.

