import {
  importTemplateExampleRow,
  importTemplateHeaders,
} from "@/lib/admin/imports/constants";
import { csvEscape } from "@/lib/admin/imports/helpers";

export function buildImportTemplateCsv() {
  const headerLine = importTemplateHeaders.join(",");
  const exampleLine = importTemplateHeaders
    .map((header) => csvEscape(importTemplateExampleRow[header] ?? ""))
    .join(",");

  return `${headerLine}\n${exampleLine}\n`;
}
