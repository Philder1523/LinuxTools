param(
    [Parameter(Mandatory=$true)]
    [string]$webSite
)

# Function to check network reachability and web server response
function Check-WebSiteReachability {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Domain
    )

    Write-Host "Verifica raggiungibilità di rete (ping)..."
    try {
        if (Test-Connection -ComputerName $Domain -Count 1 -ErrorAction Stop -Quiet) {
            Write-Host "✅ Rete: il sito è raggiungibile via ping." -ForegroundColor Green
            $reachable = $true
        } else {
            Write-Host "❌ Rete: il sito non è raggiungibile via ping." -ForegroundColor Red
            $reachable = $false
        }
    }
    catch {
        Write-Host "❌ Rete: Errore durante il ping. $($_.Exception.Message)" -ForegroundColor Red
        $reachable = $false
    }

    if ($reachable) {
        Write-Host "Verifica disponibilità server web (Invoke-WebRequest)..."
        try {
            # Use -MaximumRedirection 0 to handle redirects explicitly and avoid endless loops or unexpected behavior
            $response = Invoke-WebRequest -Uri "http://$Domain" -UseBasicParsing -MaximumRedirection 0 -TimeoutSec 10 -ErrorAction SilentlyContinue
            if ($response) {
                $statusCode = [int]$response.StatusCode
                if ($statusCode -ge 200 -and $statusCode -lt 400) {
                    Write-Host "✅ Server Web: il sito risponde con codice HTTP $statusCode." -ForegroundColor Green
                } else {
                    Write-Host "❌ Server Web: il sito non risponde correttamente (Codice HTTP: $statusCode)." -ForegroundColor Red
                }
            } else {
                # If initial Invoke-WebRequest failed or returned no response, check for redirects with HEAD request
                $headResponse = Invoke-WebRequest -Uri "http://$Domain" -Method Head -UseBasicParsing -TimeoutSec 10 -ErrorAction SilentlyContinue
                if ($headResponse -and $headResponse.Headers.Location) {
                     $statusCode = [int]$headResponse.StatusCode
                     Write-Host "✅ Server Web: il sito reindirizza a $($headResponse.Headers.Location) (Codice HTTP: $statusCode)." -ForegroundColor Green
                } else {
                    Write-Host "❌ Server Web: Impossibile ottenere risposta dal server web." -ForegroundColor Red
                }
            }
        }
        catch {
            Write-Host "❌ Server Web: Errore durante la verifica con Invoke-WebRequest. $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Il sito non è raggiungibile o non risponde correttamente." -ForegroundColor Red
    }
}

# Function to check SSL Certificate
function Check-SslCertificate {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Domain
    )

    Write-Host "Verifica certificato SSL..."
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect($Domain, 443)
        # The third argument to SslStream constructor is a callback for certificate validation.
        # Here we're accepting all certificates ($true), mimicking the bash script's loose check
        # which doesn't strictly validate the chain but rather if a cert is present and its dates.
        # For production, a more robust validation is recommended.
        $sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream(), $false, { param($sender, $certificate, $chain, $errors) $true })
        $sslStream.AuthenticateAsClient($Domain)

        $certificate = $sslStream.RemoteCertificate
        if ($certificate) {
            $x509 = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certificate)

            $notBefore = $x509.NotBefore
            $notAfter = $x509.NotAfter
            $currentTime = (Get-Date)

            if ($currentTime -ge $notBefore -and $currentTime -le $notAfter) {
                Write-Host "✅ Il certificato SSL è valido e non scaduto (scade il $($notAfter.ToString()))." -ForegroundColor Green
            } else {
                Write-Host "❌ Il certificato SSL non è valido o scaduto (valido da $($notBefore.ToString()) a $($notAfter.ToString()))." -ForegroundColor Red
            }
        } else {
            Write-Host "⚠️ Impossibile ottenere dettagli sul certificato. Fallback a controllo Invoke-WebRequest." -ForegroundColor Yellow
            # Fallback to basic Invoke-WebRequest check
            $response = Invoke-WebRequest -Uri "https://$Domain" -UseBasicParsing -TimeoutSec 10 -ErrorAction SilentlyContinue
            if ($response -and $response.StatusCode -ge 200 -and $response.StatusCode -lt 400) {
                 Write-Host "✅ Il sito è sicuro (controllo base Invoke-WebRequest)." -ForegroundColor Green
            } elseif ($response) {
                 Write-Host "❌ Il certificato non è valido o non rilevato. Non visitare questo sito (Codice HTTP: $($response.StatusCode))." -ForegroundColor Red
            } else {
                 Write-Host "❌ Il certificato non è valido o non rilevato. Non visitare questo sito." -ForegroundColor Red
            }
        }
        $sslStream.Dispose()
        $tcpClient.Dispose()
    }
    catch {
        Write-Host "❌ Errore durante la verifica del certificato SSL. $($_.Exception.Message)" -ForegroundColor Red
        # Fallback to basic Invoke-WebRequest check
        Write-Host "Effettuando controllo SSL base con Invoke-WebRequest..."
        $response = Invoke-WebRequest -Uri "https://$Domain" -UseBasicParsing -TimeoutSec 10 -ErrorAction SilentlyContinue
        if ($response -and $response.StatusCode -ge 200 -and $response.StatusCode -lt 400) {
             Write-Host "✅ Il sito è sicuro (controllo base Invoke-WebRequest)." -ForegroundColor Green
        } elseif ($response) {
             Write-Host "❌ Il certificato non è valido o non rilevato. Non visitare questo sito (Codice HTTP: $($response.StatusCode))." -ForegroundColor Red
        } else {
             Write-Host "❌ Il certificato non è valido o non rilevato. Non visitare questo sito." -ForegroundColor Red
        }
    }
}

Write-Host "`n`nControllo del sito web $webSite..." -ForegroundColor Cyan

Check-WebSiteReachability -Domain $webSite
Check-SslCertificate -Domain $webSite

Write-Host "`nInformazioni sul sito: (Nota: la funzionalità 'whois' non è standard in PowerShell. Su Windows, potrebbe essere disponibile 'whois.exe' dal Sysinternals Suite. Su Linux/WSL, 'whois' può essere installato via package manager.)`n" -ForegroundColor Yellow

# Esempio di come potresti chiamare whois se installato (decommenta e adatta se necessario)
# if (Get-Command whois.exe -ErrorAction SilentlyContinue) {
#    whois.exe $webSite | Select-Object -First 10
# } elseif (Get-Command whois -ErrorAction SilentlyContinue) { # For Linux/WSL
#    whois $webSite | Select-Object -First 10
# } else {
#    Write-Host "Il comando 'whois' non è stato trovato. Installare il tool 'whois' per la funzionalità di ricerca informazioni sul dominio." -ForegroundColor Yellow
# }
