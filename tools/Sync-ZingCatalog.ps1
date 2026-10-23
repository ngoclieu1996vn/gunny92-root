param(
    [Parameter(Mandatory=$true)][string]$SourceXml,
    [switch]$Apply
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$sourcePath = (Resolve-Path -LiteralPath $SourceXml).Path
[xml]$source = [IO.File]::ReadAllText($sourcePath)
$items = @($source.SelectNodes('//*[@TemplateID]'))
if ($items.Count -eq 0) { throw 'Source has no item templates.' }
$seen = @{}
foreach ($item in $items) {
    $id = [int]$item.TemplateID
    if ($seen.ContainsKey($id)) { throw "Duplicate source TemplateID: $id" }
    $seen[$id] = $true
}
# Read the existing local database configuration without logging credentials.
$api = [IO.File]::ReadAllText((Join-Path $root 'WebPortal/api.ashx'))
$literal = [regex]::Match([regex]::Match($api,'(?m)^\s*private const string ConnStr[^\r\n]*').Value,'@?"([^"]+)"').Groups[1].Value
$builder = New-Object Data.SqlClient.SqlConnectionStringBuilder($literal)
$builder['Initial Catalog'] = 'Db_Tank'; $builder['Connect Timeout'] = 5
$connection = New-Object Data.SqlClient.SqlConnection($builder.ConnectionString)
$backup = Join-Path $root ('scratch/item-catalog-backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $backup | Out-Null
$target = Join-Path $root 'Gunny92/Request/TemplateAlllist.xml'
$oldRequest = Join-Path $backup 'TemplateAlllist.xml'
Copy-Item -LiteralPath $target -Destination $oldRequest
$plain = Join-Path $backup 'request-before.xml'
& node (Join-Path $PSScriptRoot 'item-catalog-zlib.cjs') unpack $target $plain
if ($LASTEXITCODE -ne 0) { throw 'Could not decode local Request table.' }
[xml]$client = [IO.File]::ReadAllText($plain)
$clientItems = @{}; $container = $client.SelectSingleNode('//ItemTemplate')
if ($null -eq $container) { throw 'Local Request table has no ItemTemplate container.' }
foreach ($item in $client.SelectNodes('//*[@TemplateID]')) {
    $id = [int]$item.TemplateID
    if ($clientItems.ContainsKey($id)) { throw "Duplicate local client TemplateID: $id" }
    $clientItems[$id] = $item
}
$transaction = $null; $replaced = $false; $committed = $false; $report = $null
try {
    $connection.Open()
    $command = $connection.CreateCommand(); $command.CommandText = 'SELECT * FROM dbo.Shop_Goods ORDER BY TemplateID'
    $current = New-Object Data.DataTable('Shop_Goods')
    $adapter = New-Object Data.SqlClient.SqlDataAdapter($command); [void]$adapter.Fill($current)
    $current.WriteXml((Join-Path $backup 'Shop_Goods.xml'),[Data.XmlWriteMode]::WriteSchema)
    $lookup = @{}; foreach ($row in $current.Rows) { $lookup[[int]$row.TemplateID] = $row }
    $import = $current.Clone()
    $importColumns = @($items[0].Attributes | ForEach-Object { $_.Name } | Where-Object { $current.Columns.Contains($_) })
    $added = 0; $changed = 0
    foreach ($item in $items) {
        $id = [int]$item.TemplateID; $row = $import.NewRow(); $different = $false
        if ($lookup.ContainsKey($id)) { $row.ItemArray = $lookup[$id].ItemArray }
        else {
            $added++
            # SqlDataAdapter.Fill does not import SQL NOT NULL/default metadata.
            foreach ($entry in @{Valid=0;Count=1;FloorPrice=0;SuitId=0;CanTransfer=1}.GetEnumerator()) {
                if ($import.Columns.Contains($entry.Key)) { $row[$entry.Key] = $entry.Value }
            }
            foreach ($column in $import.Columns) {
                if ($column.AllowDBNull) { continue }
                if ($column.ColumnName -eq 'Count' -or $column.ColumnName -eq 'CanTransfer') { $row[$column.ColumnName] = 1 }
                elseif ($column.ColumnName -in @('Valid','FloorPrice','SuitId')) { $row[$column.ColumnName] = 0 }
                elseif (-not $item.HasAttribute($column.ColumnName)) { throw "Missing required field $($column.ColumnName) on $id" }
            }
        }
        foreach ($name in $importColumns) {
            if (-not $item.HasAttribute($name)) { throw "Missing field $name on $id" }
            $value = $item.GetAttribute($name); $type = $import.Columns[$name].DataType
            if ($type -eq [bool]) { $value = [bool]::Parse($value) }
            elseif ($type -eq [datetime]) { $value = [datetime]::Parse($value,[Globalization.CultureInfo]::InvariantCulture) }
            else { $value = [Convert]::ChangeType($value,$type,[Globalization.CultureInfo]::InvariantCulture) }
            if ($name -ne 'AddTime' -and [string]$row[$name] -cne [string]$value) { $different = $true }
            $row[$name] = $value
        }
        if ($lookup.ContainsKey($id) -and $different) { $changed++ }
        $import.Rows.Add($row)
        if ($clientItems.ContainsKey($id)) {
            $oldNode = $clientItems[$id]
            foreach ($attribute in $item.Attributes) { $oldNode.SetAttribute($attribute.Name,$attribute.Value) }
        } else { [void]$container.AppendChild($client.ImportNode($item,$true)) }
    }
    $preparedPlain = Join-Path $backup 'request-after.xml'; $client.Save($preparedPlain)
    $prepared = Join-Path $backup 'request-after.zlib'
    & node (Join-Path $PSScriptRoot 'item-catalog-zlib.cjs') pack $preparedPlain $prepared
    if ($LASTEXITCODE -ne 0) { throw 'Could not pack updated client table.' }
    $report = [ordered]@{SourceItems=$items.Count;SourceSHA256=(Get-FileHash -LiteralPath $sourcePath).Hash;Before=$current.Rows.Count;Added=$added;Changed=$changed;After=($current.Rows.Count+$added);Backup=$backup;CanonicalApplied=$false;PlayerCatalogApplied=$false;Applied=$false}
    if ($Apply) {
        $transaction = $connection.BeginTransaction()
        $command.Transaction = $transaction
        $command.CommandText = 'SELECT TOP (0) * INTO #ZingItems FROM dbo.Shop_Goods'; [void]$command.ExecuteNonQuery()
        $bulk = New-Object Data.SqlClient.SqlBulkCopy($connection,[Data.SqlClient.SqlBulkCopyOptions]::CheckConstraints,$transaction)
        try {
            $bulk.DestinationTableName = '#ZingItems'; $bulk.BulkCopyTimeout = 120
            foreach ($column in $import.Columns) { [void]$bulk.ColumnMappings.Add($column.ColumnName,$column.ColumnName) }
            $bulk.WriteToServer($import)
        } finally { $bulk.Close() }
        $set = ($importColumns | Where-Object { $_ -ne 'TemplateID' } | ForEach-Object { "t.[$_]=s.[$_]" }) -join ','
        $columns = ($import.Columns | ForEach-Object { '['+$_.ColumnName+']' }) -join ','
        $command.CommandTimeout = 120
        $command.CommandText = "UPDATE t SET $set FROM dbo.Shop_Goods t JOIN #ZingItems s ON s.TemplateID=t.TemplateID; INSERT INTO dbo.Shop_Goods ($columns) SELECT $columns FROM #ZingItems s WHERE NOT EXISTS (SELECT 1 FROM dbo.Shop_Goods t WHERE t.TemplateID=s.TemplateID);"
        [void]$command.ExecuteNonQuery()
        # Readers see either complete zlib file; roll back SQL and restore this file on failure.
        $swap = $target + '.catalog-swap'
        Copy-Item -LiteralPath $prepared -Destination $swap
        [IO.File]::Replace($swap,$target,(Join-Path $backup 'request-replaced.zlib')); $replaced = $true
        $transaction.Commit(); $transaction = $null; $committed = $true; $report.CanonicalApplied = $true
        [IO.File]::WriteAllText((Join-Path $backup 'report.json'),($report | ConvertTo-Json))
        $playerJson = & (Join-Path $PSScriptRoot 'Sync-PlayerItemCatalog.ps1') -Apply | Out-String
        $playerReport = $playerJson | ConvertFrom-Json
        if (-not $playerReport.Applied) { throw 'Player catalog mirror did not complete.' }
        $report.PlayerCatalogApplied = $true; $report.PlayerBackup = $playerReport.Backup; $report.Applied = $true
    }
    $json = $report | ConvertTo-Json
    [IO.File]::WriteAllText((Join-Path $backup 'report.json'),$json)
    $json
} catch {
    try {
        if ($null -ne $transaction) {
            try { $transaction.Rollback() } catch { Write-Warning 'SQL rollback could not be confirmed; inspect the saved backup before retrying.' }
        }
    } finally {
        if ($replaced -and -not $committed) {
            $restore = $target + '.catalog-restore'
            Copy-Item -LiteralPath $oldRequest -Destination $restore -Force
            [IO.File]::Replace($restore,$target,(Join-Path $backup 'request-rolled-back.zlib'))
        }
        if ($committed -and $null -ne $report -and -not $report.PlayerCatalogApplied) {
            $report.Error = 'Primary catalog committed; player mirror incomplete. Run tools/Sync-PlayerItemCatalog.ps1 -Apply before sending items.'
            [IO.File]::WriteAllText((Join-Path $backup 'report.json'),($report | ConvertTo-Json))
        }
    }
    throw
} finally { $connection.Close() }
