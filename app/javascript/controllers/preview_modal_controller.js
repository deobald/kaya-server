import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["modal", "content", "title", "visitLink"];

  connect() {
    this.pollingInterval = null;
    this.currentTileElement = null;
  }

  disconnect() {
    this.stopPolling();
  }

  open(event) {
    event.preventDefault();
    const tile = event.currentTarget;
    const url = tile.dataset.previewUrl;
    const filename = tile.dataset.previewFilename;
    const fileType = tile.dataset.previewType;
    const originalUrl = tile.dataset.previewOriginalUrl;
    const cacheUrl = tile.dataset.previewCacheUrl;
    const cacheStatusUrl = tile.dataset.cacheStatusUrl;

    this.currentTileElement = tile;
    this.titleTarget.textContent = filename;

    // Show/hide visit link for bookmarks
    if (originalUrl) {
      this.visitLinkTarget.href = originalUrl;
      this.visitLinkTarget.classList.remove("hidden");
    } else {
      this.visitLinkTarget.classList.add("hidden");
    }

    // Load content based on file type
    this.loadContent(url, fileType, cacheUrl, cacheStatusUrl);

    this.modalTarget.classList.add("active");
    document.body.style.overflow = "hidden";

    // Focus the modal for keyboard navigation
    this.modalTarget.focus();
  }

  close() {
    this.stopPolling();
    this.modalTarget.classList.remove("active");
    document.body.style.overflow = "";
    this.contentTarget.innerHTML = "";
    this.currentTileElement = null;
  }

  closeOnBackdrop(event) {
    if (event.target === this.modalTarget) {
      this.close();
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close();
    }
  }

  loadContent(url, fileType, cacheUrl, cacheStatusUrl) {
    this.contentTarget.innerHTML =
      '<div class="preview-loading">Loading...</div>';

    switch (fileType) {
      case "note":
      case "text":
        this.loadText(url);
        break;
      case "image":
        this.loadImage(url);
        break;
      case "pdf":
        this.loadPdf(url);
        break;
      case "bookmark":
        this.loadBookmark(url, cacheUrl, cacheStatusUrl);
        break;
      default:
        this.contentTarget.innerHTML =
          '<div class="preview-unsupported">Preview not available for this file type.</div>';
    }
  }

  loadText(url) {
    fetch(url)
      .then((response) => response.text())
      .then((text) => {
        this.contentTarget.innerHTML = `<pre class="preview-text">${this.escapeHtml(text)}</pre>`;
      })
      .catch(() => {
        this.contentTarget.innerHTML =
          '<div class="preview-error">Failed to load file.</div>';
      });
  }

  loadImage(url) {
    const img = document.createElement("img");
    img.src = url;
    img.alt = "Preview";
    img.className = "preview-image";
    img.onload = () => {
      this.contentTarget.innerHTML = "";
      this.contentTarget.appendChild(img);
    };
    img.onerror = () => {
      this.contentTarget.innerHTML =
        '<div class="preview-error">Failed to load image.</div>';
    };
  }

  loadPdf(url) {
    // Use an iframe to render PDF with browser's built-in PDF viewer
    this.contentTarget.innerHTML = `<iframe src="${url}" class="preview-pdf" title="PDF Preview"></iframe>`;
  }

  loadBookmark(url, cacheUrl, cacheStatusUrl) {
    // If we have a cached version, render it in an iframe
    if (cacheUrl) {
      this.contentTarget.innerHTML = `<iframe src="${cacheUrl}" class="preview-cached-page" title="Cached Webpage"></iframe>`;
      return;
    }

    // Otherwise, trigger caching and poll for completion
    if (cacheStatusUrl) {
      this.showCachingStatus(url);
      this.startPolling(cacheStatusUrl, url);
    } else {
      // Fallback for bookmarks without cache status URL
      this.showBookmarkFallback(url);
    }
  }

  showCachingStatus(url) {
    fetch(url)
      .then((response) => response.text())
      .then((text) => {
        this.contentTarget.innerHTML = `
          <div class="preview-bookmark">
            <div class="preview-caching-status">
              <div class="caching-spinner"></div>
              <p class="preview-bookmark-notice">Caching webpage...</p>
            </div>
            <pre class="preview-bookmark-content">${this.escapeHtml(text)}</pre>
          </div>`;
      })
      .catch(() => {
        this.contentTarget.innerHTML =
          '<div class="preview-error">Failed to load bookmark.</div>';
      });
  }

  showBookmarkFallback(url) {
    fetch(url)
      .then((response) => response.text())
      .then((text) => {
        this.contentTarget.innerHTML = `<div class="preview-bookmark"><p class="preview-bookmark-notice">Webpage preview not available.</p><pre class="preview-bookmark-content">${this.escapeHtml(text)}</pre></div>`;
      })
      .catch(() => {
        this.contentTarget.innerHTML =
          '<div class="preview-error">Failed to load bookmark.</div>';
      });
  }

  startPolling(cacheStatusUrl, previewUrl) {
    this.stopPolling();

    // Trigger caching immediately
    fetch(cacheStatusUrl)
      .then((response) => response.json())
      .then((data) => {
        this.handleCacheStatus(data, previewUrl);
      });

    // Poll every 2 seconds
    this.pollingInterval = setInterval(() => {
      fetch(cacheStatusUrl)
        .then((response) => response.json())
        .then((data) => {
          this.handleCacheStatus(data, previewUrl);
        })
        .catch(() => {
          // Ignore polling errors
        });
    }, 2000);
  }

  handleCacheStatus(data, previewUrl) {
    if (data.status === "cached") {
      this.onCacheComplete(data, previewUrl);
    } else if (data.status === "error") {
      this.onCacheError(data, previewUrl);
    }
    // If status is "pending", keep polling
  }

  stopPolling() {
    if (this.pollingInterval) {
      clearInterval(this.pollingInterval);
      this.pollingInterval = null;
    }
  }

  onCacheComplete(data, previewUrl) {
    this.stopPolling();

    // Update the modal with the cached page
    if (data.cache_url) {
      this.contentTarget.innerHTML = `<iframe src="${data.cache_url}" class="preview-cached-page" title="Cached Webpage"></iframe>`;
    }

    // Update the tile to show the favicon and cache URL
    this.updateTile(data);
  }

  onCacheError(data, previewUrl) {
    this.stopPolling();

    // Show error message and fall back to showing the URL
    fetch(previewUrl)
      .then((response) => response.text())
      .then((text) => {
        this.contentTarget.innerHTML = `
          <div class="preview-bookmark">
            <div class="preview-cache-error">
              <p class="preview-bookmark-notice">Failed to cache webpage</p>
              <p class="preview-error-details">${this.escapeHtml(data.error || "Unknown error")}</p>
            </div>
            <pre class="preview-bookmark-content">${this.escapeHtml(text)}</pre>
          </div>`;
      })
      .catch(() => {
        this.contentTarget.innerHTML =
          '<div class="preview-error">Failed to load bookmark.</div>';
      });
  }

  updateTile(data) {
    if (!this.currentTileElement) return;

    const tile = this.currentTileElement;

    // Update the tile's cache URL data attribute
    if (data.cache_url) {
      tile.dataset.previewCacheUrl = data.cache_url;
    }

    // Update the tile content to show favicon if available
    if (data.favicon_url) {
      const tileContent = tile.querySelector(".anga-tile-content");
      if (tileContent && tileContent.classList.contains("anga-tile-bookmark")) {
        tileContent.innerHTML = `<img src="${data.favicon_url}" class="bookmark-favicon" alt="Favicon">`;
      }
    }
  }

  escapeHtml(text) {
    const div = document.createElement("div");
    div.textContent = text;
    return div.innerHTML;
  }
}
