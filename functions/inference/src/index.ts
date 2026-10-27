import { Hono } from "hono";
import type { AppEnv } from "@/types/ context";

const app = new Hono<AppEnv>();

app.get("/", (c) => c.text("Hello from inference!"));
app.get("/health", (c) => c.json({ status: "ok" }));
app.get("no-idea",c=>{
    console.log("no-idea")
    return c.json({ status: "ok" })
})
export default app;
