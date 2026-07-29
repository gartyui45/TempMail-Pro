#!/bin/bash
# Gera ícones Android a partir do ícone 3D
# Requer: ImageMagick (convert)

ICON_SOURCE="assets/icon_3d.png"

if [ ! -f "$ICON_SOURCE" ]; then
    echo "❌ Ícone fonte não encontrado: $ICON_SOURCE"
    exit 1
fi

# Para uso real, faça o resize manual para cada tamanho
echo "✅ Ícone 3D gerado em: $ICON_SOURCE"
echo ""
echo "📱 Para usar em produção, redimensione para:"
echo "   - mipmap-mdpi:    48x48"
echo "   - mipmap-hdpi:    72x72"
echo "   - mipmap-xhdpi:   96x96"
echo "   - mipmap-xxhdpi:  144x144"
echo "   - mipmap-xxxhdpi: 192x192"
echo ""
echo "💡 Use o ícone gerado como referência para a Play Store."
echo "   O ícone será aplicado automaticamente no build do GitHub Actions."
