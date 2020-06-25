param([string] $path)

$content = (gc $path)
set-content -Encoding UTF8 -Path $path -Value $content
