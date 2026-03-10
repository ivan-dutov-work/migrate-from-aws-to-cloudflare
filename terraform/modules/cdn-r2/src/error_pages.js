export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // Fast path: fetch from origin (R2 via custom domain).
    let response = await fetch(request);

    if (response.ok) {
      return response;
    }

    // R2 returned 404. Try subdirectory index.html resolution.
    const path = url.pathname;
    const lastSegment = path.split("/").pop();
    const hasExtension = lastSegment.includes(".");

    if (!hasExtension) {
      const indexPath = path.endsWith("/")
        ? path + "index.html"
        : path + "/index.html";
      const indexUrl = new URL(request.url);
      indexUrl.pathname = indexPath;
      const indexResponse = await fetch(indexUrl.toString());

      if (indexResponse.ok) {
        return indexResponse;
      }
    }

    // Genuinely missing — serve custom 404.html with 404 status.
    url.pathname = "/404.html";
    const errorPage = await fetch(url.toString());

    return new Response(errorPage.body, {
      status: 404,
      statusText: "Not Found",
      headers: errorPage.headers,
    });
  },
};
