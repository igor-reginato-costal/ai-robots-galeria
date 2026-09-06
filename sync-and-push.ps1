$ErrorActionPreference = 'Stop'

$SourcePath = 'C:\Users\igore\Meu Drive (igor.reginato@costal.com.br)\AI ROBOTS\AI_ROBOTS_Galeria.html'
$RepositoryPath = $PSScriptRoot
$PublishedPath = Join-Path $RepositoryPath 'index.html'
$ExpectedRemote = 'https://github.com/igor-reginato-costal/ai-robot-galeria.git'

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

    $sourceHash = Get-Sha256 -Path $SourcePath
    $destinationHash = if (Test-Path -LiteralPath $PublishedPath -PathType Leaf) {
        Get-Sha256 -Path $PublishedPath
    } else {
        $null
    }

    if ($sourceHash -ne $destinationHash) {
        Copy-Item -LiteralPath $SourcePath -Destination $PublishedPath -Force
        $copiedHash = Get-Sha256 -Path $PublishedPath
        if ($copiedHash -ne $sourceHash) {
            throw 'A verificacao SHA-256 falhou depois da copia para index.html.'
        }
        Write-Host 'ALTERACAO: index.html foi sincronizado e validado por SHA-256.' -ForegroundColor Yellow
    } else {
        Write-Host 'ALTERACAO: nenhuma; index.html ja corresponde ao arquivo-fonte.' -ForegroundColor Green
    }

    Write-Host "`nGIT STATUS (antes do commit):"
    Invoke-Git -Arguments @('status', '--short', '--branch')

    # O HTML e autossuficiente; nao ha assets externos para sincronizar.
    Invoke-Git -Arguments @('add', '--', 'index.html')

    & git -C $RepositoryPath diff --cached --quiet -- 'index.html'
    $diffExitCode = $LASTEXITCODE
    if ($diffExitCode -eq 1) {
        $message = 'Update AI Robots Gallery - ' + (Get-Date -Format 'yyyy-MM-dd HH:mm')
        Invoke-Git -Arguments @('commit', '-m', $message, '--', 'index.html')
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
