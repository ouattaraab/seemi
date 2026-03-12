import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialiser le moteur Flutter en premier (crée la window + rootViewController),
    // puis enregistrer les plugins — flutter_contacts v1.x accède à window!!.rootViewController
    // à l'enregistrement et crashe si la window n'est pas encore créée.
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    GeneratedPluginRegistrant.register(with: self)
    return result
  }

  // F-3 — Masque l'UI quand l'app passe en arrière-plan pour éviter que le
  // sélecteur d'apps iOS affiche un aperçu des écrans sensibles (wallet,
  // paiement, KYC). L'UI est restaurée au retour au premier plan.
  override func applicationDidEnterBackground(_ application: UIApplication) {
    super.applicationDidEnterBackground(application)
    window?.rootViewController?.view.isHidden = true
  }

  override func applicationWillEnterForeground(_ application: UIApplication) {
    super.applicationWillEnterForeground(application)
    window?.rootViewController?.view.isHidden = false
  }
}
