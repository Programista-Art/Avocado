/**
 * Tauri-ready filesystem / dialog abstraction.
 * Web: download + file picker. Desktop (Tauri 2): replace with invoke().
 */
export interface FsAdapter {
  readText(): Promise<string | null>;
  writeText(name: string, text: string): Promise<void>;
}

export const webFs: FsAdapter = {
  async readText() {
    return new Promise((resolve) => {
      const input = document.createElement('input');
      input.type = 'file';
      input.onchange = async () => resolve((await input.files?.[0]?.text()) ?? null);
      input.oncancel = () => resolve(null);
      input.click();
    });
  },
  async writeText(name, text) {
    const blob = new Blob([text], { type: 'text/plain;charset=utf-8' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = name;
    a.click();
    URL.revokeObjectURL(a.href);
  },
};

/**
 * Tauri implementation (optional dependency).
 * Usage later:
 *   import { invoke } from '@tauri-apps/api/core';
 *   await invoke('write_text_file', { path, contents });
 */
export function detectTauri(): boolean {
  return typeof window !== 'undefined' && '__TAURI_INTERNALS__' in window;
}

export async function getFs(): Promise<FsAdapter> {
  // Tauri commands can be wired here without touching UI code.
  return webFs;
}
