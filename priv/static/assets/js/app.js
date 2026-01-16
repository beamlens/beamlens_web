(function() {
  "use strict";

  // Wait for Phoenix and LiveView to be available
  function initLiveSocket() {
    if (typeof window.Phoenix === "undefined" || typeof window.LiveView === "undefined") {
      console.error("Phoenix or LiveView not loaded");
      return;
    }

    var csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
    var liveSocket = new window.LiveView.LiveSocket("/live", window.Phoenix.Socket, {
      params: { _csrf_token: csrfToken }
    });

    // Connect if there are any LiveViews on the page
    liveSocket.connect();

    // Expose liveSocket on window for debugging
    window.liveSocket = liveSocket;
  }

  // Initialize when DOM is ready
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initLiveSocket);
  } else {
    initLiveSocket();
  }
})();
