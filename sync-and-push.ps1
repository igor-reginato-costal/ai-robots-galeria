$ErrorActionPreference = 'Stop'

$SourcePath = 'C:\Users\igore\Meu Drive (igor.reginato@costal.com.br)\AI ROBOTS\AI_ROBOTS_Galeria.html'
$SourceDirectory = Split-Path -Parent $SourcePath
$RepositoryPath = $PSScriptRoot
$PublishedPath = Join-Path $RepositoryPath 'index.html'
$ExpectedRemote = 'https://github.com/igor-reginato-costal/ai-robots-galeria.git'

function Invoke-Git {
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $Arguments
    )

    & git -C $RepositoryPath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Git falhou: git $($Arguments -join ' ')"
    }
}

function Get-Sha256 {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        try {
            return ([System.BitConverter]::ToString($sha256.ComputeHash($stream))).Replace('-', '')
        } finally {
            $sha256.Dispose()
        }
    } finally {
        $stream.Dispose()
    }
}

try {
    Write-Host '=== Publicacao da AI Robot Galeria ===' -ForegroundColor Cyan

    if (-not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
        throw "Arquivo-fonte nao encontrado: $SourcePath"
    }

    if (-not (Test-Path -LiteralPath (Join-Path $RepositoryPath '.git') -PathType Container)) {
        throw "Repositorio Git nao encontrado em: $RepositoryPath"
    }

    $currentBranch = (& git -C $RepositoryPath branch --show-current).Trim()
    if ($LASTEXITCODE -ne 0 -or $currentBranch -ne 'main') {
        throw "A branch ativa deve ser main. Branch atual: $currentBranch"
    }

    $originUrl = (& git -C $RepositoryPath remote get-url origin).Trim()
    if ($LASTEXITCODE -ne 0 -or $originUrl -ne $ExpectedRemote) {
        throw "Origin inesperado: $originUrl"
    }

    $sourceHtml = [System.IO.File]::ReadAllText($SourcePath)
    $publishedHtml = $sourceHtml
    $utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
    $publishedBytes = $utf8WithoutBom.GetBytes($publishedHtml)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $expectedPublishedHash = ([System.BitConverter]::ToString($sha256.ComputeHash($publishedBytes))).Replace('-', '')
    } finally {
        $sha256.Dispose()
    }

    $destinationHash = if (Test-Path -LiteralPath $PublishedPath -PathType Leaf) {
        Get-Sha256 -Path $PublishedPath
    } else {
        $null
    }

    if ($expectedPublishedHash -ne $destinationHash) {
        [System.IO.File]::WriteAllText($PublishedPath, $publishedHtml, $utf8WithoutBom)
        $copiedHash = Get-Sha256 -Path $PublishedPath
        if ($copiedHash -ne $expectedPublishedHash) {
            throw 'A verificacao SHA-256 falhou depois da copia para index.html.'
        }
        Write-Host 'ALTERACAO: index.html foi sincronizado, adaptado para o Netlify e validado por SHA-256.' -ForegroundColor Yellow
    } else {
        Write-Host 'ALTERACAO: nenhuma; index.html ja corresponde a versao web do arquivo-fonte.' -ForegroundColor Green
    }

    $indexSizeBytes = (Get-Item -LiteralPath $PublishedPath).Length
    $indexSizeMiB = $indexSizeBytes / 1MB
    if ($indexSizeBytes -gt 95MB) {
        Write-Warning ("index.html tem {0:N2} MiB e esta acima de 95 MiB." -f $indexSizeMiB)
    }
    if ($indexSizeBytes -ge 100MB) {
        throw ("PUBLICACAO INTERROMPIDA: index.html tem {0:N2} MiB e excedeu o limite de 100 MiB suportado pelo GitHub." -f $indexSizeMiB)
    }

    $htmlContent = [System.IO.File]::ReadAllText($PublishedPath)
    $assetMatches = [regex]::Matches($htmlContent, '"file"\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"')
    $assetNames = @(
        $assetMatches |
            ForEach-Object { ConvertFrom-Json ('"' + $_.Groups[1].Value + '"') } |
            Sort-Object -Unique
    )

    $assetsCopied = 0
    $publishedAssetNames = @()
    $sourceRoot = [System.IO.Path]::GetFullPath($SourceDirectory + [System.IO.Path]::DirectorySeparatorChar)
    $repositoryRoot = [System.IO.Path]::GetFullPath($RepositoryPath + [System.IO.Path]::DirectorySeparatorChar)
    foreach ($assetName in $assetNames) {
        $publishedAssetName = $assetName.Replace('\\', '/')
        $publishedAssetNames += $publishedAssetName
        $relativeAssetPath = $publishedAssetName.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
        $sourceAsset = [System.IO.Path]::GetFullPath((Join-Path $SourceDirectory $relativeAssetPath))
        $publishedAsset = [System.IO.Path]::GetFullPath((Join-Path $RepositoryPath $relativeAssetPath))
        if (-not $sourceAsset.StartsWith($sourceRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Referencia de asset fora da pasta-fonte permitida: $assetName"
        }
        if (-not $publishedAsset.StartsWith($repositoryRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Destino de asset fora do repositorio permitido: $assetName"
        }
        if (-not (Test-Path -LiteralPath $sourceAsset -PathType Leaf)) {
            throw "Asset referenciado pelo HTML nao encontrado: $sourceAsset"
        }

        $assetSourceHash = Get-Sha256 -Path $sourceAsset
        $assetDestinationHash = if (Test-Path -LiteralPath $publishedAsset -PathType Leaf) {
            Get-Sha256 -Path $publishedAsset
        } else {
            $null
        }

        if ($assetSourceHash -ne $assetDestinationHash) {
            $publishedAssetDirectory = Split-Path -Parent $publishedAsset
            if (-not (Test-Path -LiteralPath $publishedAssetDirectory -PathType Container)) {
                New-Item -ItemType Directory -Path $publishedAssetDirectory -Force | Out-Null
            }
            Copy-Item -LiteralPath $sourceAsset -Destination $publishedAsset -Force
            if ((Get-Sha256 -Path $publishedAsset) -ne $assetSourceHash) {
                throw "A verificacao SHA-256 falhou para o asset: $assetName"
            }
            $assetsCopied++
        }
    }

    Write-Host "ASSETS: $($assetNames.Count) referenciados; $assetsCopied sincronizados." -ForegroundColor Green
    $trackedPngs = @(& git -C $RepositoryPath -c core.quotepath=false ls-files -- '*.png')
    if ($LASTEXITCODE -ne 0) {
        throw 'Nao foi possivel listar os PNGs rastreados no repositorio.'
    }
    $retiredAssetNames = @($trackedPngs | Where-Object { $publishedAssetNames -notcontains $_ })
    foreach ($retiredAssetName in $retiredAssetNames) {
        $retiredAsset = [System.IO.Path]::GetFullPath((Join-Path $RepositoryPath $retiredAssetName))
        if (-not $retiredAsset.StartsWith($repositoryRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Asset antigo fora do repositorio permitido: $retiredAssetName"
        }
        if (Test-Path -LiteralPath $retiredAsset -PathType Leaf) {
            Remove-Item -LiteralPath $retiredAsset
        }
    }
    if ($retiredAssetNames.Count -gt 0) {
        Write-Host "LIMPEZA: $($retiredAssetNames.Count) PNGs antigos removidos do site (recuperaveis pelo Git)." -ForegroundColor Yellow
    }
    $siteFiles = @('index.html', 'sync-and-push.ps1') + $publishedAssetNames + $retiredAssetNames

    Write-Host "`nGIT STATUS (antes do commit):"
    Invoke-Git -Arguments @('status', '--short', '--branch')

    Invoke-Git -Arguments (@('add', '--') + $siteFiles)

    & git -C $RepositoryPath diff --cached --quiet -- @siteFiles
    $diffExitCode = $LASTEXITCODE
    if ($diffExitCode -eq 1) {
        $message = 'Update AI Robots Gallery - ' + (Get-Date -Format 'yyyy-MM-dd HH:mm')
        Invoke-Git -Arguments (@('commit', '-m', $message, '--') + $siteFiles)
        $commitHash = (& git -C $RepositoryPath rev-parse HEAD).Trim()
        if ($LASTEXITCODE -ne 0) { throw 'Nao foi possivel obter o hash do commit.' }
        Write-Host "COMMIT: criado ($commitHash)" -ForegroundColor Green
    } elseif ($diffExitCode -eq 0) {
        $commitHash = (& git -C $RepositoryPath rev-parse HEAD).Trim()
        if ($LASTEXITCODE -ne 0) { throw 'Nao foi possivel obter o hash atual.' }
        Write-Host 'COMMIT: nenhum commit criado; nao havia mudancas no site.' -ForegroundColor Green
        Write-Host "COMMIT ATUAL: $commitHash"
    } else {
        throw 'Nao foi possivel verificar as alteracoes preparadas para commit.'
    }

    Write-Host "`nEnviando main para origin..."
    Invoke-Git -Arguments @('push', 'origin', 'main')
    Write-Host 'PUSH: concluido.' -ForegroundColor Green

    Invoke-Git -Arguments @('fetch', 'origin', 'main')
    $localHash = (& git -C $RepositoryPath rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Nao foi possivel obter o hash local.' }
    $remoteHash = (& git -C $RepositoryPath rev-parse 'origin/main').Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Nao foi possivel obter o hash de origin/main.' }
    if ($localHash -ne $remoteHash) {
        throw "Validacao falhou: HEAD ($localHash) difere de origin/main ($remoteHash)."
    }

    Write-Host "VALIDACAO: origin/main confirma o commit $remoteHash" -ForegroundColor Green
    Write-Host "`nGIT STATUS (final):"
    Invoke-Git -Arguments @('status', '--short', '--branch')
    Write-Host "`nPublicacao concluida com sucesso." -ForegroundColor Cyan
} catch {
    Write-Error $_
    exit 1
}
