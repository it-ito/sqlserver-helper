<#
  .SYNOPSIS
   DMVなどから取得したSQL文を構文エラーが出ないようにパラメータ部分を書き換えます

   .DESCRIPTION
   以下のような変換を実施します
   対象SQL例: (@P1 int)SELECT TOP 1 * FROM SampleTable WHERE column = @P1
   変換後: (@P1 int)SELECT TOP 1 * FROM SampleTable WHERE column = @P1
  #>
function Format-SqlParam($sql) {
    if ($sql[0] -ne "(") {
        return $sql;
    }
    $bracketCount = 1;
    $closeBracketIndex = 0;
    # (@P0 int, @P1 int, ...) を抽出
    for ($i = 1; $i -lt $sql.Length; $i++) {
        if ($sql[$i] -eq "(") {
            $bracketCount++;
        }
        elseif ($sql[$i] -eq ")") {
            $bracketCount--;
            if ($bracketCount -eq 0) {
                $closeBracketIndex = $i;
                break;
            }
        }
    }
    $parameters = $sql.Substring(1, $closeBracketIndex - 1);
    $query = $sql.Substring($closeBracketIndex + 1);
    # parameter部分をdeclareによる変数宣言に変更、OUTPUTを除去
    # 全体から " を除去
    return ( -join ($parameters.Split(",") | ForEach-Object { $_ -replace "(@\w+) (.+)", 'declare $1 $2;' -replace " OUTPUT;", ";" }) + $query) `
        -replace """", ""
}

$fileName = "input.sql"
$cdataFormated = "";

foreach ($sql in Get-Content $fileName -encoding unicode) {
    $formated = Format-SqlParam($sql)
    $cdataFormated = $cdataFormated + @"
<![CDATA[
$formated
]]>

"@
}

Write-Output @"
<xml>
$cdataFormated
</xml>
"@
