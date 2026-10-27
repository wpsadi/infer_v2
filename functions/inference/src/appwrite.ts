// This Appwrite function will be executed every time your function is triggered
export default async ({ req, res, log, error }: any) => {
  return res.json({
    motto: "Build like a team of hundreds_",
    learn: "https://appwrite.io/docs",
    connect: "https://appwrite.io/discord",
    getInspired: "https://builtwith.appwrite.io",
  });
};
