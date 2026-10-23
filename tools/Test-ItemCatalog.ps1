param(
    [Parameter(Mandatory=$true)][string]$SourceXml,
    [Parameter(Mandatory=$true)][string]$BackupDirectory,
    [string]$PlayerBackupDirectory
)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$sourcePath=(Resolve-Path -LiteralPath $SourceXml).Path
$backupPath=(Resolve-Path -LiteralPath $BackupDirectory).Path
$clientPath=Join-Path $backupPath 'request-served-check.xml'
$served=Join-Path $backupPath 'request-served-check.zlib'
Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:8888/request/TemplateAllList.xml' -OutFile $served -TimeoutSec 20
& node (Join-Path $PSScriptRoot 'item-catalog-zlib.cjs') unpack $served $clientPath
if($LASTEXITCODE -ne 0){throw 'Served client table is not valid zlib/XML.'}
$api=[IO.File]::ReadAllText((Join-Path $root 'WebPortal/api.ashx'))
$literal=[regex]::Match([regex]::Match($api,'(?m)^\s*private const string ConnStr[^\r\n]*').Value,'@?"([^"]+)"').Groups[1].Value
$builder=New-Object Data.SqlClient.SqlConnectionStringBuilder($literal)
$builder['Initial Catalog']='Db_Tank';$builder['Connect Timeout']=5
$connection=New-Object Data.SqlClient.SqlConnection($builder.ConnectionString)
try {
    $connection.Open();$command=$connection.CreateCommand();$command.CommandText='SELECT * FROM dbo.Shop_Goods'
    $current=New-Object Data.DataTable('Shop_Goods')
    $adapter=New-Object Data.SqlClient.SqlDataAdapter($command);[void]$adapter.Fill($current)
    if($PlayerBackupDirectory){
        $command.CommandText='SELECT * FROM Db_Tank41.dbo.Shop_Goods'
        $playerCatalog=New-Object Data.DataTable('Shop_Goods')
        $adapter=New-Object Data.SqlClient.SqlDataAdapter($command);[void]$adapter.Fill($playerCatalog)
    }
} finally {$connection.Close()}
$before=New-Object Data.DataSet
[void]$before.ReadXml((Join-Path $backupPath 'Shop_Goods.xml'))
Add-Type -ReferencedAssemblies System.Data,System.Xml -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Data;
using System.Globalization;
using System.Xml;
public static class CatalogVerification {
 public static string VerifyPlayer(DataTable source,DataTable target,DataTable before) {
  var rows=new Dictionary<int,DataRow>();var oldRows=new Dictionary<int,DataRow>();var ids=new HashSet<int>();
  foreach(DataRow row in target.Rows)rows.Add((int)row["TemplateID"],row);
  foreach(DataRow row in before.Rows)oldRows.Add((int)row["TemplateID"],row);
  var preserved=new HashSet<string>(new[]{"Remark","Valid","Count","Price"});int fields=0,extra=0;
  foreach(DataRow row in source.Rows){
   int id=(int)row["TemplateID"];ids.Add(id);
   if(!rows.ContainsKey(id))throw new Exception("Player catalog missing "+id);
   foreach(DataColumn column in source.Columns){
    if(preserved.Contains(column.ColumnName))continue;
    if(!Object.Equals(row[column],rows[id][column.ColumnName]))throw new Exception("Player catalog mismatch "+id+" "+column.ColumnName);
    fields++;
   }
  }
  foreach(var pair in oldRows){
   if(!rows.ContainsKey(pair.Key))throw new Exception("Lost player catalog ID "+pair.Key);
   foreach(DataColumn column in before.Columns){
    if(ids.Contains(pair.Key)&&!preserved.Contains(column.ColumnName))continue;
    if(!Object.Equals(pair.Value[column],rows[pair.Key][column.ColumnName]))throw new Exception("Changed player-only field "+pair.Key+" "+column.ColumnName);
   }
   if(!ids.Contains(pair.Key))extra++;
  }
  if(target.Rows.Count!=source.Rows.Count+extra)throw new Exception("Unexpected player catalog count");
  return "PASS: player catalog contains all "+ids.Count+" canonical templates; "+fields+" fields match; "+extra+" player-only templates and private catalog columns preserved.";
 }
 public static string Verify(string sourcePath,string clientPath,DataTable current,DataTable before) {
  var source=new XmlDocument();source.Load(sourcePath);
  var client=new XmlDocument();client.Load(clientPath);
  var db=new Dictionary<int,DataRow>();
  foreach(DataRow row in current.Rows) db.Add((int)row["TemplateID"],row);
  var flash=new Dictionary<int,XmlElement>();
  foreach(XmlElement item in client.SelectNodes("//*[@TemplateID]")) flash.Add(Int32.Parse(item.GetAttribute("TemplateID")),item);
  var ids=new HashSet<int>();var sourceColumns=new HashSet<string>();int fields=0,preserved=0;
  foreach(XmlElement item in source.SelectNodes("//*[@TemplateID]")) {
   int id=Int32.Parse(item.GetAttribute("TemplateID"));
   if(!ids.Add(id)||!db.ContainsKey(id)||!flash.ContainsKey(id))throw new Exception("Missing/duplicate template "+id);
   foreach(XmlAttribute attribute in item.Attributes) {
    sourceColumns.Add(attribute.Name);
    if(flash[id].GetAttribute(attribute.Name)!=attribute.Value)throw new Exception("Client mismatch "+id+" "+attribute.Name);
    if(!current.Columns.Contains(attribute.Name))continue;
    object expected=Convert.ChangeType(attribute.Value,current.Columns[attribute.Name].DataType,CultureInfo.InvariantCulture);
    if(!Object.Equals(db[id][attribute.Name],expected))throw new Exception("Database mismatch "+id+" "+attribute.Name);
    fields++;
   }
  }
  foreach(DataRow old in before.Rows) {
   int id=(int)old["TemplateID"];
   if(!db.ContainsKey(id)||!flash.ContainsKey(id))throw new Exception("Lost local template "+id);
   foreach(DataColumn column in before.Columns) {
    if(ids.Contains(id)&&sourceColumns.Contains(column.ColumnName))continue;
    if(!Object.Equals(old[column.ColumnName],db[id][column.ColumnName]))throw new Exception("Changed retained field "+id+" "+column.ColumnName);
   }
   if(!ids.Contains(id))preserved++;
  }
  if(db.Count!=flash.Count)throw new Exception("Database/client item count differs");
  return "PASS: "+ids.Count+" source templates, "+fields+" database fields and all client attributes match; "+preserved+" local-only templates and database-only fields preserved; total "+db.Count+".";
 }
}
'@
$result=[CatalogVerification]::Verify($sourcePath,$clientPath,$current,$before.Tables['Shop_Goods'])
[IO.File]::WriteAllText((Join-Path $backupPath 'verification.txt'),$result)
$result
if($PlayerBackupDirectory){
    $playerBefore=New-Object Data.DataSet
    [void]$playerBefore.ReadXml((Join-Path (Resolve-Path -LiteralPath $PlayerBackupDirectory).Path 'Shop_Goods.xml'))
    $playerResult=[CatalogVerification]::VerifyPlayer($current,$playerCatalog,$playerBefore.Tables['Shop_Goods'])
    [IO.File]::WriteAllText((Join-Path (Resolve-Path -LiteralPath $PlayerBackupDirectory).Path 'verification.txt'),$playerResult)
    $playerResult
}
