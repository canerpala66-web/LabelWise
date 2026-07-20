"use client";

import { createBrowserClient } from "@supabase/ssr";

function getBrowserSupabaseUrl() {
  return process.env.NEXT_PUBLIC_SUPABASE_URL?.trim() ?? "";
}

function getBrowserSupabaseAnonKey() {
  return process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY?.trim() ?? "";
}

export function getBrowserSupabaseEnvStatus() {
  return {
    urlPresent: Boolean(getBrowserSupabaseUrl()),
    anonKeyPresent: Boolean(getBrowserSupabaseAnonKey()),
  };
}

export function hasSupabaseBrowserEnv() {
  const status = getBrowserSupabaseEnvStatus();
  return status.urlPresent && status.anonKeyPresent;
}

export function createSupabaseBrowserClient() {
  const supabaseUrl = getBrowserSupabaseUrl();
  const supabaseAnonKey = getBrowserSupabaseAnonKey();

  if (!supabaseUrl || !supabaseAnonKey) {
    throw new Error("Supabase public env eksik.");
  }

  return createBrowserClient(supabaseUrl, supabaseAnonKey);
}
