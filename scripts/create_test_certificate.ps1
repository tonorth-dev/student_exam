# PowerShell脚本：创建自签名测试证书
# 注意：此证书仅用于开发和测试，不适用于生产环境

# 创建自签名证书
$cert = New-SelfSignedCertificate `
    -Type Custom `
    -Subject "CN=红师教育, O=红师教育, C=CN" `
    -KeyUsage DigitalSignature `
    -FriendlyName "红师教育学生端测试证书" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}")

# 导出证书到PFX文件（包含私钥）
$password = ConvertTo-SecureString -String "hongshi2024" -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath "hongshi_test_cert.pfx" -Password $password

# 导出公钥证书（用于安装到受信任的根证书颁发机构）
Export-Certificate -Cert $cert -FilePath "hongshi_test_cert.cer"

Write-Host "证书创建完成！"
Write-Host "PFX文件: hongshi_test_cert.pfx (密码: hongshi2024)"
Write-Host "CER文件: hongshi_test_cert.cer"
Write-Host ""
Write-Host "安装步骤："
Write-Host "1. 双击 hongshi_test_cert.cer"
Write-Host "2. 点击'安装证书'"
Write-Host "3. 选择'本地计算机'"
Write-Host "4. 选择'将所有证书放入下列存储'"
Write-Host "5. 浏览并选择'受信任的根证书颁发机构'"
Write-Host "6. 完成安装"
