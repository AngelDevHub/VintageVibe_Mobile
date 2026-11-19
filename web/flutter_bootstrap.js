{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    
    // Ocultar suavemente el contenedor de carga vintage
    const loader = document.getElementById('loading-container');
    if (loader) {
      loader.style.transition = 'opacity 0.4s ease';
      loader.style.opacity = '0';
      setTimeout(function() {
        if (loader.parentNode) {
          loader.parentNode.removeChild(loader);
        }
      }, 400);
    }

    await appRunner.runApp();
  }
});

