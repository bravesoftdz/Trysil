﻿(*

  Trysil
  Copyright © David Lastrucci
  All rights reserved

  Trysil - Operation ORM (World War II)
  http://codenames.info/operation/orm/

*)
unit Trysil.Resolver;

interface

uses
  System.SysUtils,
  System.Classes,

  Trysil.Types,
  Trysil.Rtti,
  Trysil.Mapping,
  Trysil.Metadata,
  Trysil.Data,
  Trysil.Context.Abstract;

type

{ TTResolver }

  TTResolver = class
  strict private
    FContext: TTAbstractContext;
  public
    constructor Create(const AContext: TTAbstractContext);

    procedure Insert<T: class>(const AEntity: T);
    procedure Update<T: class>(const AEntity: T);
    procedure Delete<T: class>(const AEntity: T);
  end;

implementation

{ TTResolver }

constructor TTResolver.Create(const AContext: TTAbstractContext);
begin
  inherited Create;
  FContext := AContext;
end;

procedure TTResolver.Insert<T>(const AEntity: T);
var
  LTableMap: TTTableMap;
  LTableMetadata: TTTableMetadata;
  LCommand: TTDataInsertCommand;
begin
  LTableMap := FContext.Mapper.Load<T>();
  LTableMetadata := FContext.Metadata.Load<T>();
  LCommand := FContext.Connection.CreateInsertCommand(
    LTableMap, LTableMetadata);
  try
    LCommand.Execute(AEntity);
    LTableMap.VersionColumn.Member.SetValue(AEntity, 0);
  finally
    LCommand.Free;
  end;
end;

procedure TTResolver.Update<T>(const AEntity: T);
var
  LTableMap: TTTableMap;
  LTableMetadata: TTTableMetadata;
  LCommand: TTDataUpdateCommand;
begin
  LTableMap := FContext.Mapper.Load<T>();
  LTableMetadata := FContext.Metadata.Load<T>();
  LCommand := FContext.Connection.CreateUpdateCommand(
    LTableMap, LTableMetadata);
  try
    LCommand.Execute(AEntity);
    LTableMap.VersionColumn.Member.SetValue(
      AEntity,
      LTableMap.VersionColumn.Member.GetValue(AEntity).AsType<TTVersion>() + 1);
  finally
    LCommand.Free;
  end;
end;

procedure TTResolver.Delete<T>(const AEntity: T);
var
  LTableMap: TTTableMap;
  LTableMetadata: TTTableMetadata;
  LCommand: TTDataDeleteCommand;
begin
  LTableMap := FContext.Mapper.Load<T>();
  FContext.Connection.CheckRelations(LTableMap, AEntity);
  LTableMetadata := FContext.Metadata.Load<T>();
  LCommand := FContext.Connection.CreateDeleteCommand(
    LTableMap, LTableMetadata);
  try
    LCommand.Execute(AEntity);
  finally
    LCommand.Free;
  end;
end;

end.
