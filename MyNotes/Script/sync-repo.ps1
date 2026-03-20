#!/usr/bin/env pwsh
# sync-repo.ps1 - Синхронизация содержимого между Git репозиториями

param(
    [Parameter(Mandatory=$false)]
    [string]$Source,
    
    [Parameter(Mandatory=$false)]
    [string]$Destination,
    
    [switch]$Push,
    [switch]$SkipPrivate,
    [switch]$NoPull,
    [switch]$Terminal,
    [switch]$Help
)

# Функция для вывода цветных сообщений
function Write-Message {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    $colors = @{
        "Red" = 0xF00
        "Green" = 0x0F0
        "Yellow" = 0xFF0
        "Blue" = 0x0FF
        "White" = 0xFFF
    }
    
    Write-Host $Message -ForegroundColor $Color
}

# Функция для проверки пути
function Test-PathValid {
    param(
        [string]$Path,
        [string]$PathType
    )
    
    if ([string]::IsNullOrEmpty($Path)) {
        Write-Message "Ошибка: $PathType не указан" "Red"
        return $false
    }
    
    if (-not (Test-Path $Path)) {
        Write-Message "Ошибка: $PathType '$Path' не существует" "Red"
        return $false
    }
    
    Write-Message "✓ $PathType проверен: $Path" "Green"
    return $true
}

# Функция для проверки Git репозитория
function Test-GitRepo {
    param(
        [string]$RepoPath,
        [string]$RepoName
    )
    
    $gitPath = Join-Path $RepoPath ".git"
    if (-not (Test-Path $gitPath)) {
        Write-Message "Ошибка: $RepoName не является Git репозиторием" "Red"
        return $false
    }
    
    Write-Message "✓ $RepoName является Git репозиторием" "Green"
    return $true
}

# Функция для синхронизации с удаленным репозиторием
function Sync-WithRemote {
    param(
        [string]$RepoPath,
        [string]$RepoName,
        [bool]$DoPush = $false
    )
    
    Write-Message "Синхронизация $RepoName с удаленным репозиторием..." "Blue"
    
    Push-Location $RepoPath
    
    try {
        # Проверка на незакоммиченные изменения
        $status = git status --porcelain
        if ($status) {
            Write-Message "Предупреждение: В $RepoName есть незакоммиченные изменения" "Yellow"
            $response = Read-Host "Хотите продолжить? (y/n)"
            if ($response -notmatch '^[Yy]$') {
                return $false
            }
        }
        
        # Получение текущей ветки
        $currentBranch = git branch --show-current
        Write-Message "Текущая ветка: $currentBranch" "Blue"
        
        # Pull изменений
        Write-Message "Выполняется git pull..." "Blue"
        $pullResult = git pull origin $currentBranch 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Message "✓ Pull выполнен успешно" "Green"
        } else {
            Write-Message "✗ Ошибка при выполнении pull: $pullResult" "Red"
            return $false
        }
        
        # Push изменений (опционально)
        if ($DoPush) {
            Write-Message "Выполняется git push..." "Blue"
            $pushResult = git push origin $currentBranch 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Message "✓ Push выполнен успешно" "Green"
            } else {
                Write-Message "✗ Ошибка при выполнении push: $pushResult" "Red"
                return $false
            }
        }
        
        return $true
    }
    finally {
        Pop-Location
    }
}

# Функция для копирования содержимого без .git
function Copy-WithoutGit {
    param(
        [string]$SourceDir,
        [string]$DestDir
    )
    
    Write-Message "Копирование содержимого из $SourceDir в $DestDir..." "Blue"
    
    try {
        # Получение всех файлов и папок, кроме .git
        $items = Get-ChildItem -Path $SourceDir -Exclude ".git" -Force
        
        foreach ($item in $items) {
            $destPath = Join-Path $DestDir $item.Name
            
            if ($item.PSIsContainer) {
                # Копирование папки
                if (Test-Path $destPath) {
                    Remove-Item -Path $destPath -Recurse -Force
                }
                Copy-Item -Path $item.FullName -Destination $destPath -Recurse -Force
            } else {
                # Копирование файла
                Copy-Item -Path $item.FullName -Destination $destPath -Force
            }
        }
        
        Write-Message "✓ Копирование выполнено успешно" "Green"
        return $true
    }
    catch {
        Write-Message "✗ Ошибка при копировании: $_" "Red"
        return $false
    }
}

# Функция для проверки приватного репозитория
function Test-PrivateRepo {
    param([string]$RepoPath)
    
    Push-Location $RepoPath
    
    try {
        # Проверка наличия remote
        $remoteUrl = git remote get-url origin 2>$null
        if (-not $remoteUrl) {
            Write-Message "Репозиторий не имеет remote 'origin'" "Yellow"
            return $false
        }
        
        # Проверка на приватность
        if ($remoteUrl -match "^git@") -or ($remoteUrl -match "^https://.*@") {
            Write-Message "Обнаружен приватный репозиторий" "Yellow"
            return $true
        }
        
        return $false
    }
    finally {
        Pop-Location
    }
}

# Функция для отображения справки
function Show-Help {
    @"
Использование: sync-repo.ps1 [ПАРАМЕТРЫ]

Синхронизация содержимого между Git репозиториями

ПАРАМЕТРЫ:
    -Source PATH          Путь к исходному репозиторию
    -Destination PATH     Путь к целевому репозиторию
    -Push                Выполнить git push в целевом репозитории
    -SkipPrivate         Пропустить приватные репозитории
    -NoPull              Пропустить git pull в исходном репозитории
    -Terminal            Запустить в отдельном окне терминала
    -Help                Показать эту справку

ПРИМЕРЫ:
    .\sync-repo.ps1 -Source ~/projects/source -Destination ~/projects/dest
    .\sync-repo.ps1 -Source ~/projects/source -Destination ~/projects/dest -Push -SkipPrivate
    .\sync-repo.ps1 -Terminal -Source ~/projects/source -Destination ~/projects/dest -Push

"@
}

# Основная функция
function Main {
    if ($Help) {
        Show-Help
        exit 0
    }
    
    # Проверка обязательных параметров
    if ([string]::IsNullOrEmpty($Source)) -or ([string]::IsNullOrEmpty($Destination)) {
        Write-Message "Ошибка: Необходимо указать Source и Destination репозитории" "Red"
        Show-Help
        exit 1
    }
    
    # Запуск в отдельном окне терминала
    if ($Terminal) {
        $scriptPath = $MyInvocation.MyCommand.Path
        $args = @()
        if ($Source) { $args += "-Source `"$Source`"" }
        if ($Destination) { $args += "-Destination `"$Destination`"" }
        if ($Push) { $args += "-Push" }
        if ($SkipPrivate) { $args += "-SkipPrivate" }
        if ($NoPull) { $args += "-NoPull" }
        
        $cmd = "powershell -NoExit -Command `"& '$scriptPath' $args; Write-Host 'Нажмите Enter для выхода...'; Read-Host`""
        
        if ($env:WT_SESSION) {
            # Windows Terminal
            wt.exe $cmd
        } else {
            # Обычная консоль
            Start-Process powershell -ArgumentList "-NoExit", "-Command", "& '$scriptPath' $args; Write-Host 'Нажмите Enter для выхода...'; Read-Host"
        }
        exit 0
    }
    
    # Проверка путей
    Write-Message "=== Начало синхронизации ===" "Blue"
    
    if (-not (Test-PathValid -Path $Source -PathType "Исходный репозиторий")) {
        exit 1
    }
    
    if (-not (Test-PathValid -Path $Destination -PathType "Целевой репозиторий")) {
        exit 1
    }
    
    # Проверка Git репозиториев
    if (-not (Test-GitRepo -RepoPath $Source -RepoName "Исходный репозиторий")) {
        exit 1
    }
    
    if (-not (Test-GitRepo -RepoPath $Destination -RepoName "Целевой репозиторий")) {
        exit 1
    }
    
    # Проверка приватности (опционально)
    if ($SkipPrivate) {
        if (Test-PrivateRepo -RepoPath $Source) {
            Write-Message "Пропуск приватного репозитория" "Yellow"
            exit 0
        }
    }
    
    # Синхронизация с удаленным репозиторием
    if (-not $NoPull) {
        if (-not (Sync-WithRemote -RepoPath $Source -RepoName "Исходный репозиторий" -DoPush $false)) {
            exit 1
        }
    }
    
    # Копирование содержимого
    if (-not (Copy-WithoutGit -SourceDir $Source -DestDir $Destination)) {
        exit 1
    }
    
    # Опциональный push в целевом репозитории
    if ($Push) {
        if (-not (Sync-WithRemote -RepoPath $Destination -RepoName "Целевой репозиторий" -DoPush $true)) {
            exit 1
        }
    }
    
    Write-Message "=== Синхронизация успешно завершена ===" "Green"
}

# Запуск основной функции
Main