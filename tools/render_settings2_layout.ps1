# Purpose: render a 2560x1440 Settings 2.0 chrome PNG from the approved mockup numbers
# (cards_status.html) so the 58px rows, 1px dividers, 268 sidebar and 292 preview can be
# compared next to the HTML mockups. Not a game screenshot.
# Author: Moragar. Last modified: 2026-11-26.
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $root "test_scratch"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$out = Join-Path $outDir "settings2_layout_2560x1440.png"

$W = 2560; $H = 1440
$bmp = New-Object System.Drawing.Bitmap $W, $H
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::None
$g.Clear([System.Drawing.Color]::FromArgb(255, 7, 11, 16))

# Scale 1920x1080 mockup space onto 2560x1440 (4/3).
$s = 2560.0 / 1920.0
function Px([int]$n) { return [int][Math]::Round($n * 1.3333333) }

$acc = [System.Drawing.Color]::FromArgb(255, 63, 208, 224)
$txt = [System.Drawing.Color]::FromArgb(255, 242, 247, 249)
$mut = [System.Drawing.Color]::FromArgb(255, 142, 156, 164)
$bg  = [System.Drawing.Color]::FromArgb(255, 11, 18, 24)
$win = [System.Drawing.Color]::FromArgb(210, 12, 20, 28)
$box = [System.Drawing.Color]::FromArgb(200, 17, 26, 34)
$div = [System.Drawing.Color]::FromArgb(20, 242, 247, 249)   # txt 8%
$sh  = [System.Drawing.Color]::FromArgb(71, 63, 208, 224)    # acc 28%
$sel = [System.Drawing.Color]::FromArgb(26, 63, 208, 224)    # acc 10%
$edge = [System.Drawing.Color]::FromArgb(71, 63, 208, 224)   # acc 28%
$boxE = [System.Drawing.Color]::FromArgb(46, 63, 208, 224)   # acc 18%

function Fill([System.Drawing.Color]$c, [int]$x, [int]$y, [int]$w, [int]$h) {
  $br = New-Object System.Drawing.SolidBrush $c
  $script:g.FillRectangle($br, $x, $y, $w, $h)
  $br.Dispose()
}
function Stroke1([System.Drawing.Color]$c, [int]$x, [int]$y, [int]$w, [int]$h) {
  Fill $c $x $y $w 1
  Fill $c $x ($y + $h - 1) $w 1
  if ($h -gt 2) {
    Fill $c $x ($y + 1) 1 ($h - 2)
    Fill $c ($x + $w - 1) ($y + 1) 1 ($h - 2)
  }
}

# Window: left 36 top 32, 1848x1020 on 1920x1080 -> scaled
$wx = Px 36; $wy = Px 32; $ww = Px 1848; $wh = Px 1020
Fill $win $wx $wy $ww $wh
Stroke1 $edge $wx $wy $ww $wh

$head = Px 62; $tabs = Px 46; $side = Px 268; $prev = Px 292; $foot = Px 54; $row = Px 58
Fill ([System.Drawing.Color]::FromArgb(26, 242, 247, 249)) $wx ($wy + $head - 1) $ww 1
Fill ([System.Drawing.Color]::FromArgb(26, 242, 247, 249)) $wx ($wy + $head + $tabs - 1) $ww 1
Fill $div ($wx + $side - 1) ($wy + $head + $tabs) 1 ($wh - $head - $tabs - $foot)
Fill $div ($wx + $ww - $prev) ($wy + $head + $tabs) 1 ($wh - $head - $tabs - $foot)
Fill ([System.Drawing.Color]::FromArgb(26, 242, 247, 249)) $wx ($wy + $wh - $foot) $ww 1

$fontT = New-Object System.Drawing.Font("Segoe UI", [single]18)
$fontR = New-Object System.Drawing.Font("Segoe UI", [single]12)
$fontH = New-Object System.Drawing.Font("Segoe UI", [single]11)
$fontS = New-Object System.Drawing.Font("Segoe UI", [single]10)
$brTxt = New-Object System.Drawing.SolidBrush $txt
$brAcc = New-Object System.Drawing.SolidBrush $acc
$brMut = New-Object System.Drawing.SolidBrush $mut
$g.DrawString("HORIZON UI  SETTINGS", $fontT, $brTxt, ($wx + (Px 28)), ($wy + (Px 16)))
$g.DrawString("CARDS    APPEARANCE    SCANNER    COMMS    SYSTEM", $fontR, $brAcc, ($wx + (Px 56)), ($wy + $head + (Px 12)))

# Sidebar
$sy = $wy + $head + $tabs + (Px 8)
$items = @(
  @("GENERAL", "Compact strips size · HUD scale · Margin"),
  @("STATUS", "Vitals · Jetpack · Afflictions · Hazard Status"),
  @("COMBAT", "Equipment · Enemy Health · Stealth · Scope"),
  @("NAVIGATION", "Compass · Quest Tracker · Planet")
)
$ih = Px 52
for ($i = 0; $i -lt $items.Count; $i++) {
  $iy = $sy + (Px 26) + $i * $ih
  if ($i -eq 1) {
    Fill $sel ($wx) $iy $side $ih
    Fill $acc $wx $iy 3 $ih
    $g.DrawString($items[$i][0], $fontR, $brAcc, ($wx + (Px 20)), ($iy + (Px 11)))
  } else {
    $g.DrawString($items[$i][0], $fontR, $brTxt, ($wx + (Px 20)), ($iy + (Px 11)))
  }
  $g.DrawString($items[$i][1], $fontH, $brMut, ($wx + (Px 20)), ($iy + (Px 28)))
  Fill ([System.Drawing.Color]::FromArgb(10, 242, 247, 249)) ($wx + (Px 20)) ($iy + $ih - 1) ($side - (Px 20)) 1
}

# Rows in a box
$lx = $wx + $side + (Px 28)
$ly = $wy + $head + $tabs + (Px 64)
$lw = $ww - $side - $prev - (Px 46)
$g.DrawString("CARDS  >  STATUS", $fontS, $brMut, $lx, ($wy + $head + $tabs + (Px 14)))
$g.DrawString("STATUS", $fontT, $brTxt, $lx, ($wy + $head + $tabs + (Px 30)))
$g.DrawString("VITALS", $fontS, $brAcc, $lx, ($ly - (Px 24)))
Fill $sh ($lx + (Px 70)) ($ly - (Px 16)) ($lw - (Px 70)) 1

$labels = @(
  @("VITALS CARD", "Health, oxygen, and boost. On/Off is independent of Show when."),
  @("SHOW WHEN", "Card-specific. Default Always."),
  @("SIZE", "Follow HUD uses HUD Scale."),
  @("VITALS LAYOUT", "Vertical = health above oxygen. Horizontal = one row."),
  @("HEALTH AND O2 BARS", "Compact uses the same merged boost / health / oxygen card."),
  @("CENTER VITALS WHEN EQUIPMENT HIDDEN", "Slides vitals to center when the Equipment card is hidden.")
)
Fill $box $lx $ly $lw ($row * $labels.Count)
Stroke1 $boxE $lx $ly $lw ($row * $labels.Count)
for ($i = 0; $i -lt $labels.Count; $i++) {
  $ry = $ly + $i * $row
  if ($i -eq 0) { Fill $sel $lx $ry $lw $row }
  $g.DrawString($labels[$i][0], $fontR, $brTxt, ($lx + (Px 16)), ($ry + (Px 9)))
  $g.DrawString($labels[$i][1], $fontH, $brMut, ($lx + (Px 16)), ($ry + (Px 28)))
  if ($i -lt $labels.Count - 1) { Fill $div $lx ($ry + $row - 1) $lw 1 }
}

# Preview column
$px = $wx + $ww - $prev + (Px 18)
$py = $wy + $head + $tabs + (Px 16)
$g.DrawString("LIVE PREVIEW", $fontS, $brAcc, $px, $py)
$pvcH = Px 188
Fill $box $px ($py + (Px 22)) ($prev - (Px 36)) $pvcH
Stroke1 ([System.Drawing.Color]::FromArgb(36, 242, 247, 249)) $px ($py + (Px 22)) ($prev - (Px 36)) $pvcH
$g.DrawString("SETTING DETAILS", $fontS, $brAcc, $px, ($py + (Px 22) + $pvcH + (Px 18)))

$g.DrawString("KEYBOARD   UP/DN SELECT   L/R CHANGE   ENTER OK   ESC CANCEL", $fontS, $brMut, ($wx + (Px 24)), ($wy + $wh - $foot + (Px 18)))

$cap = "Settings 2.0 layout chrome at 2560x1440 from mockup CSS: win 1848x1020, side 268, prev 292, row 58, divider 1px txt 8%, box acc 18%."
$g.DrawString($cap, $fontH, $brMut, 24, 8)

$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Host $out
