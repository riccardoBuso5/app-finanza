[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl,

    [string]$TestUserId = ("smoke_user_" + (Get-Date -Format "yyyyMMddHHmmss")),
    [string]$TestEmail = ("smoke_" + (Get-Date -Format "yyyyMMddHHmmss") + "@example.com"),
    [string]$TestPassword = "Test1234!",
    [switch]$SkipCleanup,
    [int]$TimeoutSec = 20
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$script:RequestUserId = $null

function Normalize-ApiBase {
    param([string]$Url)

    $clean = $Url.Trim().TrimEnd('/')
    if ($clean -notmatch '/api$') {
        $clean = "$clean/api"
    }
    return $clean
}

function Convert-ToJsonSafe {
    param([Parameter(ValueFromPipeline = $true)]$Value)
    process {
        if ($null -eq $Value) { return $null }
        try {
            return ($Value | ConvertTo-Json -Depth 10 -Compress)
        }
        catch {
            return [string]$Value
        }
    }
}

function Get-ErrorBody {
    param([Parameter(Mandatory = $true)]$Exception)

    try {
        if ($Exception.Response -and $Exception.Response.GetResponseStream()) {
            $reader = New-Object System.IO.StreamReader($Exception.Response.GetResponseStream())
            return $reader.ReadToEnd()
        }
    }
    catch {
    }

    return $Exception.Message
}

function Invoke-Api {
    param(
        [Parameter(Mandatory = $true)][string]$Method,
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter()][object]$Body,
        [Parameter(Mandatory = $true)][string]$Name
    )

    $headers = @{
        "Accept" = "application/json"
    }

    if ($script:RequestUserId) {
        $headers["x-user-id"] = $script:RequestUserId
    }

    $requestParams = @{
        Method      = $Method
        Uri         = $Uri
        Headers     = $headers
        TimeoutSec  = $TimeoutSec
        ErrorAction = "Stop"
    }

    if ($PSBoundParameters.ContainsKey('Body')) {
        $requestParams.ContentType = "application/json"
        $requestParams.Body = ($Body | Convert-ToJsonSafe)
    }

    try {
        $result = Invoke-RestMethod @requestParams
        return [pscustomobject]@{
            Name    = $Name
            Ok      = $true
            Status  = 200
            Body    = $result
            Error   = $null
            Uri     = $Uri
            Method  = $Method
        }
    }
    catch {
        $statusCode = -1
        try {
            if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
                $statusCode = [int]$_.Exception.Response.StatusCode
            }
        }
        catch {
        }

        $rawError = Get-ErrorBody -Exception $_.Exception
        $parsed = $null
        try {
            $parsed = $rawError | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            $parsed = $rawError
        }

        return [pscustomobject]@{
            Name    = $Name
            Ok      = $false
            Status  = $statusCode
            Body    = $parsed
            Error   = $rawError
            Uri     = $Uri
            Method  = $Method
        }
    }
}

function Write-Step {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter()][ValidateSet("INFO", "PASS", "FAIL", "WARN")][string]$Level = "INFO"
    )

    $color = switch ($Level) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "WARN" { "Yellow" }
        default { "Cyan" }
    }

    Write-Host ("[{0}] {1}" -f $Level, $Message) -ForegroundColor $color
}

$apiBase = Normalize-ApiBase -Url $BaseUrl
$today = Get-Date -Format "yyyy-MM-dd"

Write-Step -Level INFO -Message ("API base: " + $apiBase)
Write-Step -Level INFO -Message ("Test user: " + $TestUserId + " / " + $TestEmail)
$script:RequestUserId = $TestUserId

$results = New-Object System.Collections.Generic.List[object]

# 1) Health
$health = Invoke-Api -Method "GET" -Uri "$apiBase/health" -Name "Health"
$results.Add($health)
if ($health.Ok) { Write-Step -Level PASS -Message "Health check OK" } else { Write-Step -Level FAIL -Message ("Health check failed (HTTP " + $health.Status + ")") }

# 2) Register
$registerBody = @{
    userId   = $TestUserId
    email    = $TestEmail
    password = $TestPassword
}
$register = Invoke-Api -Method "POST" -Uri "$apiBase/register" -Body $registerBody -Name "Register"
$results.Add($register)
if ($register.Ok) { Write-Step -Level PASS -Message "Register OK" } else { Write-Step -Level WARN -Message ("Register not OK (HTTP " + $register.Status + "). Se utente gia esistente e normale.") }

# 3) Login
$loginBody = @{
    email    = $TestEmail
    password = $TestPassword
}
$login = Invoke-Api -Method "POST" -Uri "$apiBase/login" -Body $loginBody -Name "Login"
$results.Add($login)
if ($login.Ok) { Write-Step -Level PASS -Message "Login OK" } else { Write-Step -Level FAIL -Message ("Login failed (HTTP " + $login.Status + ")") }

# 4) Create category
$categoryName = "SmokeCat_" + (Get-Date -Format "HHmmss")
$createCategory = Invoke-Api -Method "POST" -Uri "$apiBase/categorie" -Body @{ nome = $categoryName } -Name "CreateCategory"
$results.Add($createCategory)
if ($createCategory.Ok) { Write-Step -Level PASS -Message "Create category OK" } else { Write-Step -Level FAIL -Message ("Create category failed (HTTP " + $createCategory.Status + ")") }

# 5) List categories and resolve id
$listCategories = Invoke-Api -Method "GET" -Uri "$apiBase/categorie" -Name "ListCategories"
$results.Add($listCategories)
if ($listCategories.Ok) { Write-Step -Level PASS -Message "List categories OK" } else { Write-Step -Level FAIL -Message ("List categories failed (HTTP " + $listCategories.Status + ")") }

$categoryId = $null
if ($createCategory.Ok -and $createCategory.Body.id) {
    $categoryId = [int]$createCategory.Body.id
}
elseif ($listCategories.Ok -and $listCategories.Body.categorie) {
    $matched = $listCategories.Body.categorie | Where-Object { $_.nome -eq $categoryName } | Select-Object -First 1
    if ($matched) {
        $categoryId = [int]$matched.idcategoria
    }
}

if (-not $categoryId) {
    Write-Step -Level WARN -Message "Category ID non trovato: i test di spese potrebbero fallire."
}

# 6) Create expense
$createExpense = $null
if ($categoryId) {
    $createExpenseBody = @{
        nome       = "Smoke Spesa"
        giorno     = $today
        prezzo     = 12
        idcategoria = $categoryId
    }
    $createExpense = Invoke-Api -Method "POST" -Uri "$apiBase/spese" -Body $createExpenseBody -Name "CreateExpense"
    $results.Add($createExpense)
    if ($createExpense.Ok) { Write-Step -Level PASS -Message "Create expense OK" } else { Write-Step -Level FAIL -Message ("Create expense failed (HTTP " + $createExpense.Status + ")") }
}

# 7) List expenses
$listExpenses = Invoke-Api -Method "GET" -Uri "$apiBase/spese?limit=5" -Name "ListExpenses"
$results.Add($listExpenses)
if ($listExpenses.Ok) { Write-Step -Level PASS -Message "List expenses OK" } else { Write-Step -Level FAIL -Message ("List expenses failed (HTTP " + $listExpenses.Status + ")") }

# 8) Create income
$createIncomeBody = @{
    nome  = "Smoke Entrata"
    prezzo = 99
    data  = $today
}
$createIncome = Invoke-Api -Method "POST" -Uri "$apiBase/entrate" -Body $createIncomeBody -Name "CreateIncome"
$results.Add($createIncome)
if ($createIncome.Ok) { Write-Step -Level PASS -Message "Create income OK" } else { Write-Step -Level FAIL -Message ("Create income failed (HTTP " + $createIncome.Status + ")") }

# 9) List incomes
$listIncomes = Invoke-Api -Method "GET" -Uri "$apiBase/entrate?limit=5" -Name "ListIncomes"
$results.Add($listIncomes)
if ($listIncomes.Ok) { Write-Step -Level PASS -Message "List incomes OK" } else { Write-Step -Level FAIL -Message ("List incomes failed (HTTP " + $listIncomes.Status + ")") }

# Cleanup (best effort)
if (-not $SkipCleanup) {
    Write-Step -Level INFO -Message "Cleanup risorse test (best effort)..."

    if ($createExpense -and $createExpense.Ok -and $createExpense.Body.idspese) {
        $delExpense = Invoke-Api -Method "DELETE" -Uri ("$apiBase/spese/" + $createExpense.Body.idspese) -Name "DeleteExpense"
        $results.Add($delExpense)
        if ($delExpense.Ok) { Write-Step -Level PASS -Message "Delete expense OK" } else { Write-Step -Level WARN -Message "Delete expense non riuscito" }
    }

    if ($createIncome.Ok -and $createIncome.Body.identrate) {
        $delIncome = Invoke-Api -Method "DELETE" -Uri ("$apiBase/entrate/" + $createIncome.Body.identrate) -Name "DeleteIncome"
        $results.Add($delIncome)
        if ($delIncome.Ok) { Write-Step -Level PASS -Message "Delete income OK" } else { Write-Step -Level WARN -Message "Delete income non riuscito" }
    }

    if ($categoryId) {
        $delCategory = Invoke-Api -Method "DELETE" -Uri ("$apiBase/categorie/" + $categoryId) -Name "DeleteCategory"
        $results.Add($delCategory)
        if ($delCategory.Ok) { Write-Step -Level PASS -Message "Delete category OK" } else { Write-Step -Level WARN -Message "Delete category non riuscito" }
    }
}

$failedRequired = @($results | Where-Object {
    $_.Name -in @("Health", "Login", "ListCategories", "ListExpenses", "CreateIncome", "ListIncomes") -and -not $_.Ok
})

Write-Host ""
Write-Host "==== SUMMARY ====" -ForegroundColor White
foreach ($r in $results) {
    $state = if ($r.Ok) { "PASS" } else { "FAIL" }
    $color = if ($r.Ok) { "Green" } else { "Red" }
    Write-Host (("{0,-14} {1,-6} HTTP {2}" -f $r.Name, $state, $r.Status)) -ForegroundColor $color
}

if ($failedRequired.Count -gt 0) {
    Write-Host "" 
    Write-Step -Level FAIL -Message ("Smoke test FAILED: " + $failedRequired.Count + " check obbligatori non passati.")
    exit 1
}

Write-Host ""
Write-Step -Level PASS -Message "Smoke test PASSED."
exit 0
