param([switch]$Apply)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$api=[IO.File]::ReadAllText((Join-Path $root 'WebPortal/api.ashx'))
$literal=[regex]::Match([regex]::Match($api,'(?m)^\s*private const string ConnStr[^\r\n]*').Value,'@?"([^"]+)"').Groups[1].Value
$builder=New-Object Data.SqlClient.SqlConnectionStringBuilder($literal)
$builder['Initial Catalog']='Db_Tank41';$builder['Connect Timeout']=5
$connection=New-Object Data.SqlClient.SqlConnection($builder.ConnectionString)
$transaction=$null
try {
 $connection.Open();$command=$connection.CreateCommand()
 $command.CommandText='SELECT * FROM dbo.Shop_Goods ORDER BY TemplateID'
 $before=New-Object Data.DataTable('Shop_Goods')
 $adapter=New-Object Data.SqlClient.SqlDataAdapter($command);[void]$adapter.Fill($before)
 $command.CommandText='SELECT COUNT(*) FROM Db_Tank.dbo.Shop_Goods s WHERE NOT EXISTS (SELECT 1 FROM dbo.Shop_Goods t WHERE t.TemplateID=s.TemplateID)'
 $added=[int]$command.ExecuteScalar()
 $command.CommandText='SELECT COUNT(*) FROM Db_Tank.dbo.Shop_Goods'
 $sourceCount=[int]$command.ExecuteScalar()
 $backup=Join-Path $root ('scratch/player-item-catalog-backup-'+(Get-Date -Format 'yyyyMMdd-HHmmss'))
 New-Item -ItemType Directory -Path $backup | Out-Null
 $before.WriteXml((Join-Path $backup 'Shop_Goods.xml'),[Data.XmlWriteMode]::WriteSchema)
 $command.CommandText="SELECT COL_LENGTH('dbo.Shop_Goods','Hole')"
 $holeBytes=[int]$command.ExecuteScalar()
 $columns=@($before.Columns|ForEach-Object{$_.ColumnName})
 # Keep database-only metadata on existing rows, just as the primary importer does.
 $set=($columns|Where-Object{$_ -notin @('TemplateID','Remark','Valid','Count','Price')}|ForEach-Object{"t.[$_]=s.[$_]"}) -join ','
 $list=($columns|ForEach-Object{'['+$_+']'}) -join ','
 if($Apply){
  $transaction=$connection.BeginTransaction();$command.Transaction=$transaction;$command.CommandTimeout=120
  $command.CommandText="IF COL_LENGTH('dbo.Shop_Goods','Hole')<200 ALTER TABLE dbo.Shop_Goods ALTER COLUMN Hole nvarchar(100) NULL; UPDATE t SET $set FROM dbo.Shop_Goods t JOIN Db_Tank.dbo.Shop_Goods s ON t.TemplateID=s.TemplateID; INSERT INTO dbo.Shop_Goods ($list) SELECT $list FROM Db_Tank.dbo.Shop_Goods s WHERE NOT EXISTS (SELECT 1 FROM dbo.Shop_Goods t WHERE t.TemplateID=s.TemplateID);"
  [void]$command.ExecuteNonQuery()
  $transaction.Commit();$transaction=$null
 }
 $report=[ordered]@{Source=$sourceCount;Before=$before.Rows.Count;Added=$added;After=($before.Rows.Count+$added);PreviousHoleBytes=$holeBytes;Applied=[bool]$Apply;Backup=$backup}
 $json=$report|ConvertTo-Json;[IO.File]::WriteAllText((Join-Path $backup 'report.json'),$json);$json
}catch{if($null -ne $transaction){$transaction.Rollback()};throw}finally{$connection.Close()}
