# 🔷 TempMail Pro - E-mail Temporário Premium

<div align="center">
  <img src="assets/icon_3d.png" width="200" alt="TempMail Pro Icon"/>
  
  ### 📧 E-mail Descartável • Neon 3D • Ultra Rápido
  
  ![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B?style=for-the-badge&logo=flutter)
  ![Dart](https://img.shields.io/badge/Dart-3.1+-0175C2?style=for-the-badge&logo=dart)
  ![APK](https://img.shields.io/badge/APK-Release-00D4FF?style=for-the-badge&logo=android)
  
  [![Build APK](https://github.com/seuuser/temp_mail_app/actions/workflows/build_apk.yml/badge.svg)](https://github.com/seuuser/temp_mail_app/actions/workflows/build_apk.yml)
</div>

---

## ✨ Funcionalidades

| Recurso | Descrição |
|---------|-----------|
| 📧 **E-mail Instantâneo** | Criação automática em 1 segundo |
| 🛡️ **Domínios Anti-Blocklist** | Domínios obscuros que não estão em blocklists |
| 🔄 **Auto-Refresh** | Atualização automática a cada 10 segundos |
| 🎨 **Interface Neon 3D** | Design premium com partículas animadas |
| 📋 **Cópia Rápida** | Copie seu e-mail com 1 toque |
| 🗑️ **Gerenciamento** | Leia, arquive ou delete mensagens |
| 🔒 **100% Anônimo** | Sem cadastro, sem rastreamento |
| ⚡ **Leve e Rápido** | APK otimizado < 15MB |

## 📱 Como Usar

1. **Abra o app** - Seu e-mail é gerado automaticamente
2. **Copie o endereço** - Toque no botão de cópia
3. **Use onde quiser** - Cadastros, verificações, testes
4. **Aguarde** - Os e-mails chegam em tempo real
5. **Troque quando quiser** - Toque no refresh para novo e-mail

## 🏗️ Build Local

```bash
# Clone o repositório
git clone https://github.com/seuuser/temp_mail_app.git
cd temp_mail_app

# Instale as dependências
flutter pub get

# Execute em debug
flutter run

# Build APK Release
flutter build apk --release --split-per-abi
```

## 🤖 GitHub Actions (Build Automático)

O projeto já inclui CI/CD completo. Ao fazer push para `main` ou `master`:

1. ✅ Análise de código
2. 🧪 Testes automatizados
3. 🏗️ Build de 4 variantes de APK:
   - `arm64-v8a` (99% dos dispositivos modernos)
   - `armeabi-v7a` (dispositivos antigos)
   - `x86_64` (emuladores)
   - `Universal` (todos)
4. 📦 Artefatos disponíveis para download
5. 🚀 Release automático com changelog

### Para baixar seu APK:

1. Faça fork/push deste repositório para o GitHub
2. Vá em **Actions** > **Build TempMail APK** > **Run workflow**
3. Aguarde ~5 minutos
4. Baixe os artefatos na seção **Summary** da build

## 🔧 Domínios Suportados

O app usa a API [mail.tm](https://mail.tm) com dezenas de domínios, incluindo domínios obscuros que passam despercebidos por blocklists.

## 📸 Screenshots

*(Adicione screenshots aqui após o build)*

## 📄 Licença

MIT - Use, modifique, distribua livremente.

---

<div align="center">
  <b>Feito com 💙 • Flutter • Dart • Neon</b>
</div>
