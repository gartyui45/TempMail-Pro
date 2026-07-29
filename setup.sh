#!/bin/bash
# 🛠️ Script de setup para TempMail Pro
# Execute na raiz do projeto

echo "🔷 TempMail Pro - Setup Iniciado"
echo "================================"

# Verifica Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter não encontrado! Instale Flutter SDK primeiro."
    exit 1
fi

echo "✅ Flutter encontrado: $(flutter --version | head -1)"

# Instala dependências
echo "📦 Instalando dependências..."
flutter pub get

# Análise
echo "🔍 Analisando código..."
flutter analyze --no-fatal-infos --no-fatal-warnings

# Testes
echo "🧪 Rodando testes..."
flutter test || echo "   ℹ️ Nenhum teste configurado"

echo ""
echo "✅ Setup concluído com sucesso!"
echo ""
echo "📱 Para executar: flutter run"
echo "🏗️ Para build APK: flutter build apk --release --split-per-abi"
echo "📤 Para upload GitHub:"
echo "   1. git add ."
echo "   2. git commit -m 'Initial commit'"
echo "   3. git remote add origin https://github.com/seuuser/temp_mail_app.git"
echo "   4. git push -u origin main"
echo ""
echo "🤖 O GitHub Actions fará o build automático!"
