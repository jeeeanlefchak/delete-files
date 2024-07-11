@echo off
setlocal EnableDelayedExpansion
set startDate=%date%
set startTime=%time%
:: Abrir arquivo de log
set "logFile=C:\TFS\Builds\delete_builds.log"

:: Remove milissegundos da hora
set startTime=%startTime:~0,8%

echo Script iniciado em: %startDate% %startTime% >> "%logFile%"

:: Capturar a data atual no formato YYYYMMDD
for /f "tokens=1" %%a in ('powershell -command "Get-Date -Format yyyyMMdd"') do (
    set "currentDate=%%a"
)

:: Calcular a data de corte (5 dias atrás)
set /a cutoffDays=5
for /f "tokens=1-3" %%A in ('powershell -Command "(Get-Date).AddDays(-%cutoffDays%).ToString('yyyyMMdd')"') do (
    set "cutoffDate=%%A"
)

:: Definir as pastas a serem processadas
set "folder1=C:\TFS\Builds\iRisk Dashboard Develop"
set "folder2=C:\TFS\Builds\iRisk Dashboard Master"
set "folder3=C:\TFS\Builds\iRisk Develop"
set "folder4=C:\TFS\Builds\iRisk Develop BBMapfre"
set "folder5=C:\TFS\Builds\iRisk Develop Sprint BBMapfre"
set "folder6=C:\TFS\Builds\iRisk Develop Sprint HML Brasilseg"
set "folder7=C:\TFS\Builds\iRisk Lite Main"
set "folder8=C:\TFS\Builds\iRisk v1 Master"
set "folder9=C:\TFS\Builds\iRisk v3 Master"
set "folder10=C:\TFS\Builds\Porto"
set "folder11=C:\TFS\Builds\iRisk_PROD\Brasilseg"
set "folder12=C:\TFS\Builds\iRisk_PROD\Mds"
set "folder13=C:\TFS\Builds\iRisk_PROD\Porto"

echo %date% >> "%logFile%"

:: Loop para cada pasta
for %%F in ("!folder1!" "!folder2!" "!folder3!" "!folder4!" "!folder5!" "!folder6!" "!folder7!" "!folder8!" "!folder9!" "!folder10!" "!folder11!" "!folder12!" "!folder13!") do (
    set "folder=%%~F"

    :: Remover aspas dos caminhos das pastas
    set "folder=!folder:\"=!"

    :: Verificar se a pasta existe
    echo Verificando pasta: !folder! >> "%logFile%"
    if not exist "!folder!" (
        echo Erro: Pasta não encontrada: !folder! >> "%logFile%"
        continue
    )

    :: Entrar na pasta usando pushd para lidar melhor com caminhos com espaços
    pushd "!folder!"

    :: Encontrar o build mais recente
    set "mostRecentBuild="
    set "mostRecentDate=0"
    for /d %%D in (*) do (
        set "buildName=%%~nxD"

        :: Obter a data de criação da pasta
        for /f "tokens=1" %%A in ('PowerShell -NoProfile -Command "(Get-Item -LiteralPath '%%~fD').CreationTime.ToString('yyyyMMdd')"') do (
            set "createDate=%%A"
        )

        :: Verificar se esta é a data mais recente
        if !createDate! gtr !mostRecentDate! (
            set "mostRecentDate=!createDate!"
            set "mostRecentBuild=%%~fD"
        )
    )

    :: Deletar pastas antigas (com mais de 5 dias)
    for /d %%D in (*) do (
        set "buildName=%%~nxD"

        :: Obter a data de criação da pasta
        for /f "tokens=1" %%A in ('PowerShell -NoProfile -Command "(Get-Item -LiteralPath '%%~fD').CreationTime.ToString('yyyyMMdd')"') do (
            set "createDate=%%A"
        )

        :: Verificar se a pasta é antiga (mais de 5 dias) e não é a mais recente
        if !createDate! LEQ !cutoffDate! (
            if "%%~fD" NEQ "!mostRecentBuild!" (
                echo Deletando pasta antiga: !folder! %%D >> "%logFile%"
                rd /s /q "%%~fD"
            ) else (
                echo Mantendo pasta mais recente: !folder!\%%D >> "%logFile%"
            )
        ) else (
            echo Ignorando pasta recente: !folder!\%%D >> "%logFile%"
        )
    )

    :: Sair da pasta usando popd para retornar ao diretório anterior
    popd
)

set endDate=%date%
set endTime=%time%
:: Remove milissegundos da hora
set endTime=%endTime:~0,8%
echo Script finalizado em: %endDate% %endTime% >> "%logFile%"

echo Concluído.
pause
