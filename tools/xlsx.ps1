# Nice HMS kit — stdlib-only multi-sheet .xlsx writer.
#
# PowerShell 5.1 + .NET only. No modules, no packages, nothing to install on a hospital PC.
# An .xlsx is a zip of XML parts; this builds the minimal valid set and zips it with forward-slash
# entry names so Excel, Google Sheets and LibreOffice all open it.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\xlsx.ps1 -Spec spec.json
#
# spec.json:
#   {
#     "out": "C:\\path\\payout-Demo-2024-12.xlsx",
#     "sheets": [
#       { "name": "Summary",    "csv": "summary.csv" },
#       { "name": "Line items", "csv": "lines.csv", "text_columns": ["mobile","uhid"] }
#     ]
#   }
#
# Cells: a value is written as a NUMBER when it is a plain decimal (so the admin can sum a column)
# unless its header is a known identifier (mobile, phone, uhid, account, id, gstin, pincode, abha)
# or it has a leading zero. Everything else is written as text, verbatim — nothing is coerced,
# rounded or reformatted.
#
# Per sheet, two optional keys (both match a column by its header, normalised):
#   "formula_columns": ["pay", ...]  — cells in this column that start with "=" are written as a
#                                      live formula <f>, not as text. Only listed columns are
#                                      eligible, so a pack value can never become a formula.
#   "money_columns":   ["total", ...] — cells in this column use number format #,##0.00.
# A formula almost always contains commas, so quote its CSV cell ("=IF(...,...)"); an unquoted
# one is split by the CSV reader before it ever reaches this script.
# Formula cells carry NO cached result: Excel, LibreOffice and Google Sheets recalculate on open,
# but a programmatic reader (openpyxl data_only, pandas) sees nothing. Pair a formula column with a
# plain control total when a reader must trust the number without opening Excel.

param(
    [Parameter(Mandatory = $true)][string]$Spec,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null

function Get-ColumnName([int]$index) {
    # 1-based column index -> A, B, ... Z, AA, AB ...
    $s = ''
    while ($index -gt 0) {
        $m = ($index - 1) % 26
        $s = [char](65 + $m) + $s
        $index = [int][math]::Floor(($index - 1) / 26)
    }
    return $s
}

function ConvertTo-XmlText([string]$value) {
    if ($null -eq $value) { return '' }
    $value = $value -replace '&', '&amp;'
    $value = $value -replace '<', '&lt;'
    $value = $value -replace '>', '&gt;'
    return $value
}

$identifierHeaders = @('mobile', 'phone', 'contact', 'uhid', 'account', 'account_id', 'encounter_id',
    'id', 'gstin', 'gst', 'pincode', 'pin', 'abha', 'aadhaar', 'vat', 'tin', 'utr')

function Test-IdentifierHeader([string]$header, $extraText) {
    $h = ($header -replace '[^A-Za-z0-9_]', '').ToLowerInvariant()
    if ($identifierHeaders -contains $h) { return $true }
    if ($extraText -and ($extraText.ToLowerInvariant() -contains $h)) { return $true }
    return $false
}

function Test-IsNumber([string]$value) {
    if ([string]::IsNullOrWhiteSpace($value)) { return $false }
    if ($value -match '^0\d') { return $false }            # 0987654321 is a phone, not a number
    if ($value -match '^\s*-?\d+(\.\d+)?\s*$') { return $true }
    return $false
}

function Read-CsvRows([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { throw "CSV not found: $path" }
    $raw = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    if ($null -eq $raw) { $raw = '' }
    $raw = $raw.TrimStart([char]0xFEFF)                    # strip a UTF-8 BOM so header 1 is clean
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return [pscustomobject]@{ Headers = @(); Rows = @() }
    }
    $records = @($raw | ConvertFrom-Csv)
    if ($records.Count -gt 0) {
        $headers = @($records[0].PSObject.Properties.Name)
        return [pscustomobject]@{ Headers = $headers; Rows = $records }
    }
    # Header-only file. ConvertFrom-Csv needs at least one data row to expose the columns, so
    # append one dummy row of placeholders and read the property names back. Header cells in these
    # packs never contain commas, so counting commas gives the column count.
    $firstLine = ($raw -split "`r?`n")[0]
    $colCount = ([regex]::Matches($firstLine, ',')).Count + 1
    $dummy = (@('x') * $colCount) -join ','
    $headers = @((($firstLine + "`n" + $dummy) | ConvertFrom-Csv | Select-Object -First 1).PSObject.Properties.Name)
    return [pscustomobject]@{ Headers = $headers; Rows = @() }
}

function Resolve-ColumnIndexes($headers, $names) {
    # Header name(s) -> 1-based column indexes. Normalised the same way as identifiers so
    # "What-if payout (₹)" and "whatif_payout" resolve to the same column.
    $idx = @()
    if (-not $names) { return $idx }
    $want = @($names | ForEach-Object { ([string]$_ -replace '[^A-Za-z0-9_]', '').ToLowerInvariant() })
    for ($c = 1; $c -le $headers.Count; $c++) {
        $h = ([string]$headers[$c - 1] -replace '[^A-Za-z0-9_]', '').ToLowerInvariant()
        if ($want -contains $h) { $idx += $c }
    }
    return $idx
}

function New-SheetXml($headers, $rows, $extraText, $formulaIdx, $moneyIdx) {
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
    [void]$sb.Append('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">')
    [void]$sb.Append('<sheetViews><sheetView workbookViewId="0">')
    [void]$sb.Append('<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>')
    [void]$sb.Append('</sheetView></sheetViews>')
    [void]$sb.Append('<sheetData>')

    $rowNo = 0
    if ($headers.Count -gt 0) {
        $rowNo++
        [void]$sb.Append("<row r=`"$rowNo`">")
        for ($c = 1; $c -le $headers.Count; $c++) {
            $ref = (Get-ColumnName $c) + $rowNo
            [void]$sb.Append("<c r=`"$ref`" t=`"inlineStr`" s=`"1`"><is><t xml:space=`"preserve`">$(ConvertTo-XmlText ([string]$headers[$c - 1]))</t></is></c>")
        }
        [void]$sb.Append('</row>')
    }

    foreach ($rec in $rows) {
        $rowNo++
        [void]$sb.Append("<row r=`"$rowNo`">")
        for ($c = 1; $c -le $headers.Count; $c++) {
            $header = [string]$headers[$c - 1]
            $value = [string]$rec.$header
            $ref = (Get-ColumnName $c) + $rowNo
            $style = ''
            if ($moneyIdx -contains $c) { $style = ' s="2"' }

            if (($formulaIdx -contains $c) -and $value.StartsWith('=')) {
                # live formula — allowlisted column only, so pack text can never become one
                [void]$sb.Append("<c r=`"$ref`"$style><f>$(ConvertTo-XmlText $value.Substring(1))</f></c>")
            }
            elseif ((Test-IsNumber $value) -and -not (Test-IdentifierHeader $header $extraText)) {
                [void]$sb.Append("<c r=`"$ref`"$style><v>$($value.Trim())</v></c>")
            }
            elseif ([string]::IsNullOrEmpty($value)) {
                # leave the cell absent: an empty cell, not a zero
            }
            else {
                [void]$sb.Append("<c r=`"$ref`"$style t=`"inlineStr`"><is><t xml:space=`"preserve`">$(ConvertTo-XmlText $value)</t></is></c>")
            }
        }
        [void]$sb.Append('</row>')
    }

    if ($rowNo -eq 0) {
        [void]$sb.Append('<row r="1"><c r="A1" t="inlineStr"><is><t>(no rows)</t></is></c></row>')
    }

    [void]$sb.Append('</sheetData></worksheet>')
    return $sb.ToString()
}

function Add-ZipText($zip, [string]$entryName, [string]$content) {
    $entry = $zip.CreateEntry($entryName, [System.IO.Compression.CompressionLevel]::Optimal)
    $stream = $entry.Open()
    $enc = New-Object System.Text.UTF8Encoding($false)      # no BOM in XML parts
    $bytes = $enc.GetBytes($content)
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Close()
}

# ---- load spec ---------------------------------------------------------------------------------
$specPath = (Resolve-Path -LiteralPath $Spec).Path
$cfg = Get-Content -LiteralPath $specPath -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $cfg.out) { throw "spec.out is required (the .xlsx path)." }
if (-not $cfg.sheets -or @($cfg.sheets).Count -eq 0) { throw "spec.sheets must list at least one sheet." }

$sheets = @()
$i = 0
foreach ($s in @($cfg.sheets)) {
    $i++
    $name = [string]$s.name
    if ([string]::IsNullOrWhiteSpace($name)) { $name = "Sheet$i" }
    $name = ($name -replace '[:\\/\?\*\[\]]', ' ').Trim()
    if ($name.Length -gt 31) { $name = $name.Substring(0, 31) }
    $csvPath = [string]$s.csv
    if (-not [System.IO.Path]::IsPathRooted($csvPath)) {
        $csvPath = Join-Path (Split-Path -Parent $specPath) $csvPath
    }
    $parsed = Read-CsvRows $csvPath
    $extra = @()
    if ($s.text_columns) { $extra = @($s.text_columns | ForEach-Object { ([string]$_ -replace '[^A-Za-z0-9_]', '').ToLowerInvariant() }) }
    $fIdx = Resolve-ColumnIndexes $parsed.Headers $s.formula_columns
    $mIdx = Resolve-ColumnIndexes $parsed.Headers $s.money_columns
    $sheets += [pscustomobject]@{ Name = $name; Headers = $parsed.Headers; Rows = $parsed.Rows; ExtraText = $extra; FormulaIdx = $fIdx; MoneyIdx = $mIdx; Csv = $csvPath }
}

$outPath = [string]$cfg.out
if (-not [System.IO.Path]::IsPathRooted($outPath)) {
    $outPath = Join-Path (Split-Path -Parent $specPath) $outPath
}
$outDir = Split-Path -Parent $outPath
if ($outDir -and -not (Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

if ($WhatIf) {
    "Would write $outPath with $($sheets.Count) sheet(s):"
    foreach ($sh in $sheets) { "  - $($sh.Name)  ($(@($sh.Rows).Count) data rows)  <- $($sh.Csv)" }
    return
}

# ---- build the package -------------------------------------------------------------------------
$ctBuilder = [System.Text.StringBuilder]::new()
[void]$ctBuilder.Append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
[void]$ctBuilder.Append('<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">')
[void]$ctBuilder.Append('<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>')
[void]$ctBuilder.Append('<Default Extension="xml" ContentType="application/xml"/>')
[void]$ctBuilder.Append('<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>')
[void]$ctBuilder.Append('<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>')
for ($n = 1; $n -le $sheets.Count; $n++) {
    [void]$ctBuilder.Append("<Override PartName=`"/xl/worksheets/sheet$n.xml`" ContentType=`"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml`"/>")
}
[void]$ctBuilder.Append('</Types>')

$rootRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
'<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
'<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>' +
'</Relationships>'

$wbBuilder = [System.Text.StringBuilder]::new()
[void]$wbBuilder.Append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
[void]$wbBuilder.Append('<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">')
[void]$wbBuilder.Append('<sheets>')
for ($n = 1; $n -le $sheets.Count; $n++) {
    $nm = ConvertTo-XmlText ($sheets[$n - 1].Name)
    [void]$wbBuilder.Append("<sheet name=`"$nm`" sheetId=`"$n`" r:id=`"rId$n`"/>")
}
[void]$wbBuilder.Append('</sheets></workbook>')

$wbRelsBuilder = [System.Text.StringBuilder]::new()
[void]$wbRelsBuilder.Append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
[void]$wbRelsBuilder.Append('<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">')
for ($n = 1; $n -le $sheets.Count; $n++) {
    [void]$wbRelsBuilder.Append("<Relationship Id=`"rId$n`" Type=`"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet`" Target=`"worksheets/sheet$n.xml`"/>")
}
[void]$wbRelsBuilder.Append('<Relationship Id="rIdStyles" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>')
[void]$wbRelsBuilder.Append('</Relationships>')

$styles = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
'<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' +
'<numFmts count="1"><numFmt numFmtId="164" formatCode="#,##0.00"/></numFmts>' +
'<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><name val="Calibri"/></font></fonts>' +
'<fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills>' +
'<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>' +
'<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>' +
'<cellXfs count="3"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/><xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/></cellXfs>' +
'<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>' +
'</styleSheet>'

if (Test-Path -LiteralPath $outPath) { Remove-Item -LiteralPath $outPath -Force }
$zip = [System.IO.Compression.ZipFile]::Open($outPath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    Add-ZipText $zip '[Content_Types].xml' $ctBuilder.ToString()
    Add-ZipText $zip '_rels/.rels' $rootRels
    Add-ZipText $zip 'xl/workbook.xml' $wbBuilder.ToString()
    Add-ZipText $zip 'xl/_rels/workbook.xml.rels' $wbRelsBuilder.ToString()
    Add-ZipText $zip 'xl/styles.xml' $styles
    for ($n = 1; $n -le $sheets.Count; $n++) {
        $sh = $sheets[$n - 1]
        Add-ZipText $zip "xl/worksheets/sheet$n.xml" (New-SheetXml $sh.Headers $sh.Rows $sh.ExtraText $sh.FormulaIdx $sh.MoneyIdx)
    }
}
finally {
    $zip.Dispose()
}

"Wrote $outPath ($($sheets.Count) sheet(s))."
