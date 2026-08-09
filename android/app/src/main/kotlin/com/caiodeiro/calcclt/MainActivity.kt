package com.caiodeiro.calcclt

import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Habilitar Edge-to-Edge para Android 15+ (API 35+)
        // Isso resolve o problema de APIs descontinuadas relacionadas a status bar e navigation bar
        // WindowCompat.setDecorFitsSystemWindows(window, false) permite que o conteúdo seja exibido
        // atrás das barras do sistema, preparando o app para Edge-to-Edge
        WindowCompat.setDecorFitsSystemWindows(window, false)
        super.onCreate(savedInstanceState)
    }
}
