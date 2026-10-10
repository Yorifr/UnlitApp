import 'package:flutter/material.dart';

import 'app.dart';
import 'app_state.dart';
import 'services/demo_device_service.dart';
import 'services/storage_service.dart';

/// Uygulama buradan başlar.
Future<void> main() async {
  // Flutter'ı, uygulama çalışmadan önce kayıtları okuyabilecek hale getir.
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Yerel kayıt (sadece bu cihaz)
  final storage = await StorageService.create();

  // 2) Kılıf bağlantısı. Şimdilik demo kılıf; gerçek kılıf hazır olunca
  //    burada BleDeviceService kullanılacak. Başka hiçbir yer değişmeyecek.
  final device = DemoDeviceService(storage: storage);

  // 3) Uygulamanın durumu: kayıtları yükle, kılıfa bağlan.
  final state = AppState(storage: storage, device: device);
  await state.start();

  runApp(UnlitApp(state: state));
}
