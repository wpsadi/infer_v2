import app from "@/index";

// Appwrite function entrypoint: forwards the incoming Appwrite request to the Hono app
export default async ({ req, res, error }: any) => {
  const hasBody = req.method !== "GET" && req.method !== "HEAD";

  try {
    const response = await app.fetch(req);

    return response;
  } catch (e) {
    error(String(e));
    return res.json({ error: "Internal Server Error" }, 500);
  }
};
