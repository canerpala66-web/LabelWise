export type SubmissionStatus = "pending" | "approved" | "rejected";

export type SubmittedProduct = {
  id: string;
  barcode: string;
  name: string;
  brand: string | null;
  ingredients_text: string | null;
  energy_kcal: number | null;
  fat: number | null;
  saturated_fat: number | null;
  sugars: number | null;
  fiber: number | null;
  protein: number | null;
  salt: number | null;
  front_image_path: string | null;
  nutrition_image_path: string | null;
  ingredients_image_path: string | null;
  status: string | null;
  source: string | null;
  created_at: string | null;
  reviewed_at: string | null;
  review_note: string | null;
  reviewed_by: string | null;
  category: string | null;
};

export type SubmissionImagePreview = {
  label: string;
  path: string;
  signedUrl: string;
};

export type AdminSession = {
  userId: string;
  email: string | null;
};
