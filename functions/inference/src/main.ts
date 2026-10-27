import app, {  } from "@/index";


// Headers that describe the original transfer, not the body we re-send
const SKIP_RESPONSE_HEADERS = new Set(["content-length", "transfer-encoding", "connection"]);

// Appwrite function entrypoint: forwards the incoming Appwrite request to the Hono app
export default async ({ req, res, log, error }: any) => {
  const hasBody = req.method !== "GET" && req.method !== "HEAD";
  const appwrite: Appwrite= { req, log, error,res };

  try {
    // Request: method, full URL (path + query), headers and raw body; the Appwrite
    // context is available in handlers as c.env.appwrite
    const response = await app.fetch(
      new Request(req.url, {
        method: req.method,
        headers: req.headers,
        body: hasBody ? req.bodyBinary : undefined,
      }),
      { appwrite },
    );

    // Response: same status, body and headers (minus transfer-specific ones)
    const headers: Record<string, string> = {};
    response.headers.forEach((value, key) => {
      if (!SKIP_RESPONSE_HEADERS.has(key)) headers[key] = value;
    });

    return res.binary(Buffer.from(await response.arrayBuffer()), response.status, headers);
  } catch (e) {
    error(`Unhandled error: ${e instanceof Error ? (e.stack ?? e.message) : String(e)}`);
    return res.json({ error: "Internal Server Error" }, 500);
  }
};
