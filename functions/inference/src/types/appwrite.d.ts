type Appwrite = {
  req: Request;
  res: {
    empty: () => void;
    json: (obj: any, statusCode?: number) => void;
    text: (text: string, statusCode?: number) => void;
    binary: (body: ArrayBuffer | Uint8Array, statusCode?: number, headers?: Record<string, string>) => void;
    redirect: (url: string, statusCode?: number) => void;
  };
  log: (message: any) => void;
  error: (message: any) => void;
};