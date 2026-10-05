#!/bin/sh
# Semeia o histórico no APK DEBUG (B5-06/B2-11): 1 registro legado (schemaVersion ausente,
# netAmount 12345.67) + 1 registro ilegível (tipo de rescisão desconhecido).
# Usa `adb shell run-as`, que só funciona em build debug. Escreve o XML interno do plugin
# shared_preferences (lista de strings = prefixo base64 + "!" + JSON): se o plugin mudar o
# formato, este script quebra e o fluxo history_legacy_and_unreadable fica pendente.
# Uso: sh .maestro/utils/seed_history.sh [serial]   (depois rode o fluxo, sem clearState)
set -e
PKG=com.caiodeiro.calcclt
ADB="adb"
[ -n "$1" ] && ADB="adb -s $1"

LEGACY='{\"id\":\"1700000000000\",\"input\":{\"admissionDate\":\"2023-01-01T00:00:00.000\",\"terminationDate\":\"2025-06-15T00:00:00.000\",\"baseSalary\":4000.0},\"result\":{\"additions\":[{\"description\":\"Saldo de Salário\",\"value\":2000.0,\"type\":\"addition\",\"details\":null}],\"deductions\":[],\"totalDeductions\":0.0,\"netAmount\":12345.67,\"calculationDate\":\"2025-06-15T00:00:00.000\"},\"terminationType\":\"withoutJustCause\",\"timestamp\":\"2025-06-15T10:00:00.000\",\"note\":null}'
UNREADABLE='{\"id\":\"1\",\"terminationType\":\"tipoInexistente\"}'

$ADB shell am force-stop $PKG
XML="<?xml version='1.0' encoding='utf-8' standalone='yes' ?>
<map>
    <boolean name=\"flutter.first_result_done\" value=\"true\" />
    <boolean name=\"flutter.onboarding_completed\" value=\"true\" />
    <string name=\"flutter.calculation_history\">VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu![&quot;$(printf '%s' "$LEGACY" | sed 's/"/\&quot;/g')&quot;,&quot;$(printf '%s' "$UNREADABLE" | sed 's/"/\&quot;/g')&quot;]</string>
</map>"
printf '%s\n' "$XML" | $ADB shell "run-as $PKG sh -c 'mkdir -p shared_prefs && cat > shared_prefs/FlutterSharedPreferences.xml'"
echo "Histórico semeado."
