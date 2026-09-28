@echo off
setlocal EnableExtensions
title Brilhante Scann
color 0F
set "SELF=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$c=[IO.File]::ReadAllText($env:SELF); $i=$c.LastIndexOf('#PS'+'BEGIN#'); Invoke-Expression $c.Substring($i)"
exit /b

#PSBEGIN#
$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
try {
  $Host.UI.RawUI.WindowTitle = 'Brilhante Scann'
  $Host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(120, 3000)
  $Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(120, 42)
} catch {}

# ---------------------------------------------------------------- simbolos
$SQ  = [string][char]0x25A0   # quadrado cheio
$SQE = [string][char]0x25A1   # quadrado vazio
$TRI = [string][char]0x25B2   # triangulo de alerta
$DOT = [string][char]0x25CF   # bolinha
$ARW = [string][char]0x25BA   # seta
$HL  = [string][char]0x2550
$VL  = [string][char]0x2551
$TL  = [string][char]0x2554
$TR  = [string][char]0x2557
$BL  = [string][char]0x255A
$BR  = [string][char]0x255D
$LN  = [string][char]0x2500

# ---------------------------------------------------------------- estado
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$global:Cnt = @(0, 0, 0, 0, 0)
$global:RepLines = New-Object System.Collections.Generic.List[string]
$global:Stat = [ordered]@{}

$LV = @(
  @{ Name = 'OK';       Fg = 'Green';      N = 1 },
  @{ Name = 'Info';     Fg = 'Cyan';       N = 1 },
  @{ Name = 'Atencao';  Fg = 'Yellow';     N = 3 },
  @{ Name = 'Suspeito'; Fg = 'DarkYellow'; N = 4 },
  @{ Name = 'Critico';  Fg = 'Red';        N = 5 }
)

$ExecExt = '.exe', '.dll', '.sys', '.bat', '.cmd', '.ps1', '.vbs', '.js', '.jar', '.msi', '.scr', '.com', '.hta'
$ArcExt  = '.zip', '.rar', '.7z'
$AllExt  = $ExecExt + $ArcExt
$Kw = '(?i)(cheat|hack|inject|loader|crack|keygen|bypass|spoof|aimbot|wallhack|hwid|executor|exploit|stealer|trainer|unlocker|triggerbot|skinchanger|kdmapper|mapper|(^|[^a-z])esp([^a-z]|$)|(^|[^a-z])rat([^a-z]|$))'
$SusPath = '(?i)(\\(Downloads|Desktop|Temp|Users\\Public)\\|374DE290-123F-4565-9164-39C4925E467B|B4BFCC3A-DB2C-424C-B029-7FE99A87C641)'
$Dirs = @(
  @{ P = "$env:USERPROFILE\Downloads"; D = 8 },
  @{ P = "$env:USERPROFILE\Desktop";   D = 4 },
  @{ P = "$env:USERPROFILE\Documents"; D = 3 },
  @{ P = "$env:TEMP";                  D = 2 }
)

# ---------------------------------------------------------------- visual
function Put([string]$T, [string]$Fg = 'Gray', [string]$Bg = '') {
  if ($Bg) { Write-Host $T -NoNewline -ForegroundColor $Fg -BackgroundColor $Bg }
  else { Write-Host $T -NoNewline -ForegroundColor $Fg }
}
function Nl { Write-Host '' }

function Box([string[]]$Lines, [string]$Color = 'Cyan', [string]$TextColor = 'White') {
  $w = 74
  Put ('  ' + $TL + ($HL * $w) + $TR) $Color; Nl
  foreach ($t in $Lines) {
    $l = [int][math]::Floor(($w - $t.Length) / 2); if ($l -lt 0) { $l = 0 }
    $r = $w - $t.Length - $l; if ($r -lt 0) { $r = 0 }
    Put ('  ' + $VL) $Color
    Put ((' ' * $l) + $t + (' ' * $r)) $TextColor
    Put $VL $Color; Nl
  }
  Put ('  ' + $BL + ($HL * $w) + $BR) $Color; Nl
}

function Banner([string]$Sub = '') {
  Clear-Host
  Nl
  Box @('B R I L H A N T E   S C A N N', 'Forense  |  Sistema  |  Anti-Bypass') 'Cyan' 'White'
  if ($Sub) { Put '  ' ; Put ($DOT + ' ') Cyan; Put $Sub Yellow; Nl }
  Nl
}

function Sec([string]$T) {
  Hx-NewSec $T
  Nl
  Put ('  ' + $ARW + ' ') Cyan; Put $T Yellow; Nl
  Put ('  ' + ($LN * 74)) DarkGray; Nl
}

# nivel: 0 OK | 1 Info | 2 Atencao | 3 Suspeito | 4 Critico
function Find-Out([string]$Tag, [int]$Lvl, [string]$Msg) {
  $c = $LV[$Lvl]
  $global:Cnt[$Lvl] = $global:Cnt[$Lvl] + 1
  Put '  '
  Put (' ' + $Tag.PadRight(10) + ' ') White Blue
  Put ' '
  Put ($SQ * $c.N) $c.Fg
  Put ($SQE * (5 - $c.N)) DarkGray
  Put ' '
  if ($Lvl -ge 2) { Put ($TRI + ' ') $c.Fg } else { Put ($DOT + ' ') $c.Fg }
  $mc = 'Gray'
  if ($Lvl -eq 2) { $mc = 'White' } elseif ($Lvl -ge 3) { $mc = $c.Fg }
  Put $Msg $mc
  Nl
  if (-not $global:CurSec) { Hx-NewSec 'Geral' }
  $global:CurSec.Cnt[$Lvl]++
  $global:CurSec.Items.Add((Hx-Find $Lvl $Tag $Msg))
  if ($Lvl -ge 3) { $global:Hot.Add(@{ L = $Lvl; Tag = $Tag; Msg = $Msg; Sec = $global:CurSec.Title }) }
}

function Show-Summary {
  Nl
  Put ('  ' + ($LN * 74)) DarkGray; Nl
  Put '  ' ; Put ' RESUMO ' White Blue; Put '  '
  for ($i = 4; $i -ge 0; $i--) {
    Put ($SQ + ' ' + $LV[$i].Name + ': ' + $global:Cnt[$i] + '    ') $LV[$i].Fg
  }
  Nl
  Put '  '
  if ($global:Cnt[4] -gt 0) { Put ($TRI + ' Itens CRITICOS encontrados - verifique acima.') Red }
  elseif ($global:Cnt[3] -gt 0) { Put ($TRI + ' Itens suspeitos encontrados - vale conferir.') DarkYellow }
  else { Put ($DOT + ' Nenhum indicio relevante.') Green }
  Nl
}

# nivel de recomendacao de ban, com base no que foi encontrado na varredura
function Get-BanVerdict {
  if ($global:Cnt[4] -gt 0) {
    return @{ Nivel = 'BANIR'; Cor = 'Red'; Texto = 'Foram encontradas evidencias criticas (cheat/hack/injecao). Recomenda-se banimento do jogador no servidor FiveM, apos revisao humana dos itens abaixo.' }
  } elseif ($global:Cnt[3] -gt 0) {
    return @{ Nivel = 'AVALIAR'; Cor = 'DarkYellow'; Texto = 'Existem itens suspeitos, mas nao conclusivos. Recomenda-se revisar manualmente os itens abaixo antes de decidir pelo banimento.' }
  } else {
    return @{ Nivel = 'NAO BANIR'; Cor = 'Green'; Texto = 'Nenhuma evidencia critica ou suspeita foi encontrada nesta varredura.' }
  }
}

# imprime na tela e grava no .txt o veredito final com o que foi executado/encontrado
function Show-BanVerdict {
  $v = Get-BanVerdict
  Nl
  Put ('  ' + ($LN * 74)) DarkGray; Nl
  Put '  '; Put ' VEREDITO - POSSIBILIDADE DE BAN NO FIVEM ' White Blue; Nl
  Put '  '; Put ($v.Nivel + ': ') $v.Cor; Put $v.Texto White; Nl

  RepRaw ''
  RepRaw ('=' * 90); RepRaw '  VEREDITO - POSSIBILIDADE DE BAN NO FIVEM'; RepRaw ('=' * 90)
  RepRaw ('  Sugestao : ' + $v.Nivel)
  RepRaw ('  Motivo   : ' + $v.Texto)

  $top = @($global:Hot | Sort-Object { $_.L } -Descending | Select-Object -First 30)
  if ($top.Count -gt 0) {
    Nl
    Put '  O que foi executado / encontrado (motivos, do mais grave ao menos grave):' Gray; Nl
    RepRaw '  O que foi executado / encontrado (motivos, do mais grave ao menos grave):'
    foreach ($h in $top) {
      $line = '   [' + $LV[$h.L].Name.PadRight(9) + '] ' + $h.Sec + ' - ' + $h.Tag + ': ' + $h.Msg
      Put $line $LV[$h.L].Fg; Nl
      RepRaw $line
    }
    if ($global:Hot.Count -gt 30) {
      $more = '   + ' + ($global:Hot.Count - 30) + ' outro(s) item(ns) critico(s)/suspeito(s) - veja as secoes acima.'
      Put $more DarkGray; Nl
      RepRaw $more
    }
  } else {
    Put '  Nenhum item critico ou suspeito para listar.' DarkGray; Nl
    RepRaw '  Nenhum item critico ou suspeito para listar.'
  }
}

# ---------------------------------------------------------------- relatorio
# (texto puro para o .txt + estrutura HTML para o relatorio bonito)
$global:Sections = New-Object System.Collections.Generic.List[object]
$global:CurSec = $null
$global:Hot = New-Object System.Collections.Generic.List[object]
$global:Tl = New-Object System.Collections.Generic.List[object]
$global:WalkTimeout = $false

function Add-Tl($When, [string]$Tipo, [string]$Txt, [int]$Lvl = 1) {
  $dt = $null
  if ($When -is [datetime]) { $dt = $When }
  else {
    $tmp = [datetime]::MinValue
    if ([datetime]::TryParse([string]$When, [ref]$tmp)) { $dt = $tmp }
  }
  if ($dt -and $dt.Year -gt 2000) { $global:Tl.Add([pscustomobject]@{ Quando = $dt; Lvl = $Lvl; Tipo = $Tipo; Evento = $Txt }) }
}

function Enc([string]$s) { [System.Net.WebUtility]::HtmlEncode($s) }
function RepRaw([string]$T = '') { $global:RepLines.Add($T) }

function Hx-NewSec([string]$T) {
  $s = @{ Title = $T; Items = (New-Object System.Collections.Generic.List[string]); Cnt = @(0, 0, 0, 0, 0) }
  $global:Sections.Add($s)
  $global:CurSec = $s
}
function Hx-Add([string]$Html) {
  if (-not $global:CurSec) { Hx-NewSec 'Geral' }
  $global:CurSec.Items.Add($Html)
}
function Hx-Find([int]$L, [string]$Tag, [string]$Msg, [string]$Src = '') {
  $n = $LV[$L].N
  $p = ''
  for ($i = 1; $i -le 5; $i++) { if ($i -le $n) { $p += '<i class="on"></i>' } else { $p += '<i></i>' } }
  $s = ''
  if ($Src) { $s = '<em class="src">' + (Enc $Src) + '</em>' }
  '<div class="f l' + $L + '" data-l="' + $L + '"><span class="tag">' + (Enc $Tag) + '</span><span class="pips">' + $p + '</span><span class="msg">' + (Enc $Msg) + $s + '</span></div>'
}
function Hx-Text([string]$T) {
  $t2 = $T.Trim()
  if ($t2 -eq '') { return }
  if ($t2 -match '^\[(.+)\]$') { Hx-Add ('<h3>' + (Enc $Matches[1]) + '</h3>'); return }
  if ($t2 -match '^(Nada encontrado|Nenhum)') { Hx-Add ('<p class="empty">' + (Enc $t2) + '</p>'); return }
  Hx-Add ('<p class="note">' + (Enc $t2) + '</p>')
}
function Hx-Table($D) {
  $D = @($D)
  if ($D.Count -eq 0 -or $null -eq $D[0]) { Hx-Add '<p class="empty">Nada encontrado.</p>'; return }
  $cols = @($D[0].PSObject.Properties | Where-Object { $_.Name -ne 'Lvl' } | ForEach-Object { $_.Name })
  $names = @('OK', 'Info', 'Atencao', 'Suspeito', 'Critico')
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.Append('<div class="tw"><table><thead><tr>')
  foreach ($c in $cols) { $cn = ([string]$c).Replace('_', ' '); [void]$sb.Append('<th>' + (Enc $cn) + '</th>') }
  [void]$sb.Append('</tr></thead><tbody>')
  foreach ($r in $D) {
    $cls = ''
    $hasNivel = $cols -contains 'Nivel'
    if ($hasNivel) {
      $ix = [array]::IndexOf($names, [string]$r.PSObject.Properties['Nivel'].Value)
      if ($ix -ge 0) { $cls = ' class="r' + $ix + '"' }
    } else {
      $line = (($cols | ForEach-Object { [string]$r.PSObject.Properties[$_].Value }) -join ' ')
      if ($line -match $Kw) { $cls = ' class="kw"' }
    }
    [void]$sb.Append('<tr' + $cls + '>')
    foreach ($c in $cols) {
      $v = [string]$r.PSObject.Properties[$c].Value
      if ($c -eq 'Nivel') {
        $ix = [array]::IndexOf($names, $v)
        if ($ix -ge 0) { [void]$sb.Append('<td><span class="badge b' + $ix + '">' + (Enc $v) + '</span></td>'); continue }
      }
      [void]$sb.Append('<td>' + (Enc $v) + '</td>')
    }
    [void]$sb.Append('</tr>')
  }
  [void]$sb.Append('</tbody></table></div>')
  Hx-Add $sb.ToString()
}
function Hx-List($D) {
  $D = @($D)
  $sb = New-Object System.Text.StringBuilder
  foreach ($r in $D) {
    $props = @($r.PSObject.Properties)
    $all = (($props | ForEach-Object { [string]$_.Value }) -join ' ')
    $flag = ''
    if ($all -match $Kw) { $flag = ' flag' }
    $title = [string]$props[0].Value
    [void]$sb.Append('<div class="it' + $flag + '"><div class="ith">' + (Enc $title) + '</div><dl>')
    for ($j = 1; $j -lt $props.Count; $j++) {
      $nm = ([string]$props[$j].Name).Replace('_', ' ')
      $val = [string]$props[$j].Value
      if ($val -match '^[0-9A-Fa-f]{64}$') {
        $vh = '<a href="https://www.virustotal.com/gui/file/' + $val + '" target="_blank" rel="noopener">' + $val + '</a>'
      } else { $vh = Enc $val }
      [void]$sb.Append('<dt>' + (Enc $nm) + '</dt><dd>' + $vh + '</dd>')
    }
    [void]$sb.Append('</dl></div>')
  }
  Hx-Add ('<div class="grid">' + $sb.ToString() + '</div>')
}

function Rep([string]$T = '') { RepRaw $T; Hx-Text $T }
function Rep-Sec([string]$T) {
  RepRaw ''; RepRaw ('=' * 90); RepRaw ('  ' + $T); RepRaw ('=' * 90)
  if ($global:CurSec -and $global:CurSec.Items.Count -eq 0) { $global:CurSec.Title = $T } else { Hx-NewSec $T }
}
function Rep-Table($D) {
  if (-not $D) { RepRaw '  Nada encontrado.'; Hx-Add '<p class="empty">Nada encontrado.</p>'; return }
  RepRaw (($D | Format-Table -AutoSize -Wrap | Out-String -Width 220).TrimEnd())
  Hx-Table $D
}
function Rep-List($D) {
  if (-not $D) { RepRaw '  Nada encontrado.'; Hx-Add '<p class="empty">Nada encontrado.</p>'; return }
  RepRaw (($D | Format-List | Out-String -Width 220).TrimEnd())
  Hx-List $D
}
function Rep-Header {
  RepRaw ('=' * 90)
  RepRaw '  BRILHANTE SCANN - RELATORIO'
  RepRaw ('  Data  : ' + (Get-Date).ToString('dd/MM/yyyy HH:mm:ss'))
  RepRaw ('  PC    : ' + $env:COMPUTERNAME + '   Usuario: ' + $env:USERNAME)
  if ($IsAdmin) { RepRaw '  Admin : SIM' } else { RepRaw '  Admin : NAO (resultado pode ficar incompleto)' }
  RepRaw ('=' * 90)
}

function Build-Html {
  $lab = @('OK', 'Info', 'Aten&ccedil;&atilde;o', 'Suspeito', 'Cr&iacute;tico')
  if ($global:Cnt[4] -gt 0) {
    $vc = 'crit'; $vt = 'Itens CR&Iacute;TICOS encontrados'; $vs = 'Revise os destaques abaixo antes de qualquer conclus&atilde;o.'
  } elseif ($global:Cnt[3] -gt 0) {
    $vc = 'sus'; $vt = 'Itens suspeitos encontrados'; $vs = 'Vale conferir os itens marcados abaixo.'
  } else {
    $vc = 'ok'; $vt = 'Nenhum ind&iacute;cio relevante'; $vs = 'O scanner n&atilde;o encontrou itens cr&iacute;ticos nem suspeitos.'
  }

  $kpi = New-Object System.Text.StringBuilder
  for ($i = 4; $i -ge 0; $i--) {
    [void]$kpi.Append('<button class="kpi k' + $i + ' on" data-l="' + $i + '" title="Clique para filtrar"><b>' + $global:Cnt[$i] + '</b><span>' + $lab[$i] + '</span></button>')
  }

  $hot = New-Object System.Text.StringBuilder
  $hl = @($global:Hot | Sort-Object { $_.L } -Descending)
  $n = 0
  foreach ($x in $hl) {
    if ($n -ge 80) { break }
    [void]$hot.Append((Hx-Find $x.L $x.Tag $x.Msg $x.Sec))
    $n++
  }
  if ($hl.Count -gt 80) { [void]$hot.Append('<p class="empty">+' + ($hl.Count - 80) + ' itens nas se&ccedil;&otilde;es abaixo.</p>') }
  if ($hl.Count -eq 0) { [void]$hot.Append('<p class="empty">Nenhum item cr&iacute;tico ou suspeito.</p>') }

  $nav = New-Object System.Text.StringBuilder
  $body = New-Object System.Text.StringBuilder
  $k = 0
  $ordered = @($global:Sections | Where-Object { $_.Title -like 'LINHA DO TEMPO*' }) + @($global:Sections | Where-Object { $_.Title -notlike 'LINHA DO TEMPO*' })
  foreach ($s in $ordered) {
    if ($s.Items.Count -eq 0) { continue }
    $k++
    $badge = ''
    if ($s.Cnt[4] -gt 0) { $badge += '<span class="pill p4">' + $s.Cnt[4] + '</span>' }
    if ($s.Cnt[3] -gt 0) { $badge += '<span class="pill p3">' + $s.Cnt[3] + '</span>' }
    if ($s.Cnt[2] -gt 0) { $badge += '<span class="pill p2">' + $s.Cnt[2] + '</span>' }
    $ttl = Enc $s.Title
    [void]$nav.Append('<a href="#s' + $k + '"><span>' + $ttl + '</span><span class="pills">' + $badge + '</span></a>')
    [void]$body.Append('<details class="sec" id="s' + $k + '" open><summary><h2>' + $ttl + '</h2><span class="pills">' + $badge + '</span></summary><div class="sb">' + ($s.Items -join "`n") + '</div></details>')
  }

  $st = New-Object System.Text.StringBuilder
  foreach ($key in $global:Stat.Keys) {
    [void]$st.Append('<div class="stat"><span>' + (Enc ([string]$key)) + '</span><b>' + (Enc ([string]$global:Stat[$key])) + '</b></div>')
  }
  if ($global:Stat.Count -eq 0) { [void]$st.Append('<p class="empty">Sem estat&iacute;sticas nesta execu&ccedil;&atilde;o.</p>') }

  if ($IsAdmin) { $adm = '<span class="chip good">Administrador</span>' } else { $adm = '<span class="chip bad">Sem admin &mdash; resultado pode ficar incompleto</span>' }

  # ---- veredito final / possibilidade de ban no FiveM
  $banV = Get-BanVerdict
  $banCls = 'ok'
  if ($banV.Nivel -eq 'BANIR') { $banCls = 'crit' } elseif ($banV.Nivel -eq 'AVALIAR') { $banCls = 'sus' }
  if ($banCls -eq 'ok') { $banIco = '&#10003;' } else { $banIco = '!' }
  $banItems = New-Object System.Text.StringBuilder
  $bl = @($global:Hot | Sort-Object { $_.L } -Descending)
  $bn = 0
  foreach ($x in $bl) {
    if ($bn -ge 50) { break }
    [void]$banItems.Append((Hx-Find $x.L $x.Tag $x.Msg $x.Sec))
    $bn++
  }
  if ($bl.Count -gt 50) { [void]$banItems.Append('<p class="empty">+' + ($bl.Count - 50) + ' itens nas se&ccedil;&otilde;es acima.</p>') }
  if ($bl.Count -eq 0) { [void]$banItems.Append('<p class="empty">Nenhum item cr&iacute;tico ou suspeito encontrado nesta varredura.</p>') }
  $banHtml = '<div class="verdict v-' + $banCls + '"><div class="vi">' + $banIco + '</div><div><h2>Sugest&atilde;o: ' + (Enc $banV.Nivel) + '</h2><p>' + (Enc $banV.Texto) + '</p></div></div>' + $banItems.ToString() + '<p class="note" style="margin-top:12px">Esta &eacute; uma sugest&atilde;o autom&aacute;tica com base nos indic&iacute;os coletados. A decis&atilde;o final de banir (ou n&atilde;o) o jogador deve ser tomada por um administrador humano, revisando os itens acima.</p>'

  $tpl = @'
<!DOCTYPE html>
<html lang="pt-BR" data-theme="dark">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Brilhante Scann - Relat&oacute;rio</title>
<style>
:root{--bg:#0a0f1e;--panel:#121a30;--panel2:#18213b;--line:#25304f;--tx:#e6ebf7;--mut:#8f9ac0;--acc:#38bdf8;
--c0:#22c55e;--c1:#38bdf8;--c2:#facc15;--c3:#fb923c;--c4:#ef4444}
[data-theme=light]{--bg:#f2f5fb;--panel:#ffffff;--panel2:#eef2fa;--line:#dbe2f0;--tx:#161c30;--mut:#5a6588;--acc:#0284c7}
*{box-sizing:border-box}
html{scroll-behavior:smooth}
body{margin:0;background:var(--bg);color:var(--tx);font:14px/1.5 "Segoe UI",system-ui,-apple-system,Roboto,Arial,sans-serif}
.wrap{max-width:1320px;margin:0 auto;padding:0 20px}
.hero{background:linear-gradient(135deg,#0d2347,#101a36 55%,#1d1242);color:#e6ebf7;padding:22px 0 20px;border-bottom:1px solid var(--line)}
.brand{display:flex;align-items:center;gap:14px}
.logo{width:46px;height:46px;border-radius:12px;display:grid;place-items:center;font-size:24px;color:#fff;background:linear-gradient(135deg,#38bdf8,#6366f1);box-shadow:0 6px 20px rgba(56,189,248,.35)}
.brand h1{margin:0;font-size:22px;letter-spacing:.22em;font-weight:700}
.brand p{margin:2px 0 0;color:#9fb0dd;font-size:12.5px;letter-spacing:.08em}
.tools{margin-left:auto;display:flex;gap:8px}
button{font:inherit;cursor:pointer}
.tools button{background:rgba(255,255,255,.08);color:#e6ebf7;border:1px solid rgba(255,255,255,.18);border-radius:8px;padding:6px 12px}
.tools button:hover{background:rgba(255,255,255,.16)}
.meta{display:flex;flex-wrap:wrap;gap:8px;margin-top:16px}
.chip{background:rgba(255,255,255,.08);border:1px solid rgba(255,255,255,.16);border-radius:999px;padding:3px 12px;font-size:12.5px;color:#dbe4fb}
.chip.good{border-color:#22c55e;color:#86efac}.chip.bad{border-color:#ef4444;color:#fca5a5}
.verdict{display:flex;gap:16px;align-items:center;margin:22px 0 14px;padding:16px 20px;border-radius:14px;border:1px solid;background:var(--panel)}
.verdict h2{margin:0;font-size:19px}.verdict p{margin:2px 0 0;color:var(--mut)}
.vi{width:44px;height:44px;flex:none;border-radius:50%;display:grid;place-items:center;font-weight:800;font-size:22px;color:#fff}
.v-crit{border-color:var(--c4);background:linear-gradient(90deg,rgba(239,68,68,.16),transparent 70%),var(--panel)}.v-crit .vi{background:var(--c4)}
.v-sus{border-color:var(--c3);background:linear-gradient(90deg,rgba(251,146,60,.16),transparent 70%),var(--panel)}.v-sus .vi{background:var(--c3)}
.v-ok{border-color:var(--c0);background:linear-gradient(90deg,rgba(34,197,94,.14),transparent 70%),var(--panel)}.v-ok .vi{background:var(--c0)}
.kpis{display:grid;grid-template-columns:repeat(5,1fr);gap:12px}
.kpi{background:var(--panel);color:var(--tx);border:1px solid var(--line);border-top:4px solid var(--kc);border-radius:12px;padding:12px 14px;text-align:left;transition:.15s}
.kpi b{display:block;font-size:28px;line-height:1.1;color:var(--kc)}
.kpi span{color:var(--mut);font-size:12.5px;text-transform:uppercase;letter-spacing:.06em}
.kpi:not(.on){opacity:.4}.kpi:hover{transform:translateY(-2px)}
.k0{--kc:var(--c0)}.k1{--kc:var(--c1)}.k2{--kc:var(--c2)}.k3{--kc:var(--c3)}.k4{--kc:var(--c4)}
.bar2{display:flex;gap:10px;align-items:center;margin:18px 0 6px}
.bar2 input{flex:1;background:var(--panel);color:var(--tx);border:1px solid var(--line);border-radius:10px;padding:9px 14px;font:inherit;outline:none}
.bar2 input:focus{border-color:var(--acc)}
.bar2 button{background:var(--panel);color:var(--tx);border:1px solid var(--line);border-radius:10px;padding:9px 14px}
.layout{display:grid;grid-template-columns:250px 1fr;gap:22px;align-items:start;padding-bottom:50px}
nav{position:sticky;top:14px;background:var(--panel);border:1px solid var(--line);border-radius:14px;padding:8px;max-height:calc(100vh - 28px);overflow:auto}
nav a{display:flex;justify-content:space-between;align-items:center;gap:8px;padding:8px 10px;border-radius:8px;color:var(--tx);text-decoration:none;font-size:13px}
nav a:hover{background:var(--panel2)}
.pills{display:inline-flex;gap:4px}
.pill{min-width:22px;text-align:center;padding:0 7px;border-radius:999px;font-size:11.5px;font-weight:700;color:#0b1020}
.p4{background:var(--c4);color:#fff}.p3{background:var(--c3)}.p2{background:var(--c2)}
main{min-width:0}
.panel,.sec{background:var(--panel);border:1px solid var(--line);border-radius:14px;margin:0 0 16px;overflow:hidden}
.panel>h2{margin:0;padding:14px 18px;font-size:16px;border-bottom:1px solid var(--line)}
.panel>.sb,.sec>.sb{padding:12px 18px 16px}
.sec>summary{list-style:none;cursor:pointer;display:flex;align-items:center;justify-content:space-between;padding:14px 18px;background:var(--panel2)}
.sec>summary::-webkit-details-marker{display:none}
.sec>summary h2{margin:0;font-size:16px}
.sec>summary::after{content:"\25BE";margin-left:12px;color:var(--mut)}
.sec:not([open])>summary::after{content:"\25B8"}
.sec>summary .pills{margin-left:auto}
h3{margin:20px 0 8px;font-size:12.5px;color:var(--acc);text-transform:uppercase;letter-spacing:.09em}
.note{margin:4px 0;color:var(--mut)}
.empty{margin:6px 0;color:var(--mut);font-style:italic}
.f{display:flex;gap:10px;align-items:flex-start;padding:7px 12px;margin:4px 0;border-radius:8px;background:var(--panel2);border-left:4px solid var(--fc)}
.l0{--fc:var(--c0)}.l1{--fc:var(--c1)}.l2{--fc:var(--c2)}.l3{--fc:var(--c3)}.l4{--fc:var(--c4)}
.f .tag{flex:none;min-width:84px;text-align:center;background:#1d4ed8;color:#fff;border-radius:6px;padding:0 8px;font-size:12px;font-weight:600}
.pips{flex:none;display:inline-flex;gap:2px;margin-top:6px}
.pips i{width:9px;height:9px;border-radius:2px;background:var(--line)}
.pips i.on{background:var(--fc)}
.f .msg{min-width:0;overflow-wrap:anywhere}
.l3 .msg,.l4 .msg{color:var(--fc);font-weight:500}
.l0 .msg,.l1 .msg{color:var(--mut)}
.src{display:block;font-size:11.5px;color:var(--mut);font-style:normal;margin-top:1px}
.tw{overflow-x:auto;border:1px solid var(--line);border-radius:10px}
table{border-collapse:collapse;width:100%;font-size:12.5px}
th{position:sticky;top:0;background:var(--panel2);text-align:left;padding:8px 10px;font-size:11.5px;text-transform:uppercase;letter-spacing:.06em;color:var(--mut);border-bottom:1px solid var(--line)}
td{padding:7px 10px;border-bottom:1px solid var(--line);vertical-align:top;overflow-wrap:anywhere;max-width:560px}
tbody tr:nth-child(even){background:rgba(127,140,180,.06)}
tbody tr:hover{background:rgba(56,189,248,.10)}
tr.r2 td:first-child{box-shadow:inset 3px 0 var(--c2)}
tr.r3 td:first-child{box-shadow:inset 3px 0 var(--c3)}
tr.r4 td:first-child{box-shadow:inset 3px 0 var(--c4)}
tr.r3{background:rgba(251,146,60,.09)!important}tr.r4{background:rgba(239,68,68,.12)!important}
tr.kw{background:rgba(239,68,68,.10)!important}tr.kw td:first-child{box-shadow:inset 3px 0 var(--c4)}
.badge{display:inline-block;padding:1px 9px;border-radius:999px;font-size:11.5px;font-weight:700;color:#0b1020}
.b0{background:var(--c0)}.b1{background:var(--c1)}.b2{background:var(--c2)}.b3{background:var(--c3)}.b4{background:var(--c4);color:#fff}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(420px,1fr));gap:12px}
.it{background:var(--panel2);border:1px solid var(--line);border-radius:12px;padding:12px 14px;min-width:0}
.it.flag{border-color:var(--c4);box-shadow:0 0 0 1px rgba(239,68,68,.3)}
.ith{font-weight:600;margin-bottom:8px;overflow-wrap:anywhere}
.it dl{margin:0;display:grid;grid-template-columns:110px 1fr;gap:4px 10px;font-size:12.5px}
.it dt{color:var(--mut)}.it dd{margin:0;overflow-wrap:anywhere}
.it a{color:var(--acc)}
.stats{display:grid;grid-template-columns:repeat(auto-fill,minmax(250px,1fr));gap:10px}
.stat{display:flex;justify-content:space-between;gap:10px;background:var(--panel2);border:1px solid var(--line);border-radius:10px;padding:9px 12px}
.stat span{color:var(--mut)}.stat b{color:var(--acc)}
footer{text-align:center;color:var(--mut);font-size:12px;padding:6px 0 30px}
@media(max-width:900px){.layout{grid-template-columns:1fr}nav{display:none}.kpis{grid-template-columns:repeat(2,1fr)}.grid{grid-template-columns:1fr}}
@media print{[data-theme=dark]{--bg:#fff;--panel:#fff;--panel2:#f3f5fa;--line:#d5dbe8;--tx:#111;--mut:#555}
.tools,.bar2,nav{display:none}.layout{grid-template-columns:1fr}.hero{background:#0d2347!important;-webkit-print-color-adjust:exact;print-color-adjust:exact}
*{-webkit-print-color-adjust:exact;print-color-adjust:exact}.sec{break-inside:auto}}
</style>
</head>
<body>
<header class="hero"><div class="wrap">
  <div class="brand">
    <div class="logo">&#9670;</div>
    <div><h1>BRILHANTE SCANN</h1><p>Forense &nbsp;|&nbsp; Sistema &nbsp;|&nbsp; Anti-Bypass</p></div>
    <div class="tools"><button id="theme">&#9680; Tema</button><button id="tgl">Expandir / recolher</button><button onclick="window.print()">Imprimir</button></div>
  </div>
  <div class="meta"><span class="chip">%%DATE%%</span><span class="chip">PC: %%PC%%</span><span class="chip">Usu&aacute;rio: %%USER%%</span>%%ADMIN%%</div>
</div></header>

<div class="wrap">
  <div class="verdict v-%%VC%%"><div class="vi">%%ICON%%</div><div><h2>%%VT%%</h2><p>%%VS%%</p></div></div>
  <div class="kpis">%%KPI%%</div>
  <div class="bar2"><input id="q" type="search" placeholder="Buscar no relat&oacute;rio (arquivo, programa, motivo, hash...)"><button id="clr">Limpar</button></div>

  <div class="layout">
    <nav><a href="#destaques"><span>&#9733; Destaques</span></a><a href="#resumo"><span>&#9776; Resumo</span></a>%%NAV%%<a href="#veredito-ban"><span>&#9888; Veredito / Ban</span></a></nav>
    <main>
      <section class="panel" id="destaques"><h2>&#9733; Destaques (cr&iacute;tico e suspeito)</h2><div class="sb">%%HOT%%</div></section>
      <section class="panel" id="resumo"><h2>&#9776; Resumo da varredura</h2><div class="sb"><div class="stats">%%STATS%%</div></div></section>
      %%BODY%%
      <section class="panel" id="veredito-ban"><h2>&#9888; Veredito final &mdash; Possibilidade de ban no FiveM</h2><div class="sb">%%BANV%%</div></section>
    </main>
  </div>
</div>
<footer>Gerado por Brilhante Scann &mdash; os indicativos s&atilde;o apoio &agrave; an&aacute;lise, confirme cada item antes de concluir.</footer>

<script>
(function(){
  var act={0:1,1:1,2:1,3:1,4:1}, q='';
  function apply(){
    document.querySelectorAll('.f').forEach(function(e){
      var ok=act[e.getAttribute('data-l')] && (q==='' || e.textContent.toLowerCase().indexOf(q)>-1);
      e.style.display=ok?'':'none';
    });
    document.querySelectorAll('tbody tr, .it').forEach(function(e){
      e.style.display=(q==='' || e.textContent.toLowerCase().indexOf(q)>-1)?'':'none';
    });
  }
  document.querySelectorAll('.kpi').forEach(function(b){
    b.addEventListener('click',function(){
      var l=b.getAttribute('data-l'); act[l]=act[l]?0:1;
      b.classList.toggle('on',!!act[l]); apply();
    });
  });
  var qi=document.getElementById('q');
  qi.addEventListener('input',function(){q=qi.value.trim().toLowerCase();apply();});
  document.getElementById('clr').addEventListener('click',function(){qi.value='';q='';apply();});
  document.getElementById('theme').addEventListener('click',function(){
    var h=document.documentElement;
    h.setAttribute('data-theme',h.getAttribute('data-theme')==='dark'?'light':'dark');
  });
  var open=true;
  document.getElementById('tgl').addEventListener('click',function(){
    open=!open;
    document.querySelectorAll('details.sec').forEach(function(d){d.open=open;});
  });
})();
</script>
</body>
</html>
'@

  if ($vc -eq 'ok') { $ico = '&#10003;' } else { $ico = '!' }
  $tpl = $tpl.Replace('%%DATE%%', (Get-Date).ToString('dd/MM/yyyy HH:mm:ss'))
  $tpl = $tpl.Replace('%%PC%%', (Enc $env:COMPUTERNAME))
  $tpl = $tpl.Replace('%%USER%%', (Enc $env:USERNAME))
  $tpl = $tpl.Replace('%%ADMIN%%', $adm)
  $tpl = $tpl.Replace('%%VC%%', $vc)
  $tpl = $tpl.Replace('%%ICON%%', $ico)
  $tpl = $tpl.Replace('%%VT%%', $vt)
  $tpl = $tpl.Replace('%%VS%%', $vs)
  $tpl = $tpl.Replace('%%KPI%%', $kpi.ToString())
  $tpl = $tpl.Replace('%%HOT%%', $hot.ToString())
  $tpl = $tpl.Replace('%%STATS%%', $st.ToString())
  $tpl = $tpl.Replace('%%NAV%%', $nav.ToString())
  $tpl = $tpl.Replace('%%BODY%%', $body.ToString())
  $tpl = $tpl.Replace('%%BANV%%', $banHtml)
  $tpl
}

function Save-Report {
  RepRaw ''
  RepRaw ('=' * 90); RepRaw '  RESUMO'; RepRaw ('=' * 90)
  foreach ($k in $global:Stat.Keys) { RepRaw ('  ' + ([string]$k).PadRight(34) + ': ' + $global:Stat[$k]) }
  Show-BanVerdict
  $desk = [Environment]::GetFolderPath('Desktop')
  $path = Join-Path $desk 'Brilhante_Scann_Report.txt'
  $hpath = Join-Path $desk 'Brilhante_Scann_Report.html'
  $global:RepLines | Out-File -FilePath $path -Encoding UTF8
  $html = Build-Html
  [IO.File]::WriteAllText($hpath, $html, (New-Object System.Text.UTF8Encoding($true)))
  Nl
  Put '  ' ; Put ' OK ' Black Green; Put ('  Relatorio bonito : ' + $hpath) White; Nl
  Put '  ' ; Put ' OK ' Black Green; Put ('  Relatorio em txt  : ' + $path) White; Nl
  Start-Process $hpath
}

# ---------------------------------------------------------------- utilidades
function Fmt-Date($x) {
  if ($x) { try { ([datetime]$x).ToString('dd/MM/yyyy HH:mm:ss') } catch { '-' } } else { '-' }
}
function Rot13([string]$s) {
  $sb = New-Object System.Text.StringBuilder
  foreach ($ch in $s.ToCharArray()) {
    $c = [int]$ch
    if ($c -ge 65 -and $c -le 90) { [void]$sb.Append([char]((($c - 65 + 13) % 26) + 65)) }
    elseif ($c -ge 97 -and $c -le 122) { [void]$sb.Append([char]((($c - 97 + 13) % 26) + 97)) }
    else { [void]$sb.Append($ch) }
  }
  $sb.ToString()
}
function Get-UserAssist {
  $ua = @()
  $root = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist'
  foreach ($g in (Get-ChildItem $root)) {
    $k = $g.OpenSubKey('Count')
    if (-not $k) { continue }
    foreach ($n in $k.GetValueNames()) {
      $d = $k.GetValue($n)
      if ($d -is [byte[]] -and $d.Length -ge 68) {
        $ft = [BitConverter]::ToInt64($d, 60)
        if ($ft -gt 0) {
          $ua += [pscustomobject]@{ Data = [DateTime]::FromFileTime($ft); Vezes = [BitConverter]::ToInt32($d, 4); Programa = (Rot13 $n) }
        }
      }
    }
  }
  $ua | Sort-Object Data -Descending
}
function Get-Bam {
  $rows = @()
  $root = 'HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings'
  if (-not (Test-Path $root)) { $root = 'HKLM:\SYSTEM\CurrentControlSet\Services\bam\UserSettings' }
  foreach ($sid in (Get-ChildItem $root)) {
    foreach ($n in $sid.GetValueNames()) {
      $d = $sid.GetValue($n)
      if ($d -is [byte[]] -and $d.Length -ge 8) {
        $ft = [BitConverter]::ToInt64($d, 0)
        if ($ft -gt 0) {
          $rows += [pscustomobject]@{ Data = [DateTime]::FromFileTime($ft); Programa = ($n -replace '^\\Device\\HarddiskVolume\d+', '[Disco]') }
        }
      }
    }
  }
  $rows | Sort-Object Data -Descending
}

# ================================================================
#  SCANS
# ================================================================
function Scan-Executed {
  Sec 'PROGRAMAS EXECUTADOS'
  Rep-Sec '1. O QUE FOI EXECUTADO'
  Put '  Analisando Prefetch, UserAssist e BAM...' DarkGray; Nl; Nl

  # ---- Prefetch
  $pf = @(Get-ChildItem (Join-Path $env:windir 'Prefetch') -Filter *.pf | Sort-Object LastWriteTime -Descending)
  if ($pf.Count -eq 0) {
    Find-Out 'Prefetch' 2 'Sem acesso ao Prefetch (rode como ADMIN) ou pasta esvaziada/desativada'
  } else {
    if ($pf.Count -lt 15) { Find-Out 'Prefetch' 3 ('Poucos arquivos no Prefetch (' + $pf.Count + ') - possivel limpeza') }
    $i = 0
    foreach ($f in $pf) {
      $nm = $f.Name -replace '-[0-9A-F]{8}\.pf$', ''
      $msg = 'Executado: ' + $nm + '  em ' + (Fmt-Date $f.LastWriteTime)
      if ($nm -match $Kw) { Find-Out 'Prefetch' 4 $msg }
      elseif ($i -lt 10) { Find-Out 'Prefetch' 1 $msg }
      if ($i -lt 25 -or $nm -match $Kw) { $tlv = 1; if ($nm -match $Kw) { $tlv = 4 }; Add-Tl $f.LastWriteTime 'Executado' ($nm + ' (Prefetch)') $tlv }
      $i++
    }
  }
  Rep ''; Rep '[Prefetch - ultimos 40 programas executados]'
  Rep-Table ($pf | Select-Object -First 40 -Property @{n='Ultima execucao';e={Fmt-Date $_.LastWriteTime}}, @{n='Programa';e={$_.Name -replace '-[0-9A-F]{8}\.pf$',''}})

  # ---- UserAssist
  $ua = @(Get-UserAssist)
  $tk = 0; $th = 0
  foreach ($e in $ua) {
    $tlv = 1
    if ($e.Programa -match $Kw) { $tlv = 4 } elseif ($e.Programa -match $SusPath) { $tlv = 3 }
    if ($tlv -ge 3) { if ($th -lt 40) { Add-Tl $e.Data 'Executado' ($e.Programa + ' (UserAssist)') $tlv }; $th++ }
    elseif ($tk -lt 25) { Add-Tl $e.Data 'Executado' ($e.Programa + ' (UserAssist)') 1 }
    $tk++
  }
  $shown = 0; $flagged = 0
  foreach ($e in $ua) {
    $msg = 'Executado: ' + $e.Programa + '  (' + (Fmt-Date $e.Data) + ', ' + $e.Vezes + 'x)'
    if ($e.Programa -match $Kw) { Find-Out 'UserAssist' 4 $msg }
    elseif ($e.Programa -match $SusPath) { if ($flagged -lt 15) { Find-Out 'UserAssist' 3 $msg }; $flagged++ }
    elseif ($shown -lt 6) { Find-Out 'UserAssist' 1 $msg; $shown++ }
  }
  if ($flagged -gt 15) { Find-Out 'UserAssist' 1 ('+' + ($flagged - 15) + ' itens de Downloads/Desktop/Temp no relatorio') }
  Rep ''; Rep '[UserAssist - programas abertos pelo usuario (ultimos 40)]'
  Rep-Table ($ua | Select-Object -First 40 -Property @{n='Ultima execucao';e={Fmt-Date $_.Data}}, Vezes, Programa)

  # ---- BAM
  $bam = @(Get-Bam)
  $tk = 0; $th = 0
  foreach ($e in $bam) {
    $tlv = 1
    $lf = ([string]$e.Programa -split '[\\/]')[-1]
    if ($lf -match $Kw) { $tlv = 4 } elseif ($e.Programa -match $SusPath) { $tlv = 3 }
    if ($tlv -ge 3) { if ($th -lt 40) { Add-Tl $e.Data 'Executado' ($e.Programa + ' (BAM)') $tlv }; $th++ }
    elseif ($tk -lt 25) { Add-Tl $e.Data 'Executado' ($e.Programa + ' (BAM)') 1 }
    $tk++
  }
  if ($bam.Count -eq 0) { Find-Out 'BAM' 1 'BAM sem dados (requer admin / Windows 10 1709+)' }
  $shown = 0; $flagged = 0
  foreach ($e in $bam) {
    $msg = 'Executado: ' + $e.Programa + '  (' + (Fmt-Date $e.Data) + ')'
    $leaf = ([string]$e.Programa -split '[\\/]')[-1]
    if ($leaf -match $Kw) { Find-Out 'BAM' 4 $msg }
    elseif ($e.Programa -match $SusPath) { if ($flagged -lt 15) { Find-Out 'BAM' 3 $msg }; $flagged++ }
    elseif ($shown -lt 6) { Find-Out 'BAM' 1 $msg; $shown++ }
  }
  if ($flagged -gt 15) { Find-Out 'BAM' 1 ('+' + ($flagged - 15) + ' itens de Downloads/Desktop/Temp no relatorio') }
  Rep ''; Rep '[BAM - execucoes recentes (ultimos 40)]'
  Rep-Table ($bam | Select-Object -First 40 -Property @{n='Ultima execucao';e={Fmt-Date $_.Data}}, Programa)

  $global:Stat['Programas no Prefetch'] = $pf.Count
}

function Scan-Deleted {
  Sec 'ARQUIVOS APAGADOS'
  Rep-Sec '2. O QUE FOI APAGADO'

  # ---- Lixeira
  $del = @()
  $shell = New-Object -ComObject Shell.Application
  $rb = $shell.NameSpace(10)
  foreach ($it in $rb.Items()) {
    $ext = ([IO.Path]::GetExtension([string]$it.Path)).ToLower()
    $del += [pscustomobject]@{
      Apagado_em = ($rb.GetDetailsOf($it, 2) -replace '[^\x20-\x7E]', '')
      Nome       = $it.Name
      Ext        = $ext
      Origem     = $rb.GetDetailsOf($it, 1)
      Tamanho    = $rb.GetDetailsOf($it, 3)
    }
  }
  if ($del.Count -eq 0) { Find-Out 'Lixeira' 1 'Lixeira vazia' }
  $i = 0
  foreach ($x in $del) {
    $lvl = 2
    if (($AllExt -contains $x.Ext) -or ($x.Nome -match $Kw)) { $lvl = 3 }
    if ($i -lt 15) { Find-Out 'Lixeira' $lvl ('Arquivo Deletado: ' + $x.Origem + '\' + $x.Nome + '  (' + $x.Apagado_em + ')') }
    if ($i -lt 60) { Add-Tl $x.Apagado_em 'Apagado' ($x.Origem + '\' + $x.Nome + ' (Lixeira)') $lvl }
    $i++
  }
  if ($del.Count -gt 15) { Find-Out 'Lixeira' 1 ('+' + ($del.Count - 15) + ' itens na Lixeira no relatorio') }
  $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
  $rbDir = Get-Item -LiteralPath ('C:\$Recycle.Bin\' + $sid) -Force
  if ($rbDir) {
    if ($del.Count -eq 0 -and $rbDir.LastWriteTime -gt (Get-Date).AddDays(-3)) {
      Find-Out 'Lixeira' 2 ('Lixeira vazia mas alterada em ' + (Fmt-Date $rbDir.LastWriteTime) + ' - possivel esvaziamento recente')
    } else {
      Find-Out 'Lixeira' 1 ('Ultima alteracao da Lixeira: ' + (Fmt-Date $rbDir.LastWriteTime))
    }
  }
  Rep ''; Rep '[Lixeira - arquivos apagados que ainda estao la]'
  Rep-Table ($del | Select-Object Apagado_em, Nome, Origem, Tamanho)

  # ---- Logs limpos
  $cl = @()
  foreach ($q in @(@{ L = 'Security'; I = 1102 }, @{ L = 'System'; I = 104 })) {
    foreach ($e in @(Get-WinEvent -FilterHashtable @{ LogName = $q.L; Id = $q.I } -MaxEvents 10)) {
      $cl += [pscustomobject]@{ Data = $e.TimeCreated; Log = $q.L }
    }
  }
  foreach ($x in $cl) { Find-Out 'Eventos' 4 ('Log de eventos ' + $x.Log + ' foi LIMPO em ' + (Fmt-Date $x.Data)); Add-Tl $x.Data 'Log limpo' ('Log de eventos ' + $x.Log + ' limpo') 4 }
  if ($cl.Count -eq 0) {
    if ($IsAdmin) { Find-Out 'Eventos' 0 'Nenhum log de eventos foi limpo' }
    else { Find-Out 'Eventos' 1 'Log Security requer admin - checagem parcial' }
  }
  Rep ''; Rep '[Logs do Windows LIMPOS (tentativa de apagar rastros)]'
  Rep-Table ($cl | Select-Object @{n='Data';e={Fmt-Date $_.Data}}, Log)

  # ---- Journal NTFS
  Put '  Lendo journal do disco C: (pode demorar)...' DarkGray; Nl
  $usnRows = New-Object System.Collections.Generic.List[object]
  $seen = @{}
  $re = '(?i)([^,"\\/:*?<>|\r\n]+\.(exe|dll|sys|bat|cmd|ps1|vbs|jar|msi|scr|zip|rar|7z))\b'
  fsutil usn readjournal C: csv 2>$null | ForEach-Object {
    if ($_ -match 'FILE_DELETE' -and $_ -match $re) {
      $name = ([string]$Matches[1]).Trim()
      $ts = ''
      if ($_ -match '(\d{1,4}[/\-\.]\d{1,2}[/\-\.]\d{1,4}[ T]+\d{1,2}:\d{2}:\d{2})') { $ts = $Matches[1] }
      $key = $name + '|' + $ts
      if (-not $seen.ContainsKey($key)) { $seen[$key] = 1; $usnRows.Add([pscustomobject]@{ Data = $ts; Arquivo = $name }) }
    }
  }
  $recent = @($usnRows | Select-Object -Last 60)
  [array]::Reverse($recent)
  foreach ($r in @($recent | Select-Object -First 40)) {
    $tlv = 2; if ($r.Arquivo -match $Kw) { $tlv = 4 }
    Add-Tl $r.Data 'Apagado' ($r.Arquivo + ' (journal)') $tlv
  }
  if ($recent.Count -eq 0) {
    if ($IsAdmin) { Find-Out 'Journal' 1 'Nenhum executavel/script apagado no journal' }
    else { Find-Out 'Journal' 2 'Journal do disco requer ADMIN - nao foi possivel checar' }
  }
  $i = 0
  foreach ($r in $recent) {
    if ($i -ge 12) { break }
    $lvl = 2; if ($r.Arquivo -match $Kw) { $lvl = 4 }
    $suffix = ''; if ($r.Data) { $suffix = '  (' + $r.Data + ')' }
    Find-Out 'Journal' $lvl ('Arquivo Deletado: ' + $r.Arquivo + $suffix)
    $i++
  }
  if ($recent.Count -gt 12) { Find-Out 'Journal' 1 ('+' + ($recent.Count - 12) + ' itens apagados no relatorio') }
  Rep ''; Rep '[Journal do disco C: - executaveis/scripts/compactados APAGADOS (ultimos 60)]'
  Rep-Table $recent

  $global:Stat['Itens na Lixeira'] = $del.Count
  $global:Stat['Logs limpos'] = $cl.Count
  $global:Stat['Apagados (journal)'] = $recent.Count
}

function Scan-Usb {
  Sec 'PEN DRIVES / USB'
  Rep-Sec '3. PEN DRIVES / USB'
  $usb = @()
  foreach ($d in (Get-PnpDevice | Where-Object { $_.InstanceId -like 'USBSTOR\*' })) {
    $arr = (Get-PnpDeviceProperty -InstanceId $d.InstanceId -KeyName 'DEVPKEY_Device_LastArrivalDate').Data
    $rem = (Get-PnpDeviceProperty -InstanceId $d.InstanceId -KeyName 'DEVPKEY_Device_LastRemovalDate').Data
    $usb += [pscustomobject]@{
      Nome    = $d.FriendlyName
      Serial  = (($d.InstanceId -split '\\')[-1])
      Chegada = $arr
      Remocao = $rem
      Agora   = ($d.Status -eq 'OK')
    }
  }
  $usb = @($usb | Sort-Object Chegada -Descending)
  if ($usb.Count -eq 0) { Find-Out 'USB' 0 'Nenhum pen drive no historico deste PC' }
  foreach ($u in $usb) {
    $lvl = 1
    if ($u.Chegada -and $u.Chegada -gt (Get-Date).AddDays(-7)) { $lvl = 2 }
    $msg = 'Pen drive: ' + $u.Nome + '  serial ' + $u.Serial + '  conectado ' + (Fmt-Date $u.Chegada) + '  removido ' + (Fmt-Date $u.Remocao)
    if ($u.Agora) { $lvl = 3; $msg = 'CONECTADO AGORA - ' + $msg }
    Find-Out 'USB' $lvl $msg
    Add-Tl $u.Chegada 'USB' ('Pen drive conectado: ' + $u.Nome) $lvl
    if ($u.Remocao) { Add-Tl $u.Remocao 'USB' ('Pen drive removido: ' + $u.Nome) 1 }
  }
  Rep ''; Rep '[Historico de pen drives / HDs USB ja conectados]'
  Rep-Table ($usb | Select-Object Nome, Serial, @{n='Conectado_em';e={Fmt-Date $_.Chegada}}, @{n='Removido_em';e={Fmt-Date $_.Remocao}}, @{n='Status';e={ if ($_.Agora) { 'CONECTADO AGORA' } else { 'Desconectado' } }})

  Rep ''; Rep '[Pen drives conectados agora + executaveis dentro deles]'
  $rem = @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=2')
  if ($rem.Count -eq 0) { Rep '  Nenhum pen drive conectado no momento.' }
  foreach ($ld in $rem) {
    $ex = @(Get-ChildItem -Path ($ld.DeviceID + '\') -Recurse -File -Force | Where-Object { $ExecExt -contains $_.Extension.ToLower() } | Select-Object -First 50)
    Find-Out 'USB' 2 ('Unidade ' + $ld.DeviceID + ' (' + $ld.VolumeName + ') montada - ' + $ex.Count + ' executavel(is)/script(s)')
    foreach ($f in ($ex | Select-Object -First 10)) { Find-Out 'USB' 3 ('Arquivo no pen drive: ' + $f.FullName) }
    Rep ('  Unidade ' + $ld.DeviceID + '  Nome: ' + $ld.VolumeName)
    Rep-Table ($ex | Select-Object @{n='Modificado';e={Fmt-Date $_.LastWriteTime}}, FullName)
  }
  $global:Stat['Pen drives no historico'] = $usb.Count
}

function Scan-Downloads {
  Sec 'ARQUIVOS SUSPEITOS / BAIXADOS'
  Rep-Sec '4. ARQUIVOS MALICIOSOS / SUSPEITOS BAIXADOS'

  # ---- Defender
  $threats = @{}
  foreach ($t in (Get-MpThreat)) { $threats[[string]$t.ThreatID] = $t.ThreatName }
  $dets = @()
  foreach ($d in (Get-MpThreatDetection | Sort-Object InitialDetectionTime -Descending)) {
    foreach ($r in $d.Resources) {
      Add-Tl $d.InitialDetectionTime 'Defender' ('Ameaca detectada: ' + $threats[[string]$d.ThreatID]) 4
      $dets += [pscustomobject]@{
        Detectado_em = Fmt-Date $d.InitialDetectionTime
        Ameaca       = $threats[[string]$d.ThreatID]
        Arquivo      = ($r -replace '^file:_', '')
        Removida     = $d.ActionSuccess
      }
    }
  }
  if ($dets.Count -eq 0) { Find-Out 'Defender' 0 'Nenhuma ameaca no historico do Defender' }
  $i = 0
  foreach ($x in $dets) {
    if ($i -lt 15) { Find-Out 'Defender' 4 ('Ameaca: ' + $x.Ameaca + ' -> ' + $x.Arquivo + '  (' + $x.Detectado_em + ')') }
    $i++
  }
  Rep ''; Rep '[Ameacas detectadas pelo Windows Defender (confirmadas)]'
  Rep-Table $dets

  # ---- Arquivos
  Put '  Varrendo Downloads, Desktop, Documentos e Temp...' DarkGray; Nl
  $badChars = '[\u200B-\u200F\u202A-\u202E\u2060-\u2064\u2066-\u2069\uFEFF\u00A0\u3164\u115F\u1160]'
  $mixed = '[\u0370-\u03FF\u0400-\u04FF]'
  $partial = '.crdownload', '.part', '.partial', '.opdownload'
  $scripts = '.bat', '.cmd', '.ps1', '.vbs', '.js', '.jar', '.hta'
  $sigTypes = '.exe', '.dll', '.sys', '.msi', '.scr'
  $found = @()
  $others = @()

  foreach ($dd in $Dirs) {
    if (-not (Test-Path $dd.P)) { continue }
    foreach ($f in (Get-ChildItem -Path $dd.P -Recurse -Depth $dd.D -File -Force)) {
      if ($f.FullName -eq $env:SELF) { continue }
      $ext = $f.Extension.ToLower()

      if ($f.Name -match $badChars) {
        Find-Out 'Unicode' 4 ('Unicode Bypass: caractere invisivel no nome -> ' + $f.FullName)
        $others += [pscustomobject]@{ Tipo = 'Unicode Bypass'; Arquivo = $f.FullName }
        continue
      }
      if (($AllExt -contains $ext) -and ($f.BaseName -match $mixed)) {
        Find-Out 'Unicode' 4 ('Unicode Bypass: letras Cirilico/Grego no nome -> ' + $f.FullName)
        $others += [pscustomobject]@{ Tipo = 'Unicode Bypass'; Arquivo = $f.FullName }
        continue
      }
      if ($partial -contains $ext) {
        Find-Out 'Download' 2 ('Download incompleto: ' + $f.FullName + '  (' + (Fmt-Date $f.LastWriteTime) + ')')
        $others += [pscustomobject]@{ Tipo = 'Download incompleto'; Arquivo = $f.FullName }
        continue
      }
      if (-not ($AllExt -contains $ext)) { continue }

      $score = 0; $why = @(); $origem = '-'
      $z = Get-Content -LiteralPath $f.FullName -Stream Zone.Identifier
      if ($z) {
        $zl = @($z | Where-Object { $_ -match '^ZoneId=' })
        if ($zl.Count -gt 0) {
          $zid = 0
          [void][int]::TryParse(($zl[0] -replace 'ZoneId=', ''), [ref]$zid)
          if ($zid -ge 3) {
            $score += 1; $why += 'Baixado da internet'
            $hu = @($z | Where-Object { $_ -match '^HostUrl=' })
            if ($hu.Count -gt 0) { $origem = ($hu[0] -replace 'HostUrl=', '') }
            if ($scripts -contains $ext) { $score += 1 }
          }
        }
      }
      if ($f.BaseName -match $Kw) { $score += 2; $why += 'Nome suspeito' }
      if ($sigTypes -contains $ext) {
        $sig = Get-AuthenticodeSignature -LiteralPath $f.FullName
        $st = [string]$sig.Status
        if ($st -ne 'Valid') { $score += 2; $why += ('Sem assinatura valida (' + $st + ')') }
      }
      if ($score -ge 2) {
        $hash = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
        $found += [pscustomobject]@{
          Score      = $score
          Criado     = $f.CreationTime
          Arquivo    = $f.FullName
          Baixado_em = Fmt-Date $f.CreationTime
          Tamanho_KB = [math]::Round($f.Length / 1KB, 1)
          Origem_URL = $origem
          Motivos    = ($why -join '; ')
          SHA256     = $hash
        }
      }
    }
  }
  $found = @($found | Sort-Object Criado -Descending)
  $i = 0
  foreach ($x in $found) {
    $lvl = 2
    if ($x.Score -ge 4) { $lvl = 4 } elseif ($x.Score -ge 3) { $lvl = 3 }
    if ($i -lt 20) { Find-Out 'Download' $lvl ($x.Arquivo + '  [' + $x.Motivos + ']') }
    $i++
  }
  if ($found.Count -gt 20) { Find-Out 'Download' 1 ('+' + ($found.Count - 20) + ' arquivos suspeitos no relatorio') }
  if ($found.Count -eq 0 -and $others.Count -eq 0) { Find-Out 'Download' 0 'Nenhum arquivo suspeito nas pastas do usuario' }

  Rep ''; Rep '[Arquivos suspeitos em Downloads / Desktop / Documentos / Temp]'
  Rep '  Criterios: nome de cheat/hack/crack/etc, sem assinatura digital valida, baixado da internet (Zone.Identifier).'
  Rep-List ($found | Select-Object Arquivo, Baixado_em, Tamanho_KB, Origem_URL, Motivos, SHA256)
  if ($found.Count -gt 0) { Rep '  Dica: cole o SHA256 em virustotal.com para confirmar se o arquivo e malicioso.' }
  Rep ''; Rep '[Downloads incompletos / Unicode Bypass]'
  Rep-Table $others

  $global:Stat['Ameacas do Defender'] = $dets.Count
  $global:Stat['Arquivos suspeitos baixados'] = $found.Count
  $global:Stat['Unicode / downloads incompletos'] = $others.Count
}

function Scan-Processes {
  Sec 'PROCESSOS EM EXECUCAO'
  $sysNames = 'svchost.exe', 'lsass.exe', 'csrss.exe', 'winlogon.exe', 'services.exe', 'smss.exe', 'wininit.exe', 'taskhostw.exe', 'dllhost.exe', 'runtimebroker.exe', 'spoolsv.exe', 'fontdrvhost.exe', 'sihost.exe'
  $procs = @(Get-CimInstance Win32_Process)
  $flag = 0
  foreach ($p in $procs) {
    $path = [string]$p.ExecutablePath
    $nm = [string]$p.Name
    if (-not $path) { continue }
    $ln = $nm.ToLower()
    $s32 = $env:windir + '\System32\*'
    $s64 = $env:windir + '\SysWOW64\*'
    if (($sysNames -contains $ln) -and ($path -notlike $s32) -and ($path -notlike $s64)) {
      Find-Out 'Processo' 4 ('Processo do sistema FORA do System32: ' + $nm + ' (PID ' + $p.ProcessId + ') -> ' + $path); $flag++; continue
    }
    if ($ln -eq 'explorer.exe' -and $path -notlike ($env:windir + '\explorer.exe')) {
      Find-Out 'Processo' 4 ('explorer.exe falso (PID ' + $p.ProcessId + ') -> ' + $path); $flag++; continue
    }
    if ($nm -match $Kw) { Find-Out 'Processo' 4 ('Processo suspeito: ' + $nm + ' (PID ' + $p.ProcessId + ') -> ' + $path); $flag++ }
    elseif ($path -match $SusPath) { Find-Out 'Processo' 3 ('Executando de pasta suspeita: ' + $nm + ' (PID ' + $p.ProcessId + ') -> ' + $path); $flag++ }
  }
  if ($flag -eq 0) { Find-Out 'Processo' 0 ('Nenhum processo suspeito (' + $procs.Count + ' analisados)') }
}

function Scan-Services {
  Sec 'SERVICOS E BYPASS'
  $svcList = @(
    @{ N = 'EventLog'; D = 'Log de Eventos'; Crit = 4 },
    @{ N = 'Winmgmt';  D = 'WMI'; Crit = 3 },
    @{ N = 'PcaSvc';   D = 'Assistente de Compatibilidade (registra execucoes)'; Crit = 3 },
    @{ N = 'SysMain';  D = 'SysMain / Prefetch'; Crit = 3 },
    @{ N = 'DPS';      D = 'Diagnostic Policy Service'; Crit = 3 },
    @{ N = 'Schedule'; D = 'Agendador de Tarefas'; Crit = 3 },
    @{ N = 'WinDefend'; D = 'Windows Defender'; Crit = 3 },
    @{ N = 'Appinfo';  D = 'Informacoes do Aplicativo'; Crit = 2 }
  )
  $issues = 0
  foreach ($s in $svcList) {
    $svc = Get-Service -Name $s.N
    if (-not $svc) { Find-Out 'Servico' 2 ('Erro, servico nao encontrado: ' + $s.N + ' (' + $s.D + ')'); $issues++; continue }
    if ([string]$svc.StartType -eq 'Disabled') {
      Find-Out 'Servico' $s.Crit ('Possivel Bypass: servico desabilitado - ' + $s.N + ' (' + $s.D + ')'); $issues++
    } elseif ([string]$svc.Status -ne 'Running') {
      $l = 1; if ([string]$svc.StartType -eq 'Automatic') { $l = $s.Crit }
      Find-Out 'Servico' $l ('Servico parado (' + $svc.StartType + '): ' + $s.N + ' (' + $s.D + ')'); $issues++
    }
  }
  $bamDrv = Get-CimInstance Win32_SystemDriver -Filter "Name='bam'"
  if (-not $bamDrv) { Find-Out 'Servico' 2 'Erro, driver BAM nao encontrado'; $issues++ }
  elseif ($bamDrv.StartMode -eq 'Disabled') { Find-Out 'Servico' 3 'Possivel Bypass: driver BAM desabilitado'; $issues++ }
  $pfReg = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters').EnablePrefetcher
  if ($pfReg -eq 0) { Find-Out 'Servico' 3 'Possivel Bypass: Prefetch DESABILITADO no registro (EnablePrefetcher=0)'; $issues++ }
  if ($issues -eq 0) { Find-Out 'Servico' 0 'Servicos importantes ativos e sem sinais de bypass' }

  Sec 'TAREFAS AGENDADAS'
  Put '  Analisando tarefas...' DarkGray; Nl
  $tasks = @(Get-ScheduledTask | Where-Object { [string]$_.State -ne 'Disabled' })
  $recent = @()
  $tflag = 0
  foreach ($t in $tasks) {
    foreach ($a in @($t.Actions)) {
      $exe = [Environment]::ExpandEnvironmentVariables([string]$a.Execute)
      if ($exe -and (($exe -match $SusPath) -or (($exe -split '[\\/]')[-1] -match $Kw))) {
        Find-Out 'Tarefa' 3 ('Tarefa executa de pasta suspeita: ' + $t.TaskName + ' -> ' + $exe); $tflag++
      }
    }
    $info = Get-ScheduledTaskInfo -TaskName $t.TaskName -TaskPath $t.TaskPath
    if ($info -and $info.LastRunTime -gt (Get-Date).AddDays(-1)) { $recent += [pscustomobject]@{ Nome = $t.TaskName; Data = $info.LastRunTime } }
  }
  $i = 0
  foreach ($r in ($recent | Sort-Object Data -Descending)) {
    if ($i -ge 8) { break }
    Find-Out 'Tarefa' 1 ('Tarefa: ' + $r.Nome + ' as ' + (Fmt-Date $r.Data)); $i++
  }
  $ev = @(Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-TaskScheduler/Operational'; Id = 106, 140, 141 } -MaxEvents 10)
  foreach ($e in $ev) {
    $kind = 'alterada'; $lv = 1
    if ($e.Id -eq 106) { $kind = 'criada' } elseif ($e.Id -eq 141) { $kind = 'APAGADA'; $lv = 2 }
    Find-Out 'Tarefa' $lv ('Tarefa ' + $kind + ' em ' + (Fmt-Date $e.TimeCreated))
    Add-Tl $e.TimeCreated 'Tarefa' ('Tarefa agendada ' + $kind) $lv
  }
  if ($tflag -eq 0) { Find-Out 'Tarefa' 0 'Nenhuma tarefa agendada apontando para pastas suspeitas' }
}

function Scan-Network {
  Sec 'REDE'
  $priv = '^(127\.|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|169\.254\.|::1|fe80|0\.0\.0\.0|::)'
  $cons = @(Get-NetTCPConnection -State Established | Where-Object { $_.RemoteAddress -notmatch $priv })
  $groups = @($cons | Group-Object OwningProcess)
  $flag = 0
  foreach ($g in $groups) {
    $pr = Get-CimInstance Win32_Process -Filter ('ProcessId=' + $g.Name)
    $nm = [string]$pr.Name
    $path = [string]$pr.ExecutablePath
    $remote = (($g.Group | Select-Object -ExpandProperty RemoteAddress -Unique) | Select-Object -First 3) -join ', '
    if ($nm -match $Kw) { Find-Out 'Rede' 4 ('Conexao externa de processo suspeito: ' + $nm + ' -> ' + $remote); $flag++ }
    elseif ($path -match $SusPath) { Find-Out 'Rede' 3 ('Conexao externa de pasta suspeita: ' + $nm + ' -> ' + $remote); $flag++ }
  }
  Find-Out 'Rede' 1 ([string]$cons.Count + ' conexoes externas ativas em ' + [string]$groups.Count + ' processos')
  $hosts = @(Get-Content ($env:windir + '\System32\drivers\etc\hosts') | Where-Object { $_ -match '^\s*[0-9a-fA-F:.]+\s+\S+' -and $_ -notmatch '^\s*#' -and $_ -notmatch 'localhost' })
  foreach ($h in $hosts) { Find-Out 'Rede' 2 ('Entrada personalizada no arquivo hosts: ' + $h.Trim()) }
  $inet = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
  if ($inet.ProxyEnable -eq 1) { Find-Out 'Rede' 2 ('Proxy ativo: ' + $inet.ProxyServer) }
  if ($flag -eq 0 -and $hosts.Count -eq 0) { Find-Out 'Rede' 0 'Nenhuma conexao suspeita' }
}

function Scan-Security {
  Sec 'SEGURANCA DO WINDOWS'
  $mp = Get-MpComputerStatus
  if (-not $mp) { Find-Out 'Defender' 2 'Nao foi possivel consultar o Defender (antivirus de terceiros?)' }
  else {
    if ($mp.RealTimeProtectionEnabled) { Find-Out 'Defender' 0 'Protecao em tempo real ATIVA' } else { Find-Out 'Defender' 3 'Protecao em tempo real DESATIVADA' }
    if (-not $mp.AntivirusEnabled) { Find-Out 'Defender' 3 'Antivirus do Defender DESATIVADO' }
    $age = (Get-Date) - $mp.AntivirusSignatureLastUpdated
    if ($age.TotalDays -gt 7) { Find-Out 'Defender' 2 ('Assinaturas desatualizadas: ' + (Fmt-Date $mp.AntivirusSignatureLastUpdated)) }
    else { Find-Out 'Defender' 0 ('Assinaturas atualizadas em ' + (Fmt-Date $mp.AntivirusSignatureLastUpdated)) }
  }
  $pref = Get-MpPreference
  foreach ($x in @($pref.ExclusionPath))      { if ($x -and $x -notlike 'N/A*') { Find-Out 'Defender' 3 ('Exclusao de pasta/arquivo no Defender: ' + $x) } }
  foreach ($x in @($pref.ExclusionProcess))   { if ($x -and $x -notlike 'N/A*') { Find-Out 'Defender' 3 ('Exclusao de processo no Defender: ' + $x) } }
  foreach ($x in @($pref.ExclusionExtension)) { if ($x -and $x -notlike 'N/A*') { Find-Out 'Defender' 3 ('Exclusao de extensao no Defender: ' + $x) } }

  $fwOff = 0
  foreach ($fp in @(Get-NetFirewallProfile)) {
    if ([string]$fp.Enabled -eq 'False') { Find-Out 'Firewall' 2 ('Firewall DESATIVADO no perfil ' + $fp.Name); $fwOff++ }
  }
  if ($fwOff -eq 0) { Find-Out 'Firewall' 0 'Firewall ativo em todos os perfis' }

  try {
    $sb = Confirm-SecureBootUEFI -ErrorAction Stop
    if ($sb) { Find-Out 'Boot' 0 'Secure Boot ATIVO' } else { Find-Out 'Boot' 3 'Secure Boot DESATIVADO' }
  } catch { Find-Out 'Boot' 1 'Secure Boot indisponivel (BIOS legado ou sem admin)' }

  $tpm = Get-Tpm
  if (-not $tpm) { Find-Out 'TPM' 1 'TPM nao consultavel (requer admin)' }
  elseif (-not $tpm.TpmPresent) { Find-Out 'TPM' 2 'TPM ausente ou desativado na BIOS' }
  else { Find-Out 'TPM' 0 ('TPM presente - Ativado: ' + $tpm.TpmEnabled + ' / Pronto: ' + $tpm.TpmReady) }

  $bcd = (bcdedit 2>$null | Out-String)
  if (-not $bcd.Trim()) { Find-Out 'Boot' 1 'bcdedit requer admin - modo de teste/debug nao verificado' }
  else {
    $bcdBad = 0
    if ($bcd -match '(?im)^\s*testsigning\s+(Yes|Sim)') { Find-Out 'Boot' 4 'TESTSIGNING ativo - drivers sem assinatura permitidos'; $bcdBad++ }
    if ($bcd -match '(?im)^\s*nointegritychecks\s+(Yes|Sim)') { Find-Out 'Boot' 4 'NOINTEGRITYCHECKS ativo - verificacao de assinatura desligada'; $bcdBad++ }
    if ($bcd -match '(?im)^\s*debug\s+(Yes|Sim)') { Find-Out 'Boot' 3 'Modo DEBUG do kernel ativo'; $bcdBad++ }
    if ($bcdBad -eq 0) { Find-Out 'Boot' 0 'Sem modo de teste / debug no boot' }
  }

  Sec 'DRIVERS E DISPOSITIVOS'
  $vuln = 'iqvw64e', 'iqvw64', 'capcom', 'gdrv', 'rtcore64', 'rtcore32', 'dbutil_2_3', 'asio3', 'asmmap64', 'atszio', 'winring0', 'winring0x64', 'physmem', 'wnbios', 'glckio2', 'msio64', 'lnvmsrio', 'pdfwkrnl', 'kprocesshacker', 'hwrwdrv', 'inpoutx64', 'mhyprot2', 'mhyprot3', 'zam64', 'ntiolib', 'ntiolib_x64', 'gmer64', 'cpuz141', 'bs_def64', 'nvoclock'
  $drv = @(Get-CimInstance Win32_SystemDriver)
  $vf = 0; $odd = 0
  foreach ($d in $drv) {
    $pathStr = [string]$d.PathName
    $leaf = (($pathStr -split '[\\/]')[-1] -replace '\.sys$', '').ToLower()
    $dn = ([string]$d.Name).ToLower()
    if (($vuln -contains $leaf) -or ($vuln -contains $dn)) {
      Find-Out 'Driver' 4 ('Driver vulneravel/mapper conhecido: ' + $d.Name + ' (' + $d.State + ') -> ' + $pathStr); $vf++
    } elseif ($d.State -eq 'Running' -and $pathStr -and $pathStr -notmatch '(?i)(system32\\drivers|DriverStore|\\SystemRoot\\)') {
      if ($odd -lt 8) { Find-Out 'Driver' 2 ('Driver carregado fora de System32\drivers: ' + $d.Name + ' -> ' + $pathStr) }
      $odd++
    }
  }
  if ($vf -eq 0) { Find-Out 'Driver' 0 ('Nenhum driver vulneravel conhecido (' + $drv.Count + ' drivers analisados)') }
  if ($odd -gt 8) { Find-Out 'Driver' 1 ('+' + ($odd - 8) + ' drivers fora do padrao') }

  $badDev = @(Get-PnpDevice | Where-Object { [string]$_.Status -eq 'Error' -or [string]$_.Status -eq 'Degraded' })
  foreach ($dv in $badDev) { Find-Out 'Disp' 2 ('Dispositivo com problema: ' + $dv.FriendlyName + ' [' + $dv.Class + ']') }
  if ($badDev.Count -eq 0) { Find-Out 'Disp' 0 'Nenhum dispositivo com erro' }
  foreach ($gpu in @(Get-CimInstance Win32_VideoController)) { Find-Out 'Disp' 1 ('Video: ' + $gpu.Name + '  driver ' + $gpu.DriverVersion) }
}

# ================================================================
#  FIVEM / GTA V
# ================================================================
$FvKw = '(?i)(eulen|redengine|skript\.gg|susano|mod ?menu|lua ?executor)'
function Test-FvName([string]$n) { return (($n -match $Kw) -or ($n -match $FvKw)) }

function Scan-FiveM {
  Sec 'FIVEM / GTA V'
  Rep-Sec '5. FIVEM / GTA V'
  Put '  Procurando pastas, plugins, logs e DLLs carregadas...' DarkGray; Nl; Nl

  $fvRoot  = Join-Path $env:LOCALAPPDATA 'FiveM'
  $fvApp   = Join-Path $fvRoot 'FiveM.app'
  $hasFv   = Test-Path -LiteralPath $fvApp
  $loaders = '(?i)^(dinput8\.dll|scripthookv.*\.dll|scripthookvdotnet.*|openiv\.asi|asiloader.*)$'
  $hooks   = '(?i)^(dxgi\.dll|d3d11\.dll|d3d10\.dll|d3d9\.dll|reshade.*|enbseries.*|enblocal\.ini)$'
  $fvExt   = $ExecExt + $ArcExt + '.asi'

  # ---- onde estao o FiveM e o GTA V
  $cand = New-Object System.Collections.Generic.List[string]
  foreach ($ini in @((Join-Path $fvApp 'CitizenFX.ini'), (Join-Path $fvRoot 'CitizenFX.ini'))) {
    if (Test-Path -LiteralPath $ini) {
      foreach ($ln in @(Get-Content -LiteralPath $ini)) {
        if ($ln -match '^\s*IVPath\s*=\s*(.+?)\s*$') { $cand.Add($Matches[1]) }
      }
    }
  }
  foreach ($rk in @('HKLM:\SOFTWARE\WOW6432Node\Rockstar Games\Grand Theft Auto V', 'HKLM:\SOFTWARE\Rockstar Games\Grand Theft Auto V', 'HKLM:\SOFTWARE\WOW6432Node\Rockstar Games\GTAV')) {
    $v = [string](Get-ItemProperty -LiteralPath $rk).InstallFolder
    if ($v) { $cand.Add($v) }
  }
  $pf86 = ${env:ProgramFiles(x86)}
  foreach ($cp in @(($env:ProgramFiles + '\Rockstar Games\Grand Theft Auto V'), ($pf86 + '\Steam\steamapps\common\Grand Theft Auto V'), ($env:ProgramFiles + '\Epic Games\GTAV'))) { $cand.Add($cp) }
  foreach ($gp in @(Get-Process | Where-Object { $_.ProcessName -match '(?i)^GTA5$' })) { if ($gp.Path) { $cand.Add((Split-Path -Parent ([string]$gp.Path))) } }
  $gta = @($cand | ForEach-Object { ([string]$_).Trim().Trim('"').TrimEnd('\') } | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique)

  if ($hasFv) {
    Find-Out 'FiveM' 1 ('FiveM em: ' + $fvApp)
    $ct = (Get-Item -LiteralPath $fvApp).CreationTime
    if ($ct -gt (Get-Date).AddDays(-7)) { Find-Out 'FiveM' 2 ('Pasta do FiveM criada ha poucos dias (' + (Fmt-Date $ct) + ') - possivel reinstalacao') }
    else { Find-Out 'FiveM' 1 ('Pasta do FiveM criada em ' + (Fmt-Date $ct)) }
  } else {
    Find-Out 'FiveM' 1 'FiveM nao encontrado em %LocalAppData%\FiveM (nao instalado ou em outro local)'
  }
  if ($gta.Count -eq 0) { Find-Out 'GTA V' 1 'Pasta do GTA V nao localizada' }
  foreach ($g in $gta) { Find-Out 'GTA V' 1 ('GTA V em: ' + $g) }
  Rep ''; Rep '[Instalacoes encontradas]'
  Rep ('  FiveM : ' + $(if ($hasFv) { $fvApp } else { 'nao encontrado' }))
  foreach ($g in $gta) { Rep ('  GTA V : ' + $g) }

  # ---- arquivos suspeitos nas pastas do jogo
  $rows = New-Object System.Collections.Generic.List[object]
  foreach ($g in $gta) {
    foreach ($f in @(Get-ChildItem -LiteralPath $g -File -Force)) {
      $n = $f.Name; $ext = $f.Extension.ToLower(); $lvl = -1; $why = ''
      if (Test-FvName $n) { $lvl = 4; $why = 'Nome de cheat/injetor' }
      elseif (($ext -eq '.asi') -or ($n -match $loaders)) { $lvl = 3; $why = 'ASI loader / ScriptHook / plugin .asi na pasta do GTA' }
      elseif ($n -match $hooks) { $lvl = 2; $why = 'Hook grafico (ReShade/ENB) - pode ser legitimo' }
      elseif (($ext -eq '.dll') -or ($ext -eq '.exe')) {
        $st = [string](Get-AuthenticodeSignature -LiteralPath $f.FullName).Status
        if ($st -ne 'Valid') { $lvl = 2; $why = 'Sem assinatura valida (' + $st + ')' }
      }
      if ($lvl -ge 0) { $rows.Add([pscustomobject]@{ Lvl = $lvl; Nivel = $LV[$lvl].Name; Arquivo = $f.FullName; Modificado = (Fmt-Date $f.LastWriteTime); Motivo = $why }) }
    }
    foreach ($sub in 'mods', 'scripts', 'plugins') {
      $sp = Join-Path $g $sub
      if (Test-Path -LiteralPath $sp) { $rows.Add([pscustomobject]@{ Lvl = 2; Nivel = $LV[2].Name; Arquivo = $sp; Modificado = (Fmt-Date (Get-Item -LiteralPath $sp).LastWriteTime); Motivo = 'Pasta de mods dentro do GTA V' }) }
    }
  }
  if ($hasFv) {
    $skipDir = '(?i)\\(data\\(server-)?cache|logs|crashes|cache)\\'
    foreach ($f in @(Get-ChildItem -LiteralPath $fvApp -Recurse -Depth 3 -File -Force)) {
      $ext = $f.Extension.ToLower()
      if ($fvExt -notcontains $ext) { continue }
      if ($f.FullName -match $skipDir) { continue }
      $n = $f.Name; $lvl = -1; $why = ''
      if (Test-FvName $n) { $lvl = 4; $why = 'Nome de cheat/injetor' }
      elseif (($ext -eq '.asi') -or ($n -match $loaders)) { $lvl = 3; $why = 'ASI loader / plugin .asi dentro do FiveM' }
      elseif (($f.FullName -match '(?i)\\plugins\\') -and ($ExecExt -contains $ext)) { $lvl = 3; $why = 'Executavel na pasta plugins do FiveM' }
      if ($lvl -ge 0) { $rows.Add([pscustomobject]@{ Lvl = $lvl; Nivel = $LV[$lvl].Name; Arquivo = $f.FullName; Modificado = (Fmt-Date $f.LastWriteTime); Motivo = $why }) }
    }
  }
  $sh = 0
  foreach ($r in @($rows | Sort-Object Lvl -Descending)) {
    if ($sh -ge 15) { break }
    Find-Out 'Arquivos' $r.Lvl ($r.Arquivo + '  [' + $r.Motivo + ']'); $sh++
  }
  if ($rows.Count -gt 15) { Find-Out 'Arquivos' 1 ('+' + ($rows.Count - 15) + ' achados no relatorio') }
  if ($rows.Count -eq 0) { Find-Out 'Arquivos' 0 'Nenhum arquivo suspeito nas pastas do GTA V / FiveM' }
  Rep ''; Rep '[Arquivos suspeitos nas pastas do GTA V / FiveM]'
  Rep-Table @($rows | Sort-Object Lvl -Descending | Select-Object Nivel, Arquivo, Modificado, Motivo)

  # ---- logs do FiveM
  $logs = @()
  if ($hasFv) { $logs = @(Get-ChildItem -LiteralPath (Join-Path $fvApp 'logs') -Filter 'CitizenFX_log*' -File -Force | Sort-Object LastWriteTime -Descending) }
  $hits = New-Object System.Collections.Generic.List[object]
  if ($hasFv) {
    if ($logs.Count -eq 0) {
      Find-Out 'Logs' 2 'Nenhum log do FiveM (pasta logs vazia ou apagada) - possivel limpeza'
    } else {
      Find-Out 'Logs' 1 ([string]$logs.Count + ' logs do FiveM - mais recente: ' + ($logs[0].Name -replace '^CitizenFX_log_', '') + ' (' + (Fmt-Date $logs[0].LastWriteTime) + ')')
      $pat = '(?i)(\.asi\b|dinput8|scripthook|openiv|\binject|\bcheat|\bhack|executor|eulen|redengine|skript\.gg|susano|mod ?menu)'
      foreach ($lg in @($logs | Select-Object -First 5)) {
        foreach ($m in @(Select-String -LiteralPath $lg.FullName -Pattern $pat)) {
          $t = ([string]$m.Line).Trim(); if ($t.Length -gt 200) { $t = $t.Substring(0, 200) }
          $hits.Add([pscustomobject]@{ Log = $lg.Name; Linha = $m.LineNumber; Trecho = $t })
        }
      }
      $i = 0
      foreach ($h in $hits) {
        if ($i -ge 8) { break }
        $tt = $h.Trecho; if ($tt.Length -gt 55) { $tt = $tt.Substring(0, 55) }
        Find-Out 'Logs' 3 (($h.Log -replace '^CitizenFX_log_', '') + ' L' + $h.Linha + ': ' + $tt); $i++
      }
      if ($hits.Count -gt 8) { Find-Out 'Logs' 1 ('+' + ($hits.Count - 8) + ' trechos no relatorio') }
      if ($hits.Count -eq 0) { Find-Out 'Logs' 0 'Nada suspeito nos ultimos logs do FiveM' }
    }
  }
  Rep ''; Rep '[Trechos suspeitos nos logs do FiveM (5 logs mais recentes)]'
  Rep-Table @($hits)

  # ---- sessoes (Prefetch) e o que abriu perto da ultima sessao (BAM)
  $pfDir = Join-Path $env:windir 'Prefetch'
  $pfFv = @(Get-ChildItem -LiteralPath $pfDir -Filter *.pf -File | Where-Object { $_.Name -match '(?i)^(FIVEM|GTA5)' } | Sort-Object LastWriteTime -Descending)
  foreach ($p in @($pfFv | Select-Object -First 6)) {
    Find-Out 'Sessao' 1 (($p.Name -replace '-[0-9A-F]{8}\.pf$', '') + '  1a vez ' + (Fmt-Date $p.CreationTime) + '  ultima ' + (Fmt-Date $p.LastWriteTime))
    Add-Tl $p.LastWriteTime 'FiveM/GTA' ('Jogo executado: ' + ($p.Name -replace '-[0-9A-F]{8}\.pf$', '')) 1
  }
  if ($pfFv.Count -eq 0) {
    if (-not $IsAdmin) { Find-Out 'Sessao' 1 'Prefetch sem acesso (rode como ADMIN)' }
    elseif ($logs.Count -gt 0) { Find-Out 'Sessao' 2 'FiveM tem logs mas nao tem Prefetch - Prefetch limpo ou desativado' }
  }
  Rep ''; Rep '[Execucoes do FiveM / GTA V no Prefetch]'
  Rep-Table @($pfFv | Select-Object @{n='Programa';e={$_.Name -replace '-[0-9A-F]{8}\.pf$',''}}, @{n='Primeira';e={Fmt-Date $_.CreationTime}}, @{n='Ultima';e={Fmt-Date $_.LastWriteTime}})

  $sStart = $null; $sEnd = $null
  if ($logs.Count -gt 0) { $sStart = $logs[0].CreationTime; $sEnd = $logs[0].LastWriteTime }
  elseif ($pfFv.Count -gt 0) { $sStart = $pfFv[0].LastWriteTime; $sEnd = $pfFv[0].LastWriteTime }
  $near = @()
  if ($sStart) {
    $from = $sStart.AddHours(-2); $to = $sEnd.AddHours(1)
    $skip = '(?i)\\(Windows|Program Files|Program Files \(x86\))\\'
    foreach ($e in @(Get-Bam)) {
      if (($e.Data -lt $from) -or ($e.Data -gt $to)) { continue }
      $pth = [string]$e.Programa
      $leaf = ($pth -split '[\\/]')[-1]
      $lvl = 2
      if (Test-FvName $leaf) { $lvl = 4 }
      elseif ($pth -match $skip) { continue }
      elseif ($pth -match $SusPath) { $lvl = 3 }
      Add-Tl $e.Data 'Aberto perto do jogo' $pth $lvl
      $near += [pscustomobject]@{ Lvl = $lvl; Nivel = $LV[$lvl].Name; Data = (Fmt-Date $e.Data); Programa = $pth }
    }
    $near = @($near | Sort-Object Lvl -Descending)
    $i = 0
    foreach ($x in $near) {
      if ($i -ge 10) { break }
      Find-Out 'Sessao' $x.Lvl ('Aberto perto da ultima sessao: ' + $x.Programa + '  (' + $x.Data + ')'); $i++
    }
    if ($near.Count -gt 10) { Find-Out 'Sessao' 1 ('+' + ($near.Count - 10) + ' itens no relatorio') }
    if ($near.Count -eq 0) { Find-Out 'Sessao' 0 'Nenhum executavel fora do padrao aberto perto da ultima sessao' }
  }
  Rep ''; Rep ('[Executaveis abertos de 2h antes ate 1h depois da ultima sessao do FiveM (BAM)]')
  Rep-Table @($near | Select-Object Nivel, Data, Programa)

  # ---- TUDO que rodou com o FiveM / GTA V aberto (janela exata da sessao, sem filtro de suspeita)
  $everything = @()
  if ($sStart -and $sEnd) {
    foreach ($e in @(Get-Bam)) {
      if (($e.Data -lt $sStart) -or ($e.Data -gt $sEnd)) { continue }
      $pth = [string]$e.Programa
      $leaf = ($pth -split '[\\/]')[-1]
      $everything += [pscustomobject]@{ Data = (Fmt-Date $e.Data); Programa = $pth; Nome = $leaf }
    }
    $everything = @($everything | Sort-Object Data -Descending)
  }
  $i = 0
  foreach ($x in $everything) {
    if ($i -ge 25) { break }
    Find-Out 'Executado' 1 ($x.Nome + '  (' + $x.Data + ')'); $i++
  }
  if ($everything.Count -gt 25) { Find-Out 'Executado' 1 ('+' + ($everything.Count - 25) + ' itens no relatorio') }
  if ($sStart -and $everything.Count -eq 0) { Find-Out 'Executado' 1 'Nenhum registro (BAM) dentro da janela exata da sessao' }
  if (-not $sStart) { Find-Out 'Executado' 1 'Sessao do FiveM nao detectada (sem log/Prefetch) - nao foi possivel montar a janela' }
  Rep ''
  Rep ('[TUDO que foi executado com o FiveM / GTA V aberto - sessao ' + $(if ($sStart) { Fmt-Date $sStart } else { '?' }) + ' ate ' + $(if ($sEnd) { Fmt-Date $sEnd } else { '?' }) + ']')
  Rep-Table @($everything | Select-Object Nome, Programa, Data)
  $global:Stat['Executados durante a sessao do FiveM'] = $everything.Count

  # ---- DLLs carregadas no jogo (so funciona com o jogo aberto)
  $game = @(Get-Process | Where-Object { $_.ProcessName -match '(?i)(GTAProcess|^GTA5$)' })
  $modRows = New-Object System.Collections.Generic.List[object]
  $modTotal = 0
  if ($game.Count -eq 0) { Find-Out 'Modulos' 1 'GTA V / FiveM fechado - abra o jogo e rode de novo para checar as DLLs carregadas' }
  foreach ($gp in $game) {
    $mods = @()
    try { $mods = @($gp.Modules | Where-Object { $_ }) } catch { $mods = @() }
    if ($mods.Count -eq 0) {
      Find-Out 'Modulos' 2 ('Sem acesso aos modulos de ' + $gp.ProcessName + ' (PID ' + $gp.Id + ') - rode como ADMIN'); continue
    }
    $winDir = $env:windir + '\'
    $mFlag = 0
    foreach ($m in $mods) {
      $fp = [string]$m.FileName
      if (-not $fp) { continue }
      $modTotal++
      if ($fp.StartsWith($winDir, [StringComparison]::OrdinalIgnoreCase)) { continue }
      $leaf = [IO.Path]::GetFileName($fp)
      $lvl = -1; $why = ''
      if (Test-FvName $leaf) { $lvl = 4; $why = 'Nome de cheat/injetor' }
      elseif ($fp -match '(?i)\\(Downloads|Desktop)\\') { $lvl = 4; $why = 'DLL carregada de Downloads/Desktop' }
      elseif ($fp -match '(?i)\\(Temp|Users\\Public)\\') { $lvl = 3; $why = 'DLL carregada de Temp/Public' }
      elseif (-not (Test-Path -LiteralPath $fp)) { $lvl = 3; $why = 'Arquivo nao existe mais no disco (apagado depois de carregar?)' }
      elseif (($leaf -match '(?i)\.asi$') -or ($leaf -match $loaders)) { $lvl = 3; $why = 'ASI loader / ScriptHook carregado no jogo' }
      else {
        $st = [string](Get-AuthenticodeSignature -LiteralPath $fp).Status
        if ($st -ne 'Valid') { $lvl = 2; $why = 'Sem assinatura valida (' + $st + ')' }
      }
      if ($lvl -ge 0) {
        $mFlag++
        $modRows.Add([pscustomobject]@{ Lvl = $lvl; Nivel = $LV[$lvl].Name; Processo = $gp.ProcessName; Modulo = $fp; Motivo = $why })
      }
    }
    if ($mFlag -eq 0) { Find-Out 'Modulos' 0 ('Nenhum modulo suspeito em ' + $gp.ProcessName + ' (' + $mods.Count + ' modulos)') }
    else { Find-Out 'Modulos' 1 ($gp.ProcessName + ': ' + $mFlag + ' modulo(s) para conferir, de ' + $mods.Count + ' carregados') }
  }
  $sh = 0
  foreach ($r in @($modRows | Sort-Object Lvl -Descending)) {
    if ($sh -ge 15) { break }
    Find-Out 'Modulos' $r.Lvl ((Split-Path -Leaf $r.Modulo) + ' -> ' + $r.Modulo + '  [' + $r.Motivo + ']'); $sh++
  }
  if ($modRows.Count -gt 15) { Find-Out 'Modulos' 1 ('+' + ($modRows.Count - 15) + ' modulos no relatorio') }
  Rep ''; Rep '[DLLs carregadas no jogo (fora da pasta do Windows) - so os itens para conferir]'
  if ($game.Count -eq 0) { Rep '  Jogo fechado: abra o GTA V / FiveM e rode de novo.' }
  else { Rep-Table @($modRows | Sort-Object Lvl -Descending | Select-Object Nivel, Processo, Modulo, Motivo) }

  # ---- itens recentes com nome suspeito
  $rn = 0
  foreach ($f in @(Get-ChildItem -LiteralPath (Join-Path $env:APPDATA 'Microsoft\Windows\Recent') -Filter *.lnk -File -Force | Sort-Object LastWriteTime -Descending)) {
    if ($rn -ge 8) { break }
    if (Test-FvName $f.BaseName) { Find-Out 'Recentes' 3 ('Item recente com nome suspeito: ' + $f.BaseName + '  (' + (Fmt-Date $f.LastWriteTime) + ')'); $rn++ }
  }

  $global:Stat['Achados nas pastas FiveM/GTA'] = $rows.Count
  $global:Stat['Trechos suspeitos nos logs'] = $hits.Count
  $global:Stat['Modulos analisados no jogo'] = $modTotal
  $global:Stat['Modulos para conferir'] = $modRows.Count
}

# ================================================================
#  PC INTEIRO: sistema, inicializacao, programas, discos, navegadores, linha do tempo
# ================================================================
function Scan-System {
  Sec 'SISTEMA'
  Rep-Sec '6. SISTEMA E DADOS DO PC'
  $os = Get-CimInstance Win32_OperatingSystem
  $cs = Get-CimInstance Win32_ComputerSystem
  $cpu = @(Get-CimInstance Win32_Processor | Select-Object -First 1)
  $now = Get-Date
  $boot = $os.LastBootUpTime
  $inst = $os.InstallDate
  $tzName = [TimeZoneInfo]::Local.DisplayName
  $upTxt = '-'
  $up = $null
  if ($boot) { $up = $now - $boot; $upTxt = ('{0}d {1}h {2}min' -f $up.Days, $up.Hours, $up.Minutes) }
  $ram = 0
  if ($cs.TotalPhysicalMemory) { $ram = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1) }
  $users = @(Get-LocalUser | Where-Object { $_.Enabled } | ForEach-Object { $_.Name }) -join ', '
  $info = @()
  $info += [pscustomobject]@{ Item = 'Windows'; Valor = ([string]$os.Caption + ' - versao ' + $os.Version + ' (build ' + $os.BuildNumber + ')') }
  $info += [pscustomobject]@{ Item = 'Windows instalado em'; Valor = (Fmt-Date $inst) }
  $info += [pscustomobject]@{ Item = 'Ultimo boot'; Valor = (Fmt-Date $boot) }
  $info += [pscustomobject]@{ Item = 'Tempo ligado'; Valor = $upTxt }
  $info += [pscustomobject]@{ Item = 'Fuso horario'; Valor = $tzName }
  $info += [pscustomobject]@{ Item = 'Computador'; Valor = ([string]$cs.Manufacturer + ' ' + [string]$cs.Model) }
  if ($cpu.Count -gt 0) { $info += [pscustomobject]@{ Item = 'Processador'; Valor = ([string]$cpu[0].Name).Trim() } }
  $info += [pscustomobject]@{ Item = 'Memoria RAM'; Valor = ([string]$ram + ' GB') }
  $info += [pscustomobject]@{ Item = 'Usuario atual'; Valor = ($env:USERDOMAIN + '\' + $env:USERNAME) }
  $info += [pscustomobject]@{ Item = 'Contas locais ativas'; Valor = $users }

  Find-Out 'Sistema' 1 ('Windows: ' + [string]$os.Caption + ' build ' + $os.BuildNumber)
  if ($boot) {
    Add-Tl $boot 'Sistema' 'Windows iniciado (boot)' 1
    if ($up.TotalHours -lt 3) { Find-Out 'Sistema' 2 ('PC reiniciado ha pouco tempo - ultimo boot em ' + (Fmt-Date $boot) + ' (' + $upTxt + ')') }
    else { Find-Out 'Sistema' 1 ('Ultimo boot: ' + (Fmt-Date $boot) + '  (ligado ha ' + $upTxt + ')') }
  }
  if ($inst) {
    Add-Tl $inst 'Sistema' 'Windows instalado' 2
    $days = ($now - $inst).TotalDays
    if ($days -lt 7) { Find-Out 'Sistema' 3 ('Windows instalado/formatado ha menos de 7 dias (' + (Fmt-Date $inst) + ') - historico pode ter sido zerado') }
    elseif ($days -lt 30) { Find-Out 'Sistema' 2 ('Windows instalado ha menos de 30 dias (' + (Fmt-Date $inst) + ')') }
    else { Find-Out 'Sistema' 1 ('Windows instalado em ' + (Fmt-Date $inst)) }
  }
  if ([string]($cs.Manufacturer + ' ' + $cs.Model) -match '(?i)(virtual|vmware|vbox|kvm|qemu|hyper-v)') {
    Find-Out 'Sistema' 2 ('PC parece ser uma maquina virtual: ' + $cs.Manufacturer + ' ' + $cs.Model)
  }
  Find-Out 'Sistema' 1 ('Fuso horario: ' + $tzName)
  if ($users) { Find-Out 'Sistema' 1 ('Contas locais ativas: ' + $users) }

  if ($IsAdmin) {
    $tc = 0
    foreach ($e in @(Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 4616 } -MaxEvents 80)) {
      try {
        $pn = [string]$e.Properties[7].Value
        if ($pn -match '(?i)(svchost|vboxservice|vmtoolsd)') { continue }
        $diff = [math]::Abs((([datetime]$e.Properties[5].Value) - ([datetime]$e.Properties[4].Value)).TotalMinutes)
        if ($diff -gt 2 -and $tc -lt 5) {
          Find-Out 'Sistema' 3 ('Relogio do PC alterado em ' + (Fmt-Date $e.TimeCreated) + ' (' + [math]::Round($diff) + ' min) por ' + $pn)
          Add-Tl $e.TimeCreated 'Sistema' 'Relogio do PC alterado' 3
          $tc++
        }
      } catch {}
    }
  }

  Rep ''; Rep '[Dados do PC]'
  Rep-Table $info
  Rep ''; Rep '[Discos]'
  Rep-Table (@(Get-CimInstance Win32_LogicalDisk) | Select-Object @{n='Unidade';e={$_.DeviceID}}, @{n='Tipo';e={ switch ([int]$_.DriveType) { 2 { 'Removivel' } 3 { 'Fixo' } 4 { 'Rede' } 5 { 'CD/DVD' } default { 'Outro' } } }}, @{n='Nome';e={$_.VolumeName}}, @{n='Sistema';e={$_.FileSystem}}, @{n='Tamanho_GB';e={ if ($_.Size) { [math]::Round($_.Size / 1GB, 1) } else { '-' } }}, @{n='Livre_GB';e={ if ($_.Size) { [math]::Round($_.FreeSpace / 1GB, 1) } else { '-' } }})
  $global:Stat['Ultimo boot'] = (Fmt-Date $boot)
  $global:Stat['Windows instalado em'] = (Fmt-Date $inst)
}

function Scan-Startup {
  Sec 'INICIALIZACAO DO WINDOWS'
  Rep-Sec '7. O QUE INICIA COM O WINDOWS'
  $rows = New-Object System.Collections.Generic.List[object]
  $addRow = {
    param($Origem, $Nome, $Cmd)
    $lvl = 1
    if (([string]$Nome -match $Kw) -or ([string]$Cmd -match $Kw)) { $lvl = 4 }
    elseif ([string]$Cmd -match $SusPath) { $lvl = 3 }
    $rows.Add([pscustomobject]@{ Lvl = $lvl; Nivel = $LV[$lvl].Name; Origem = $Origem; Nome = [string]$Nome; Comando = [string]$Cmd })
  }
  $runKeys = @(
    @{ P = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run';     O = 'Registro do usuario (Run)' },
    @{ P = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce'; O = 'Registro do usuario (RunOnce)' },
    @{ P = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run';     O = 'Registro do sistema (Run)' },
    @{ P = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce'; O = 'Registro do sistema (RunOnce)' },
    @{ P = 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'; O = 'Registro 32-bit (Run)' }
  )
  foreach ($k in $runKeys) {
    $it = Get-Item -LiteralPath $k.P
    if (-not $it) { continue }
    foreach ($n in $it.GetValueNames()) { & $addRow $k.O $n ([string]$it.GetValue($n)) }
  }
  $sfs = @(
    @{ P = [Environment]::GetFolderPath('Startup');       O = 'Pasta Inicializar (usuario)' },
    @{ P = [Environment]::GetFolderPath('CommonStartup'); O = 'Pasta Inicializar (todos)' }
  )
  foreach ($sf in $sfs) {
    if (-not $sf.P) { continue }
    foreach ($f in @(Get-ChildItem -LiteralPath $sf.P -Force -File)) {
      if ($f.Name -ieq 'desktop.ini') { continue }
      & $addRow $sf.O $f.Name $f.FullName
    }
  }

  $bad = 0
  $wl = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
  if ($wl) {
    if ($wl.Shell -and (([string]$wl.Shell).Trim() -ine 'explorer.exe')) { Find-Out 'Inicio' 4 ('Winlogon Shell alterado: ' + $wl.Shell); $bad++ }
    $ui = ([string]$wl.Userinit).Trim().TrimEnd(',')
    if ($ui -and ($ui -notmatch ('(?i)^' + [regex]::Escape($env:windir + '\system32\userinit.exe') + '$'))) { Find-Out 'Inicio' 4 ('Winlogon Userinit alterado: ' + $wl.Userinit); $bad++ }
  }
  foreach ($k in @(Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options')) {
    $dbg = (Get-ItemProperty -LiteralPath $k.PSPath).Debugger
    if ($dbg -and ([string]$dbg -notmatch '(?i)vsjitdebugger')) { Find-Out 'Inicio' 3 ('IFEO Debugger em ' + $k.PSChildName + ': ' + $dbg); $bad++ }
  }
  $ai = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows').AppInit_DLLs
  if ($ai -and ([string]$ai).Trim()) { Find-Out 'Inicio' 3 ('AppInit_DLLs configurado: ' + $ai); $bad++ }

  $sorted = @($rows | Sort-Object Lvl -Descending)
  $i = 0
  foreach ($r in $sorted) {
    if ($r.Lvl -lt 3) { continue }
    if ($i -ge 12) { break }
    Find-Out 'Inicio' $r.Lvl ('Inicia com o Windows: ' + $r.Nome + ' -> ' + $r.Comando + '  [' + $r.Origem + ']'); $i++
  }
  $flagged = @($sorted | Where-Object { $_.Lvl -ge 3 }).Count
  if ($flagged -gt 12) { Find-Out 'Inicio' 1 ('+' + ($flagged - 12) + ' itens de inicializacao no relatorio') }
  if ($flagged -eq 0 -and $bad -eq 0) { Find-Out 'Inicio' 0 ('Nenhuma entrada de inicializacao suspeita (' + $rows.Count + ' analisadas)') }
  else { Find-Out 'Inicio' 1 ($rows.Count + ' entradas de inicializacao analisadas') }
  Rep ''; Rep '[Programas que iniciam com o Windows]'
  Rep-Table @($sorted | Select-Object Nivel, Origem, Nome, Comando)
  $global:Stat['Itens de inicializacao'] = $rows.Count
}

function Scan-Programs {
  Sec 'PROGRAMAS INSTALADOS'
  Rep-Sec '8. PROGRAMAS INSTALADOS'
  $roots = @(
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
  )
  $raw = @(Get-ItemProperty -Path $roots | Where-Object { $_.DisplayName -and -not $_.SystemComponent })
  $ceRe  = '(?i)(cheat ?engine|extreme ?injector|xenos ?injector|kdmapper|winject)'
  $dbgRe = '(?i)(x64dbg|x32dbg|ollydbg|ida (pro|free)|ghidra|dnspy|reclass|process ?hacker|system ?informer)'
  $seen = @{}
  $rows = New-Object System.Collections.Generic.List[object]
  foreach ($a in $raw) {
    $nm = [string]$a.DisplayName
    $ver = [string]$a.DisplayVersion
    $key = ($nm + '|' + $ver).ToLower()
    if ($seen.ContainsKey($key)) { continue }
    $seen[$key] = 1
    $when = $null
    $d = [datetime]::MinValue
    $ids = [string]$a.InstallDate
    if ($ids -match '^\d{8}$') {
      if ([datetime]::TryParseExact($ids, 'yyyyMMdd', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$d)) { $when = $d }
    }
    $lvl = 1; $why = ''
    if ($nm -match $ceRe) { $lvl = 3; $why = 'Ferramenta de cheat/injecao' }
    elseif ($nm -match $Kw) { $lvl = 3; $why = 'Nome suspeito' }
    elseif ($nm -match $dbgRe) { $lvl = 2; $why = 'Debugger / analise de memoria' }
    $dtxt = '-'; if ($when) { $dtxt = $when.ToString('dd/MM/yyyy') }
    $rows.Add([pscustomobject]@{ Lvl = $lvl; Nivel = $LV[$lvl].Name; Programa = $nm; Versao = $ver; Fabricante = [string]$a.Publisher; Instalado_em = $dtxt; Motivo = $why; When = $when })
  }
  $sorted = @($rows | Sort-Object @{ e = 'Lvl'; Descending = $true }, Programa)
  $i = 0
  foreach ($r in $sorted) {
    if ($r.Lvl -lt 2) { continue }
    if ($i -ge 12) { break }
    Find-Out 'Programa' $r.Lvl ('Instalado: ' + $r.Programa + '  [' + $r.Motivo + ']'); $i++
  }
  $recent = @($sorted | Where-Object { $_.When -and $_.When -gt (Get-Date).AddDays(-7) } | Sort-Object When -Descending)
  $j = 0
  foreach ($r in $recent) {
    Add-Tl $r.When 'Instalado' ('Programa instalado: ' + $r.Programa) 1
    if ($j -lt 8) { Find-Out 'Programa' 1 ('Instalado nos ultimos 7 dias: ' + $r.Programa + '  (' + $r.Instalado_em + ')') }
    $j++
  }
  $flagged = @($sorted | Where-Object { $_.Lvl -ge 2 }).Count
  if ($flagged -eq 0) { Find-Out 'Programa' 0 ('Nenhum programa suspeito entre os ' + $rows.Count + ' instalados') }
  Rep ''; Rep '[Programas instalados (suspeitos primeiro)]'
  Rep-Table @($sorted | Select-Object Nivel, Programa, Versao, Fabricante, Instalado_em, Motivo)
  $global:Stat['Programas instalados'] = $rows.Count
}

function Walk-Files([string]$Root, [int]$MaxDepth, [int]$Seconds, [string]$SkipRe) {
  $sw = [Diagnostics.Stopwatch]::StartNew()
  $st = New-Object System.Collections.Generic.Stack[object]
  $st.Push(@($Root, 0))
  $global:WalkTimeout = $false
  while ($st.Count -gt 0) {
    if ($sw.Elapsed.TotalSeconds -gt $Seconds) { $global:WalkTimeout = $true; break }
    $it = $st.Pop()
    $dir = [string]$it[0]
    $dpt = [int]$it[1]
    try {
      foreach ($f in [IO.Directory]::EnumerateFiles($dir)) {
        $e = [IO.Path]::GetExtension($f).ToLower()
        if ($AllExt -contains $e) { $f }
      }
    } catch {}
    if ($dpt -lt $MaxDepth) {
      try {
        foreach ($sd in [IO.Directory]::EnumerateDirectories($dir)) {
          if ($sd -match $SkipRe) { continue }
          try { if (([IO.File]::GetAttributes($sd) -band [IO.FileAttributes]::ReparsePoint) -ne 0) { continue } } catch { continue }
          $st.Push(@($sd, ($dpt + 1)))
        }
      } catch {}
    }
  }
}

function Scan-Disks {
  Sec 'TODOS OS DISCOS'
  Rep-Sec '9. VARREDURA DE TODOS OS DISCOS'
  $skip = '(?i)\\(Windows|Program Files|Program Files \(x86\)|\$Recycle\.Bin|System Volume Information|node_modules|WinSxS|steamapps|\.git)$'
  $sysDrv = [string]$env:SystemDrive
  if (-not $sysDrv) { $sysDrv = 'C:' }
  $roots = New-Object System.Collections.Generic.List[object]
  $roots.Add(@{ P = ($sysDrv + '\Users');       D = 7; L = 'Usuarios (todas as contas)'; Ext = $false })
  $roots.Add(@{ P = ($sysDrv + '\ProgramData'); D = 4; L = 'ProgramData'; Ext = $false })
  $roots.Add(@{ P = ($sysDrv + '\');            D = 3; L = ($sysDrv + ' (raiz)'); Ext = $false })
  foreach ($ld in @(Get-CimInstance Win32_LogicalDisk | Where-Object { ($_.DriveType -eq 2 -or $_.DriveType -eq 3) -and $_.DeviceID -ne $sysDrv })) {
    $roots.Add(@{ P = ($ld.DeviceID + '\'); D = 8; L = ('Disco ' + $ld.DeviceID + ' ' + $ld.VolumeName); Ext = $true })
  }
  $recentExt = '.exe', '.bat', '.cmd', '.ps1', '.vbs', '.jar', '.msi', '.scr'
  $cut = (Get-Date).AddDays(-7)
  $seen = @{}
  $hits = New-Object System.Collections.Generic.List[object]
  $recent = New-Object System.Collections.Generic.List[object]
  $total = 0
  $timeouts = 0
  foreach ($r in $roots) {
    if (-not (Test-Path -LiteralPath $r.P)) { continue }
    Put ('  Varrendo ' + $r.L + '...') DarkGray; Nl
    $files = @(Walk-Files $r.P $r.D 60 $skip)
    if ($global:WalkTimeout) { $timeouts++; Find-Out 'Disco' 2 ('Tempo limite em ' + $r.L + ' - varredura parcial (' + $files.Count + ' arquivos ate aqui)') }
    foreach ($f in $files) {
      $key = $f.ToLower()
      if ($seen.ContainsKey($key)) { continue }
      $seen[$key] = 1
      $total++
      $leaf = [IO.Path]::GetFileName($f)
      $ext = [IO.Path]::GetExtension($f).ToLower()
      $lvl = -1; $why = ''
      if ($leaf -match $Kw) { $lvl = 3; $why = 'Nome de cheat/hack/loader' }
      elseif ($leaf -match '(?i)\.(pdf|jpe?g|png|gif|txt|docx?|xlsx?|mp3|mp4)\.(exe|scr|bat|cmd|vbs|ps1|com)$') { $lvl = 3; $why = 'Dupla extensao (arquivo disfarcado)' }
      elseif ($ExecExt -contains $ext) {
        $dn = [IO.Path]::GetDirectoryName($f)
        if ($r.Ext -and $dn -and $dn.Length -le 3) { $lvl = 2; $why = 'Executavel solto na raiz do disco' }
        elseif ($f -match '(?i)\\Users\\Public\\') { $lvl = 2; $why = 'Executavel em Users\Public' }
      }
      $lw = [IO.File]::GetLastWriteTime($f)
      if ($lvl -ge 0 -and $hits.Count -lt 400) {
        $kb = 0; try { $kb = [math]::Round((New-Object IO.FileInfo $f).Length / 1KB) } catch {}
        $hits.Add([pscustomobject]@{ Lvl = $lvl; Nivel = $LV[$lvl].Name; Arquivo = $f; Modificado = (Fmt-Date $lw); Tamanho_KB = $kb; Motivo = $why; When = $lw })
      }
      if (($recentExt -contains $ext) -and ($lw -gt $cut) -and ($f -notmatch '(?i)\\(Windows|Program Files)') -and $recent.Count -lt 600) {
        $recent.Add([pscustomobject]@{ Modificado = (Fmt-Date $lw); Arquivo = $f; When = $lw })
      }
    }
  }
  $wo = $sysDrv + '\Windows.old'
  if (Test-Path -LiteralPath $wo) { Find-Out 'Disco' 2 ('Pasta Windows.old existe (criada em ' + (Fmt-Date (Get-Item -LiteralPath $wo -Force).CreationTime) + ') - Windows foi reinstalado/atualizado') }
  $sorted = @($hits | Sort-Object @{ e = 'Lvl'; Descending = $true }, @{ e = 'When'; Descending = $true })
  $i = 0
  foreach ($h in $sorted) {
    if ($i -ge 15) { break }
    Find-Out 'Disco' $h.Lvl ($h.Motivo + ': ' + $h.Arquivo + '  (' + $h.Modificado + ')'); $i++
  }
  if ($sorted.Count -gt 15) { Find-Out 'Disco' 1 ('+' + ($sorted.Count - 15) + ' achados nos discos no relatorio') }
  if ($sorted.Count -eq 0) { Find-Out 'Disco' 0 'Nenhum arquivo com nome de cheat/disfarce nos discos' }
  Find-Out 'Disco' 1 ($total.ToString() + ' executaveis/scripts/compactados analisados em ' + $roots.Count + ' locais')
  $rec = @($recent | Sort-Object When -Descending | Select-Object -First 40)
  $k = 0
  foreach ($x in $rec) { if ($k -lt 20) { Add-Tl $x.When 'Arquivo novo' ('Executavel/script criado: ' + $x.Arquivo) 1 }; $k++ }
  Rep ''; Rep '[Arquivos suspeitos em todos os discos]'
  Rep-Table @($sorted | Select-Object Nivel, Arquivo, Modificado, Tamanho_KB, Motivo)
  Rep ''; Rep '[Executaveis/scripts novos (ultimos 7 dias, fora de Windows e Program Files) - 40 mais recentes]'
  Rep-Table @($rec | Select-Object Modificado, Arquivo)
  $global:Stat['Arquivos varridos (todos os discos)'] = $total
  $global:Stat['Achados nos discos'] = $sorted.Count
}

function Get-BrowserText([string]$P) {
  $b = $null
  try {
    $fs = New-Object IO.FileStream($P, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
    try {
      if ($fs.Length -le 300MB) {
        $len = [int]$fs.Length
        $b = New-Object byte[] $len
        $off = 0
        while ($off -lt $len) { $n = $fs.Read($b, $off, $len - $off); if ($n -le 0) { break }; $off += $n }
      }
    } finally { $fs.Dispose() }
  } catch { $b = $null }
  if ($null -eq $b -and $IsAdmin) {
    $tmp = Join-Path $env:TEMP ('brl_' + [guid]::NewGuid().ToString('N') + '.tmp')
    try { & esentutl.exe /y $P /vss /d $tmp /o | Out-Null } catch {}
    if (Test-Path -LiteralPath $tmp) {
      try { $b = [IO.File]::ReadAllBytes($tmp) } catch { $b = $null }
      Remove-Item -LiteralPath $tmp -Force
    }
  }
  if ($null -eq $b) { return $null }
  return [Text.Encoding]::GetEncoding(28591).GetString($b)
}

function Scan-Browsers {
  Sec 'NAVEGADORES / DOWNLOADS'
  Rep-Sec '10. DOWNLOADS NOS NAVEGADORES'
  Put '  Lendo historico dos navegadores...' DarkGray; Nl
  $exts = 'exe|dll|sys|bat|cmd|ps1|vbs|jar|msi|scr|zip|rar|7z'
  $winRe = '(?i)[A-Za-z]:\\[^\x00-\x1F"<>|?*]{2,240}?\.(?:' + $exts + ')'
  $ffRe  = '(?i)file:///[A-Za-z]:/[^\x00-\x1F"<>|?*\s]{2,240}?\.(?:' + $exts + ')'
  $urlRe = '(?i)https?://[^\x00-\x20"<>\\]{6,200}'
  $badUrl = '(?i)(cheat|hack|inject|crack|bypass|spoof|aimbot|wallhack|hwid|executor|exploit|kdmapper|skript\.gg|eulen|redengine|susano)'
  $files = New-Object System.Collections.Generic.List[object]
  $chromium = @(
    @{ N = 'Chrome';   P = ($env:LOCALAPPDATA + '\Google\Chrome\User Data') },
    @{ N = 'Edge';     P = ($env:LOCALAPPDATA + '\Microsoft\Edge\User Data') },
    @{ N = 'Brave';    P = ($env:LOCALAPPDATA + '\BraveSoftware\Brave-Browser\User Data') },
    @{ N = 'Opera';    P = ($env:APPDATA + '\Opera Software\Opera Stable') },
    @{ N = 'Opera GX'; P = ($env:APPDATA + '\Opera Software\Opera GX Stable') }
  )
  foreach ($c in $chromium) {
    if (-not (Test-Path -LiteralPath $c.P)) { continue }
    $cand = @($c.P)
    foreach ($d in @(Get-ChildItem -LiteralPath $c.P -Directory | Where-Object { $_.Name -match '^(Default|Profile \d+)$' })) { $cand += $d.FullName }
    foreach ($cp in $cand) {
      $h = Join-Path $cp 'History'
      if (Test-Path -LiteralPath $h) {
        $label = $c.N; if ($cp -ne $c.P) { $label = $c.N + ' (' + (Split-Path -Leaf $cp) + ')' }
        $files.Add(@{ N = $label; F = $h; FF = $false })
      }
    }
  }
  foreach ($d in @(Get-ChildItem -LiteralPath ($env:APPDATA + '\Mozilla\Firefox\Profiles') -Directory)) {
    $pl = Join-Path $d.FullName 'places.sqlite'
    if (Test-Path -LiteralPath $pl) { $files.Add(@{ N = 'Firefox'; F = $pl; FF = $true }) }
  }
  if ($files.Count -eq 0) { Find-Out 'Navegador' 1 'Nenhum historico de navegador encontrado' }

  $rows = New-Object System.Collections.Generic.List[object]
  $urls = New-Object System.Collections.Generic.List[object]
  $seen = @{}
  $seenUrl = @{}
  $readOk = 0
  foreach ($f in $files) {
    $txt = Get-BrowserText $f.F
    if ($null -eq $txt) { Find-Out 'Navegador' 2 ('Nao consegui ler o historico de ' + $f.N + ' (navegador aberto?) - feche o navegador ou rode como ADMIN'); continue }
    $readOk++
    $cnt = 0
    $re = $winRe; if ($f.FF) { $re = $ffRe }
    foreach ($m in [regex]::Matches($txt, $re)) {
      if ($cnt -ge 3000) { break }
      $p = [string]$m.Value
      if ($f.FF) { $p = $p.Substring(8).Replace('/', '\'); try { $p = [uri]::UnescapeDataString($p) } catch {} }
      $key = $p.ToLower()
      if ($seen.ContainsKey($key)) { continue }
      $seen[$key] = 1
      $cnt++
      $leaf = [IO.Path]::GetFileName($p)
      $exists = Test-Path -LiteralPath $p
      $isKw = ($leaf -match $Kw)
      $lvl = 1
      if ($isKw -and -not $exists) { $lvl = 4 } elseif ($isKw) { $lvl = 3 } elseif (-not $exists) { $lvl = 2 }
      $sit = 'Existe'; if (-not $exists) { $sit = 'NAO EXISTE MAIS (apagado)' }
      $rows.Add([pscustomobject]@{ Lvl = $lvl; Nivel = $LV[$lvl].Name; Navegador = $f.N; Arquivo = $p; Situacao = $sit })
    }
    if (-not $f.FF) {
      $uc = 0
      foreach ($m in [regex]::Matches($txt, $urlRe)) {
        if ($uc -ge 15) { break }
        $u = [string]$m.Value
        if ($u -match $badUrl -and -not $seenUrl.ContainsKey($u.ToLower())) {
          $seenUrl[$u.ToLower()] = 1
          $urls.Add([pscustomobject]@{ Navegador = $f.N; Endereco = $u }); $uc++
        }
      }
    }
    Find-Out 'Navegador' 1 ($f.N + ': historico lido (' + $cnt + ' executaveis/compactados encontrados)')
  }
  $sorted = @($rows | Sort-Object @{ e = 'Lvl'; Descending = $true }, Arquivo)
  $i = 0
  foreach ($r in $sorted) {
    if ($r.Lvl -lt 2) { continue }
    if ($i -ge 15) { break }
    $sfx = ''; if ($r.Lvl -eq 2 -or $r.Lvl -eq 4) { $sfx = '  [apagado]' }
    Find-Out 'Navegador' $r.Lvl ('Baixado (' + $r.Navegador + '): ' + $r.Arquivo + $sfx); $i++
  }
  $fl = @($sorted | Where-Object { $_.Lvl -ge 2 }).Count
  if ($fl -gt 15) { Find-Out 'Navegador' 1 ('+' + ($fl - 15) + ' downloads para conferir no relatorio') }
  $j = 0
  foreach ($u in $urls) { if ($j -ge 10) { break }; Find-Out 'Navegador' 2 ('Site suspeito no historico (' + $u.Navegador + '): ' + $u.Endereco); $j++ }
  if ($readOk -gt 0 -and $fl -eq 0 -and $urls.Count -eq 0) { Find-Out 'Navegador' 0 'Nada suspeito no historico de downloads' }
  Rep ''; Rep '[Downloads encontrados no historico dos navegadores (inclui registros ja apagados do historico)]'
  Rep-Table @($sorted | Select-Object -First 150 -Property Nivel, Navegador, Arquivo, Situacao)
  Rep ''; Rep '[Enderecos suspeitos no historico]'
  Rep-Table @($urls)
  $global:Stat['Downloads no historico dos navegadores'] = $rows.Count
  $global:Stat['Baixados e apagados'] = @($rows | Where-Object { $_.Situacao -like 'NAO*' }).Count
}

function Scan-Timeline {
  Sec 'LINHA DO TEMPO'
  Rep-Sec 'LINHA DO TEMPO - tudo em ordem cronologica'
  $all = @($global:Tl | Sort-Object Quando -Descending)
  if ($all.Count -eq 0) { Rep '  Nada encontrado.'; return }
  # sequencias: suspeito executado e algo suspeito apagado logo depois
  $ex = @($all | Where-Object { $_.Tipo -eq 'Executado' -and $_.Lvl -ge 3 } | Sort-Object Quando)
  $ap = @($all | Where-Object { $_.Tipo -eq 'Apagado' -and $_.Lvl -ge 3 } | Sort-Object Quando)
  $n = 0
  foreach ($e in $ex) {
    if ($n -ge 5) { break }
    foreach ($a in $ap) {
      $m = ($a.Quando - $e.Quando).TotalMinutes
      if ($m -ge 0 -and $m -le 60) {
        Find-Out 'Sequencia' 4 ('Suspeito executado em ' + (Fmt-Date $e.Quando) + ' (' + $e.Evento + ') e algo apagado ' + [math]::Round($m) + ' min depois (' + $a.Evento + ')')
        $n++; break
      }
    }
  }
  Find-Out 'Tempo' 1 ($all.Count + ' eventos na linha do tempo (mostrando os 150 mais recentes no relatorio)')
  Rep ''; Rep '[Eventos mais recentes primeiro]'
  Rep-Table @($all | Select-Object -First 150 -Property @{ n = 'Nivel'; e = { $LV[$_.Lvl].Name } }, @{ n = 'Data'; e = { Fmt-Date $_.Quando } }, Tipo, Evento)
  $global:Stat['Eventos na linha do tempo'] = $all.Count
}

function Scan-All {
  Scan-System
  Scan-Startup
  Scan-Programs
  Scan-Executed
  Scan-Deleted
  Scan-Usb
  Scan-Downloads
  Scan-Browsers
  Scan-FiveM
  Scan-Processes
  Scan-Services
  Scan-Network
  Scan-Security
  Scan-Disks
  Scan-Timeline
}

# ================================================================
#  NAVEGACAO
# ================================================================
function Run-Scan([string]$Title, [scriptblock]$Body, [switch]$Save) {
  Banner $Title
  $global:Cnt = @(0, 0, 0, 0, 0)
  $global:Stat = [ordered]@{}
  $global:RepLines.Clear()
  $global:Sections.Clear(); $global:CurSec = $null; $global:Hot.Clear(); $global:Tl.Clear()
  Rep-Header
  & $Body
  Show-Summary
  if ($Save) { Save-Report }
  Nl
  Put '  Pressione ENTER para voltar ao menu...' DarkGray
  [void](Read-Host)
}

function Login {
  while ($true) {
    Banner 'LOGIN'
    Put '   Usuario : ' Cyan
    $u = Read-Host
    Put '   Senha   : ' Cyan
    $sec = Read-Host -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
    $p = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    if ($u -ieq 'brilhante' -and $p -ceq '22') { return }
    Nl
    Put '  ' ; Put ($TRI + ' [ERRO] Usuario ou senha incorretos.') Red; Nl
    Start-Sleep -Milliseconds 1500
  }
}

function Show-Menu {
  Banner 'MENU PRINCIPAL'
  Put '  PC: ' DarkGray; Put $env:COMPUTERNAME White
  Put '    Usuario: ' DarkGray; Put $env:USERNAME White
  Put '    '
  if ($IsAdmin) { Put ' ADMIN ' Black Green } else { Put ' SEM ADMIN ' White Red }
  Nl; Nl
  $left = @(
    @('1', 'Scanner completo (PC inteiro)'),
    @('2', 'Arquivos suspeitos / baixados'),
    @('3', 'Programas executados'),
    @('4', 'Arquivos apagados'),
    @('5', 'Pen drives / USB'),
    @('R', 'Relatorio rapido (principais)'),
    @('S', 'Sistema / inicializacao / programas'),
    @('D', 'Todos os discos (arquivos)')
  )
  $right = @(
    @('6', 'Processos'),
    @('7', 'Servicos, tarefas e bypass'),
    @('8', 'Rede'),
    @('9', 'Seguranca / TPM / Drivers'),
    @('F', 'FiveM / GTA V (DLLs, logs, plugins)'),
    @('B', 'Navegadores (downloads)'),
    @('', ''),
    @('', '')
  )
  for ($i = 0; $i -lt 8; $i++) {
    Put '   '
    Put (' ' + $left[$i][0] + ' ') Black Cyan
    Put ('  ' + $left[$i][1].PadRight(38)) White
    if ($right[$i][0]) {
      Put (' ' + $right[$i][0] + ' ') Black Cyan
      Put ('  ' + $right[$i][1]) White
    }
    Nl; Nl
  }
  Put '   '; Put ' 0 ' White Red; Put '  Sair' Gray; Nl
  Nl
  Put '  Escolha uma opcao ' Cyan; Put ($ARW + ' ') Yellow
}

# ---------------------------------------------------------------- inicio
$ServerUrl = '__SERVER_URL__'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Send-Result([string]$Code) {
  $v = Get-BanVerdict
  $hot = @($global:Hot | Sort-Object { $_.L } -Descending | Select-Object -First 200 | ForEach-Object { @{ nivel = $LV[$_.L].Name; secao = $_.Sec; tag = $_.Tag; msg = $_.Msg } })
  $tl = @($global:Tl | Sort-Object Quando -Descending | Select-Object -First 300 | ForEach-Object { @{ quando = $_.Quando.ToString('yyyy-MM-dd HH:mm:ss'); tipo = $_.Tipo; evento = $_.Evento } })
  $stat = @{}; foreach ($k in $global:Stat.Keys) { $stat[[string]$k] = [string]$global:Stat[$k] }
  $obj = @{ nivel = $v.Nivel; motivo = $v.Texto; pc = $env:COMPUTERNAME
            contagem = @{ ok = $global:Cnt[0]; info = $global:Cnt[1]; atencao = $global:Cnt[2]; suspeito = $global:Cnt[3]; critico = $global:Cnt[4] }
            achados = $hot; linha_do_tempo = $tl; stats = $stat }
  $json = $obj | ConvertTo-Json -Depth 5
  Invoke-RestMethod -Uri "$ServerUrl/api/scan/$Code" -Method Post -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($json)) -ErrorAction Stop | Out-Null
}

function Player-Mode([string]$Code) {
  Banner 'SCANNING PROCESSES...'
  try { Invoke-RestMethod -Uri "$ServerUrl/api/codes/$Code" -Method Post -ErrorAction Stop | Out-Null } catch {}
  $global:Cnt = @(0, 0, 0, 0, 0); $global:Stat = [ordered]@{}; $global:RepLines.Clear()
  $global:Sections.Clear(); $global:CurSec = $null; $global:Hot.Clear(); $global:Tl.Clear()
  Rep-Header
  Scan-All
  Show-Summary
  Nl; Put '  Enviando resultado para o servidor...' Yellow; Nl
  try { Send-Result $Code; Put '  Resultado enviado. Pode fechar esta janela.' Green }
  catch { Put ('  Falha ao enviar: ' + $_.Exception.Message) Red }
  Nl; Start-Sleep -Seconds 5; exit
}

Banner 'CODIGO'
Put '   Este scanner analisa o seu PC (programas executados, arquivos, downloads, FiveM, rede)' Gray; Nl
Put '   e envia SOMENTE o resultado para o servidor que gerou o codigo.' Gray; Nl; Nl
Put '   Digite o codigo de 6 digitos (ou ENTER para modo administrador): ' Cyan
$code = ([string](Read-Host)).Trim()
if ($code -match '^\d{6}$') {
  $st = $null
  try { $st = Invoke-RestMethod -Uri "$ServerUrl/api/codes/$code" -ErrorAction Stop } catch {}
  if (-not $st -or $st.status -eq 'concluido') { Put '  Codigo invalido ou ja utilizado.' Red; Nl; Start-Sleep 4; exit }
  Put '   Ao continuar voce autoriza a varredura e o envio do resultado. Continuar? [S/N] ' Yellow
  if (([string](Read-Host)) -notmatch '^[sSyY]') { exit }
  Player-Mode $code
}
Login

Banner 'LOGIN AUTORIZADO'
Put '   Bem-vindo, ' Gray; Put 'Brilhante' Yellow; Nl; Nl
Put '   Carregando  ' DarkGray
for ($i = 0; $i -lt 40; $i++) { Put $SQ Cyan; Start-Sleep -Milliseconds 20 }
Nl
Start-Sleep -Milliseconds 300

if (-not $IsAdmin) {
  Banner 'ATENCAO'
  Find-Out 'Sistema' 3 'Voce NAO esta como Administrador. Prefetch, BAM, logs e journal ficam incompletos.'
  Nl
  Put '  Reabrir como Administrador agora? [S/N] ' Yellow
  $ans = Read-Host
  if ($ans -match '^[sSyY]') {
    try {
      Start-Process cmd.exe -ArgumentList ('/c ""' + $env:SELF + '""') -Verb RunAs -ErrorAction Stop
      exit
    } catch {
      Put '  Elevacao cancelada. Continuando sem admin...' Red; Nl
      Start-Sleep -Milliseconds 1500
    }
  }
}

while ($true) {
  Show-Menu
  $op = ([string](Read-Host)).Trim().ToUpper()
  switch ($op) {
    '1' { Run-Scan 'SCANNER COMPLETO - PC INTEIRO' { Scan-All } -Save }
    '2' { Run-Scan 'ARQUIVOS SUSPEITOS' { Scan-Downloads } }
    '3' { Run-Scan 'PROGRAMAS EXECUTADOS' { Scan-Executed } }
    '4' { Run-Scan 'ARQUIVOS APAGADOS' { Scan-Deleted } }
    '5' { Run-Scan 'PEN DRIVES / USB' { Scan-Usb } }
    '6' { Run-Scan 'PROCESSOS' { Scan-Processes } }
    '7' { Run-Scan 'SERVICOS E BYPASS' { Scan-Services } }
    '8' { Run-Scan 'REDE' { Scan-Network } }
    '9' { Run-Scan 'SEGURANCA / DRIVERS' { Scan-Security } }
    'F' { Run-Scan 'FIVEM / GTA V' { Scan-FiveM } }
    'R' { Run-Scan 'RELATORIO RAPIDO' { Scan-Executed; Scan-Deleted; Scan-Usb; Scan-Downloads; Scan-FiveM; Scan-Timeline } -Save }
    'S' { Run-Scan 'SISTEMA / INICIALIZACAO / PROGRAMAS' { Scan-System; Scan-Startup; Scan-Programs } }
    'D' { Run-Scan 'TODOS OS DISCOS' { Scan-Disks } }
    'B' { Run-Scan 'NAVEGADORES / DOWNLOADS' { Scan-Browsers } }
    '0' { Clear-Host; exit }
  }
}
