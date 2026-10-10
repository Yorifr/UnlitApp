// Flutter web uygulamasını başlatan betik.
// {{...}} ile yazılan yerleri "flutter build web" derlerken kendisi doldurur.
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    // Flutter hazır: "Yükleniyor" ekranını kaldır.
    document.getElementById('yukleniyor')?.remove();
    await appRunner.runApp();
  },
});
