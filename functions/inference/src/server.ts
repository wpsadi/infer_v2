import app from "@/index";

const server = Bun.serve({
  port: Number(Bun.env.PORT ?? 3000),
  fetch: app.fetch,
});

console.log(`Listening on ${server.url}`);
