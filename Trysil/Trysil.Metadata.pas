﻿(*

  Trysil
  Copyright © David Lastrucci
  All rights reserved

  Trysil - Operation ORM (World War II)
  http://codenames.info/operation/orm/

*)
unit Trysil.Metadata;

interface

uses
  System.Classes,
  System.SysUtils,
  System.TypInfo,
  Data.DB,

  Trysil.Exceptions,
  Trysil.Classes,
  Trysil.Cache,
  Trysil.Mapping,
  Trysil.Generics.Collections;

type

{ TTColumnMetadata }

  TTColumnMetadata = class
  strict private
    FColumnName: String;
    FDataType: TFieldType;
    FDataSize: Integer;
  public
    constructor Create(
      const AColumnName: String;
      const ADataType: TFieldType;
      const ADataSize: Integer);

    property ColumnName: String read FColumnName;
    property DataType: TFieldType read FDataType;
    property DataSize: Integer read FDataSize;
  end;

{ TTColumnsMetadata }

  TTColumnsMetadata = class
  strict private
    FColumns: TTObjectList<TTColumnMetadata>;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Add(
      const AColumnName: String;
      const ADataType: TFieldType;
      const ADataSize: Integer);

    function GetEnumerator: TTListEnumerator<TTColumnMetadata>;
  end;

{ TTTableMetadata }

  TTTableMetadata = class
  strict private
    FTableName: String;
    FColumns: TTColumnsMetadata;
  public
    constructor Create(const ATableName: String);
    destructor Destroy; override;

    property TableName: String read FTableName;
    property Columns: TTColumnsMetadata read FColumns;
  end;

{ TTMetadataProvider }

  TTMetadataProvider = class abstract
  public
    procedure GetMetadata(
      const ATableMap: TTTableMap;
      const ATableMetadata: TTTableMetadata); virtual; abstract;
  end;

{ TTMetadata }

  TTMetadata = class(TTCacheEx<PTypeInfo, TTTableMetadata>)
  strict private
    FMapper: TTMapper;
    FMetadataProvider: TTMetadataProvider;
  strict protected
    function CreateObject(
      const ATypeInfo: PTypeInfo): TTTableMetadata; override;
  public
    constructor Create(
      const AMapper: TTMapper;
      const AMetadataProvider: TTMetadataProvider);

    function Load<T: class>(): TTTableMetaData;
  end;

implementation

{ TTColumnMetadata }

constructor TTColumnMetadata.Create(
  const AColumnName: String;
  const ADataType: TFieldType;
  const ADataSize: Integer);
begin
  inherited Create;
  FColumnName := AColumnName;
  FDataType := ADataType;
  FDataSize := ADataSize;
end;

{ TTColumnsMetadata }

constructor TTColumnsMetadata.Create;
begin
  inherited Create;
  FColumns := TTObjectList<TTColumnMetadata>.Create(True);
end;

destructor TTColumnsMetadata.Destroy;
begin
  FColumns.Free;
  inherited Destroy;
end;

procedure TTColumnsMetadata.Add(
  const AColumnName: String;
  const ADataType: TFieldType;
  const ADataSize: Integer);
begin
  FColumns.Add(TTColumnMetadata.Create(AColumnName, ADataType, ADataSize));
end;

function TTColumnsMetadata.GetEnumerator: TTListEnumerator<TTColumnMetadata>;
begin
  result := TTListEnumerator<TTColumnMetadata>.Create(FColumns);
end;

{ TTTableMetadata }

constructor TTTableMetadata.Create(const ATableName: String);
begin
  inherited Create;
  FTableName := ATableName;
  FColumns := TTColumnsMetadata.Create;
end;

destructor TTTableMetadata.Destroy;
begin
  FColumns.Free;
  inherited Destroy;
end;

{ TTMetadata }

constructor TTMetadata.Create(
  const AMapper: TTMapper; const AMetadataProvider: TTMetadataProvider);
begin
  inherited Create;
  FMapper := AMapper;
  FMetadataProvider := AMetadataProvider;
end;

function TTMetadata.CreateObject(const ATypeInfo: PTypeInfo): TTTableMetadata;
var
  LTableMap: TTTableMap;
begin
  LTableMap := FMapper.Load(ATypeInfo);
  result := TTTableMetadata.Create(LTableMap.Name);
  try
    FMetadataProvider.GetMetadata(LTableMap, result);
  except
    result.Free;
    raise;
  end;
end;

function TTMetadata.Load<T>: TTTableMetaData;
begin
  result := GetValueOrCreate(TypeInfo(T));
end;

end.
