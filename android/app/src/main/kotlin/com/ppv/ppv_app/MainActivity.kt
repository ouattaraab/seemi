package com.ppv.ppv_app

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // F-2 — Empêche les captures d'écran et l'affichage de l'UI dans le
        // gestionnaire de tâches récentes (app switcher).
        // Protège les écrans sensibles : wallet, paiement, KYC, profil.
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )
    }
}
