
// Appwrite execution context, passed to the app as Hono bindings (c.env)
export type AppwriteContext = {
  req: {
    method: string;
    url: string;
    path: string;
    query: Record<string, string>;
    headers: Record<string, string>;
    bodyText: string;
  };
  log: (message: unknown) => void;
  error: (message: unknown) => void;
};

export type AppEnv = { Bindings: { appwrite: AppwriteContext } };
