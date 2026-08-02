import type { MetadataRoute } from "next";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      {
        userAgent: "*",
        allow: ["/", "/blog", "/blog/"],
        disallow: ["/admin/", "/partner-demo/", "/partner-center/dashboard", "/partner-center/demo"],
      },
    ],
    sitemap: "https://labelwise.net/sitemap.xml",
    host: "https://labelwise.net",
  };
}
